#import "@preview/based:0.2.0": base64
#import "@preview/cmarker:0.1.6"
#import "@preview/mitex:0.2.5"

#import "common.typ": handle
#import "reading/rich-object.typ"
#import "latex.typ"

// A handler is a function called to render a value such as a cell result
// (in contrast to a template which is called to render a whole cell).
// Each handler is associated with a MIME type. A template can for example
// call the "text/markdown" handler to render the source of a Markdown cell.
//
// Handlers are always called with a positional argument for the data to
// render, and a 'ctx' keyword argument for contextual data. Some handlers also
// take additional arguments:
// 
// - Image handlers must accept an 'alt' argument.
// 
// - Math handlers must accept a 'block' argument (true for block equations).
//
// - The "text/x.source-generic" handler (used by the default code cell source
//   and raw cell source handlers) takes a 'lang' argument.
//
// - The "text/x.stream" handler gets a 'name' argument for the stream name
//   ("stdout" or "stderr").
//
// - The "text/x.error" handler gets 'name' and 'traceback' arguments.
//
// - The "application/x.rich-object" handler gets 'metadata', 'type' and
//   'subhandler-args' arguments.
// 
// When defining a handler, the user can choose to add an '..args' sink if
// they don't care about extra arguments, or omit this sink if they prefer to
// see an error when an unknown argument is passed.
//
// To call a handler, use the 'handle' function from common.typ.

// Generic image handler that supports image path and image bytes, used by
// several others to actually render the image.
// Must be redefined by the user to support images specified by path.
#let handler-image-generic(data, ctx: none, ..args) = {
  if type(data) == str {
    panic("image specified by path (" + data + ") requires a user-defined " +
      "handler for MIME type \"image/x.generic\"")
  }
  std.image(data, ..args)
}

// Handler for images in Markdown cells. Such images can be specified by a
// path of the form "attachment:name" where 'name' refers to a cell attachment.
// As all image handlers, this handler can receive extra arguments such as
// 'alt' that must be forwarded to the subhandler.
#let handler-image-markdown-cell(path, ctx: none, ..args) = {
  let (handlers, cell) = ctx
  if path.starts-with("attachment:") {
    let name = path.trim("attachment:", at: start)
    let attachments = cell.at("attachments", default: (:))
    if name in attachments {
      // Get data dict (keyed by MIME type) for this attachment
      let data = attachments.at(name)
      handle(
        data,
        mime: "application/x.rich-object",
        ctx: ctx,
        metadata: (path: path),
        type: "attachment",
        subhandler-args: args,
      )
    } else {
      panic("cell attachment " + name + " not found")
    }
  } else {
    handle(path, mime: "image/x.generic", ctx: ctx, ..args)
  }
}

// Handler for base64-encoded images
#let handler-image-base64(data, ctx: none, ..args) = {
  let data-bytes = base64.decode(data.replace("\n", ""))
  handle(data-bytes, mime: "image/x.generic", ctx: ctx, ..args)
}

// Handler for text-encoded images, for example svg+xml
#let handler-image-text(data, ctx: none, ..args) = {
  handle(bytes(data), mime: "image/x.generic", ctx: ctx, ..args)
}

// Helper function to guess the SVG data encoding based on the first characters
// in the given data string.
#let _encoded-svg-mime(data) = {
  // base64 encoded version of:     "<?xml "                        "<sv"
  if data.starts-with("PD94bWwg") or data.starts-with("PHN2") {
    return "image/x.base64"
  } else if data.starts-with("<?xml ") or data.starts-with("<svg") {
    return "image/x.text"
  }
  panic("unrecognized svg+xml data")
}

// Smart svg+xml handler that handles both text and base64 data
#let handler-svg-xml(data, ctx: none, ..args) = {
  let mime = _encoded-svg-mime(data)
  handle(data, mime: mime, ctx: ctx, ..args)
}

// Handler for simple text
#let handler-text(data, ctx: none, ..args) = {
  raw(data, block: true, lang: "txt")
}

// Handler for Markdown markup
#let handler-markdown(data, ctx: none, ..args) = cmarker.render(
  data,
  math: handle.with(mime: "text/x.math-markdown-cell", ctx: ctx),
  scope: (
    // Note that for images specified by disk path, the default markdown-cell
    // handler delegates to the "image/x.generic" handler. Users should define
    // that handler to fix image path resolution (until Typst gets a 'path'
    // type).
    image: handle.with(mime: "image/x.markdown-cell", ctx: ctx),
  ),
  ..args,
)

// Handler for LaTeX markup
#let handler-latex(data, ctx: none, ..args) = mitex.mitext(data, ..args)

// Handler for LaTeX equations
#let handler-math(data, ctx: none, ..args) = mitex.mitex(data, ..args)

// Wrap the math item arguments in a labelled metadata
#let _math-metadata(..args) = [#metadata(args)<__callisto-math-item>]

// Return true if the content item is an extracted math item
#let _is-math-item(it) = it.at("label", default: none) == <__callisto-math-item>

// Extract an array of math items from the given Markdown string.
// Each item is returned as an 'arguments' value holding the arguments that
// cmarker passes to the 'math' callback for rendering the math item.
// This includes at least
// - a positional argument for the string holding the LaTeX math
// - a 'block' argument set to true for block equations
#let _extract-math(markdown) = {
  let rendered = cmarker.render(
    markdown,
    math: _math-metadata,
    scope: (image: (..args) => none),
  )
  // For sequence, gather all math items among the children
  if rendered.func() == [].func() {
    return rendered.children.filter(_is-math-item).map(x => x.value)
  }
  // Otherwise we have at most one item
  if _is-math-item(rendered) {
    return (rendered.value,)
  }
  return ()
}

// Get the LaTeX definitions found in the math items in the given cell's
// source. Each item is returned as a regex match in which the 'text' field
// holds the command definition.
#let _cell-latex-defs(c) = {
  _extract-math(c.source)
    .map(args => latex.definitions(args.at(0)))
    .join()
}

// Raise an error if the given list of LaTeX definitions contains duplicates
// (same command defined twice)
#let _check-latex-duplicates(defs) = {
  let sorted = defs.sorted(key: x => x.command)
  let prev = sorted.first()
  for x in sorted.slice(1) {
    if x.command == prev.command {
      panic("conflicting \\newcommand definitions: " +
       prev.text + " and " + x.text)
    }
    prev = x
  }
}

// Make "preamble" string from given list of LaTeX definitions, removing
// redundant duplicates and raising an error if there are non-redundant
// (conflicting) duplicates.
#let _make-preamble(defs) = {
  let deduped = defs
  if deduped.len() > 1 {
    // Remove non-conflicting duplicates (that redefine a command to the same)
    deduped = defs.dedup(key: latex.normalized-def-string)
    // Raise an error if there are remaining duplicates
    _check-latex-duplicates(deduped)
  }
  return deduped.map(latex.normalized-def-string).join("\n")
}

// Handler for LaTeX equations in Markdown cells.
// This handler gathers all LaTeX \newcommand definitions from the notebook
// (if provided) or cell (if provided and the notebook is not) and uses that
// as "preamble" when rendering the math item. This is done to support commands
// defined in one Markdown LaTeX equation and used in a later one (as supported
// by MathJax and often used in Jupyter notebook although it's not valid in
// real LaTeX). There are two caveats:
// 1. Only '\newcommand' gets this special treatment. MathJax also supports
//    definitions through '\def', '\newenvironment', '\renewcommand', etc. but
//    these don't get any special treatment here.
// 2. MathJax allows using '\newcommand' instead of '\renewcommand' to
//    redefine an existing command. There's no good way for us to support this
//    in the general case (e.g. when a single equation defines a command
//    several times with different values) so we only allow duplicate
//    definitions when they are redundant (redefining a command to the same
//    value) and raise an error otherwise. This covers the most common case
//    of duplicate definitions, where an equation or cell is duplicated by
//    copy-paste.
#let handler-math-markdown-cell(data, ctx: none, ..args) = {
  let defs = none
  if ctx.nb != none {
    // Get math definitions from the notebook if specified
    defs = ctx.nb.cells.map(_cell-latex-defs).join()
  } else if ctx.cell != none {
    // Otherwise fall back on definitions from cell if specified
    defs = _cell-latex-defs(ctx.cell)
  }
  // If we could collect definitions from the notebook or cell, we'll use those
  // (checking for conflicting duplicates) and remove definitions from the
  // math item itself to avoid duplicates.
  let txt = data
  if defs != none {
    // Remove definitions from this item's body and prepend all defs
    txt = _make-preamble(defs) + txt.replace(latex.command-definition, "")
  }
  // Render equation with the latex math handler
  return handle(txt, mime: "text/x.math", ctx: ctx, ..args)
}

// Handler for rich objects, where data is a dict keyed by MIME types, and
// metadta can be a simple metadata dict or a dict with metadata dicts keyed by
// MIME types. The item type can be specified, generally as an output item type
// or as "attachment". If given, the subhandler args will be forwarded to the
// subhandler called by this handler to handle a particular format.
#let handler-rich(
  data,
  ctx: none,
  metadata: none,
  type: none,
  subhandler-args: none,
  ..args,
) = {
  // Make item dict
  let item = (data: data, metadata: metadata)
  // Update context item desc
  ctx.item = (index: none, type: type)
  // Get dict with normalized data for this item
  let preprocessed = rich-object.preprocess(item, ctx: ctx)
  if preprocessed == none { return none }
  return rich-object.process(
    preprocessed,
    ctx: ctx,
    handler-args: subhandler-args,
  )
}

// Generic handler for source code
#let handler-source(data, ctx: none, lang: none, ..args) = {
  // Ensure the source has at least one (possibly empty) line
  // (without this the raw block looks weird for empty cells)
  if data == "" {
    data = "\n"
  }
  raw(data, lang: lang, block: true)
}

// Handler for source of Markdown cells
#let handler-source-markdown-cell(data, ctx: none, ..args) = {
  handle(data, mime: "text/x.source-generic", lang: "markdown", ctx: ctx)
}

// Handle for source of code cells
#let handler-source-code-cell(data, ctx: none, ..args) = {
  // Using ctx.lang (not ctx.cfg.lang) as it resolves auto to notebook lang
  handle(data, mime: "text/x.source-generic", lang: ctx.lang, ctx: ctx)
}

// Handler for source of raw cells
#let handler-source-raw-cell(data, ctx: none, ..args) = {
  handle(data, mime: "text/x.source-generic", lang: ctx.cfg.raw-lang, ctx: ctx)
}

// Handler for stream output items
#let handler-stream(data, ctx: none, name: none, ..args) = {
  raw(data, block: true, lang: "txt")
}

// Handler for error output items
#let handler-error(evalue, ctx: none, name: none, traceback: none, ..args) = {
  raw(evalue, block: true, lang: "txt")
}

// Built-in handlers for supported MIME types.
#let mime-handlers = (
  // Handlers for rich items (output items and cell attachments)
  "image/svg+xml": handler-svg-xml,
  "image/png"    : handler-image-base64,
  "image/jpeg"   : handler-image-base64,
  "image/gif"    : handler-image-base64,
  "text/markdown": handler-markdown,
  "text/latex"   : handler-latex,
  "text/plain"   : handler-text,
  // Special handlers for LaTeX math
  "text/x.math": handler-math, // base handler used by next one
  "text/x.math-markdown-cell": handler-math-markdown-cell, // Markdown cell math
  // Special handlers for specific kinds of text items
  "text/x.source-generic"  : handler-source, // takes a lang: argument
  "text/x.source-markdown-cell": handler-source-markdown-cell, // md cell source
  "text/x.source-code-cell": handler-source-code-cell, // code cell source
  "text/x.source-raw-cell" : handler-source-raw-cell,  // raw cell source
  "text/x.stream": handler-stream,
  "text/x.error": handler-error,
  // Generic image handlers
  "image/x.generic": handler-image-generic, // base handler used by others
  "image/x.base64" : handler-image-base64,  // base64 encoded image
  "image/x.text"   : handler-image-text,    // text encoded image
  "image/x.markdown-cell": handler-image-markdown-cell, // Markdown cell image
  // Special handler for rich objects which can be available in multiple formats
  "application/x.rich-object": handler-rich,
)
