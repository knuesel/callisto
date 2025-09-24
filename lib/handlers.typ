#import "@preview/based:0.2.0": base64
#import "@preview/cmarker:0.1.6"
#import "@preview/mitex:0.2.5"

#import "common.typ": handle
#import "reading/rich-object.typ"
#import "reading/stream.typ"
#import "reading/error.typ"
#import "reading/output.typ": outputs
#import "latex.typ"

// A handler is a function called to render a value such as a cell's source,
// a cell output or even a whole cell.
// Each handler is associated with a MIME type. Rich items, which can be
// available in multiple formats, are rendered by calling the handler on the
// selected format. In this case the type is a real MIME type, for example
// "image/png". Other handlers use dummy MIME types such as "code-cell"
// (without slash character).
//
// Handlers are always called with a positional argument for the data to
// render, and a 'ctx' keyword argument for contextual data. Some handlers also
// take additional arguments:
// 
// - Image handlers must accept an 'alt' argument.
// 
// - Math handlers must accept a 'block' argument (true for block equations).
//
// - The "source-code-generic" handler (used by the default raw cell and
//   code input handlers) takes a 'lang' argument.
//
// - The "attachment" handler gets 'metadata', 'type' and
//   'subhandler-args' arguments.
//
// - XXX consider rethinking the above
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
      "handler for MIME type \"image-generic\"")
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
        mime: "attachment",
        ctx: ctx,
        metadata: (path: path),
        subhandler-args: args,
      )
    } else {
      panic("cell attachment " + name + " not found")
    }
  } else {
    handle(path, mime: "image-generic", ctx: ctx, ..args)
  }
}

// Handler for base64-encoded images
#let handler-image-base64(data, ctx: none, ..args) = {
  let data-bytes = base64.decode(data.replace("\n", ""))
  handle(data-bytes, mime: "image-generic", ctx: ctx, ..args)
}

// Handler for text-encoded images, for example svg+xml
#let handler-image-text(data, ctx: none, ..args) = {
  handle(bytes(data), mime: "image-generic", ctx: ctx, ..args)
}

// Helper function to guess the SVG data encoding based on the first characters
// in the given data string.
#let _encoded-svg-mime(data) = {
  // base64 encoded version of:     "<?xml "                        "<sv"
  if data.starts-with("PD94bWwg") or data.starts-with("PHN2") {
    return "image-base64"
  } else if data.starts-with("<?xml ") or data.starts-with("<svg") {
    return "image-text"
  }
  panic("unrecognized svg+xml data")
}

// Smart svg+xml handler that handles both text and base64 data
#let handler-image-svg-xml(data, ctx: none, ..args) = {
  let mime = _encoded-svg-mime(data)
  handle(data, mime: mime, ctx: ctx, ..args)
}

// Handler for Markdown markup to be rendered inline, without block wrapper.
// (This is useful for Markdown that must be included seamlessly in the flow
// of the document, so that e.g. spacing around headings can be configured
// without interference from a container block, see
// https://github.com/knuesel/callisto/issues/13)
#let handler-markdown-generic(data, ctx: none, ..args) = cmarker.render(
  data,
  math: handle.with(mime: "math-markdown-cell", ctx: ctx),
  scope: (
    // Note that for images specified by disk path, the default markdown-cell
    // handler delegates to the "image-generic" handler. Users should define
    // that handler to fix image path resolution (until Typst gets a 'path'
    // type).
    image: handle.with(mime: "image-markdown-cell", ctx: ctx),
  ),
  ..args,
)

// Handler for Markdown markup to be rendered as one or several paragraphs but
// without a block wrapper (see handler-markdown-generic).
#let handler-markdown-par(data, ctx: none, ..args) = {
  parbreak()
  handle(data, mime: "markdown-generic", ctx: ctx, ..args)
  parbreak()
}

// Handler for Markdown outputs
#let handler-text-markdown(data, ctx: none, ..args) = {
  block(handle(data, mime: "markdown-generic", ctx: ctx, ..args))
}

// Handler for LaTeX markup
#let handler-text-latex(data, ctx: none, ..args) = block(mitex.mitext(data, ..args))

// Handler for simple text
#let handler-text-plain(data, ctx: none, ..args) = {
  raw(data, block: true, lang: "txt")
}

// Handler for LaTeX equations
#let handler-math-generic(data, ctx: none, ..args) = mitex.mitex(data, ..args)

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
  return handle(txt, mime: "math-generic", ctx: ctx, ..args)
}

// Handler for attachments, where data is a dict keyed by MIME types, and
// metadata can be a simple metadata dict or a dict with metadata dicts keyed
// by MIME types. If given, the subhandler args will be forwarded to
// the subhandler called by this handler to handle a particular format.
#let handler-attachment(
  data,
  ctx: none,
  metadata: none,
  subhandler-args: none,
  ..args,
) = {
  // Make item dict
  let item = (data: data, metadata: metadata)
  // Update context item desc
  ctx.item = (index: none, type: "attachment")
  // Get dict with normalized data for this item
  let preprocessed = rich-object.preprocess(item, ctx: ctx)
  if preprocessed == none { return none }
  return rich-object.process(
    preprocessed,
    ctx: ctx,
    handler-args: subhandler-args,
  )
}

// Generic stream handler
#let handler-stream-generic(data, ctx: none, ..args) = {
  raw(data, block: true, lang: "txt")
}

// Handler for stream output items
#let handler-stream(item, ctx: none, ..args) = {
  let mime = (
    "stdout": "stream-stdout",
    "stderr": "stream-stderr",
    "all": "stream-merged",
  ).at(item.name)
  handle(item.text, mime: mime, ctx: ctx, ..args)
}

// Handler for error output items
#let handler-error(item, ctx: none, ..args) = {
  raw(item.evalue, block: true, lang: "txt")
}

// Handler for rich output items (display_data and result)
#let handler-rich-item-generic(data, ctx: none, ..args) = {
  rich-object.process(data, ctx: ctx, ..args)
}

// Handler for any type of code cell output
#let handler-output(data, ctx: none, ..args) = {
  handle(data, mime: ctx.item.type, ctx: ctx, ..args)
}

// Handler for source code
#let handler-source-code-generic(txt, ctx: none, lang: none, ..args) = {
  // Ensure the source has at least one (possibly empty) line
  // (without this the raw block looks weird for empty cells)
  if txt == "" {
    txt = "\n"
  }
  raw(txt, lang: lang, block: true)
}

// Handler for raw cell
#let handler-raw-cell(cell, ctx: none, ..args) = {
  handle(
    cell.source,
    mime: "source-code-generic",
    ctx: ctx,
    lang: ctx.cfg.raw-lang,
    ..args,
  )
}

// Handler for Markdown cell
#let handler-markdown-cell(cell, ctx: none, ..args) = {
  handle(cell.source, mime: "markdown-par", ctx: ctx, ..args)
}

// Handler for code cell input
#let handler-code-cell-input(cell, ctx: none, ..args) = {
  handle(
    cell.source,
    mime: "source-code-generic",
    ctx: ctx,
    lang: ctx.lang,
    ..args,
  )
}

// Handler for code cell output
#let handler-code-cell-output(cell, ctx: none, ..args) = {
  // Get outputs with user config, but override 'result' to get just the values
  outputs(cell, ..ctx.cfg, result: "value").join()
}

// Handler for code cell
#let handler-code-cell(cell, ctx: none, ..args) = {
  if ctx.cfg.input {
    handle(cell, mime: "code-cell-input", ctx: ctx, ..args)
  }
  if ctx.cfg.output {
    handle(cell, mime: "code-cell-output", ctx: ctx, ..args)
  }
}

// Handler for cells
#let handler-cell(cell, ctx: none, ..args) = {
  // Delegate to cell-type-specific handler
  handle(cell, mime: cell.cell_type + "-cell", ctx: ctx, ..args)
}

// Default handlers
#let default = (
  // Handlers for specific formats of rich items (outputs and cell attachments)
  "image/svg+xml": handler-image-svg-xml,
  "image/png"    : handler-image-base64,
  "image/jpeg"   : handler-image-base64,
  "image/gif"    : handler-image-base64,
  "text/markdown": handler-text-markdown,
  "text/latex"   : handler-text-latex,
  "text/plain"   : handler-text-plain,
  // Generic image handlers
  "image-generic": handler-image-generic, // base handler used by others
  "image-base64" : handler-image-base64,  // base64 encoded image
  "image-text"   : handler-image-text,    // text encoded image
  "image-markdown-cell": handler-image-markdown-cell, // Markdown cell image
  // Handlers for output items
  "rich-item-generic": handler-rich-item-generic,
  "display_data": handler-rich-item-generic,
  "execute_result": handler-rich-item-generic,
  "error": handler-error,
  "stream-generic": handler-stream-generic,
  "stream-stdout": handler-stream-generic,
  "stream-stderr": handler-stream-generic,
  "stream-merged": handler-stream-generic, // used when both streams are merged
  "stream": handler-stream, // called before stream-type-specific handler
  "output": handler-output, // called before output-type-specific handler
  // Handlers for Markdown as part of the document flow
  "markdown-generic": handler-markdown-generic,
  "markdown-par": handler-markdown-par,
  // Handlers for LaTeX math
  "math-generic": handler-math-generic, // base handler for math
  "math-markdown-cell": handler-math-markdown-cell, // Markdown cell math
  // Handlers for cell rendering
  "raw-cell": handler-raw-cell,
  "markdown-cell": handler-markdown-cell,
  "code-cell-input": handler-code-cell-input,
  "code-cell-output": handler-code-cell-output,
  "code-cell": handler-code-cell,
  "cell": handler-cell, // called before the cell-type-specific handler
  // Other handlers
  "source-code-generic": handler-source-code-generic,
  "attachment": handler-attachment,
)
