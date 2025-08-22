#import "@preview/based:0.2.0": base64
#import "@preview/cmarker:0.1.6"
#import "@preview/mitex:0.2.5"

#import "reading/rich-object.typ"
#import "latex.typ"

// Handlers are always called with a positional argument for the data to
// handle, and a 'ctx' keyword argument for contextual data: a dict that
// includes at least least cell, format, handlers (full dict, not just the
// user handlers or 'auto') and ignore-wrong-format fields.
// Handlers must also accept arbitrary extra arguments for extensibility. This
// is used for example in image handlers which can receive an 'alt' value
// (and possibly also other values) to be forwarded to std.image.

// Handler for images in Markdown cells. Such images can be specified by a
// path of the form "attachment:name" where 'name' refers to a cell attachment.
#let handler-image-markdown-cell(path, ctx: none, ..args) = {
  let (handlers, cell) = ctx
  if path.starts-with("attachment:") {
    let name = path.trim("attachment:", at: start)
    let attachments = cell.at("attachments", default: (:))
    if name in attachments {
      // Get data dict (keyed by MIME type) for this attachment
      let data = attachments.at(name)
      let handler = handlers.at("application/x.rich-object")
      // This handler accepts metadata but we have none to give
      handler(data, ctx: ctx, metadata: (:), ..args)
    } else {
      panic("cell attachment " + name + " not found")
    }
  } else {
    handlers.at("image/x.path")(path, ctx: ctx, ..args)
  }
}

// Handler for base64-encoded images
#let handler-image-base64(data, ctx: none, ..args) = image(
  base64.decode(data.replace("\n", "")),
  ..args,
)
// Handler for text-encoded images, for example svg+xml
#let handler-image-text(data, ctx: none, ..args) = image(
  bytes(data),
  ..args,
)
// Handler for images given by path (must be defined by the user)
#let handler-image-path(data, ctx: none, ..args) = panic(
  "image path handler undefined; to render images given by path, define
  a handler for MIME type \"image/x.path\""
)
// Smart svg+xml handler that handles both text and base64 data
#let handler-svg-xml(data, ctx: none, ..args) = {
  // base64 encoded version of:     "<?xml "                        "<sv"
  let handler = if data.starts-with("PD94bWwg") or data.starts-with("PHN2") {
    ctx.handlers.at("image/x.base64")
  } else if data.starts-with("<?xml ") or data.starts-with("<svg") {
    ctx.handlers.at("image/x.text")
  } else {
    panic("Unrecognized svg+xml data")
  }
  handler(data, ctx: ctx, ..args)
}

// Handler for simple text
#let handler-text(data, ctx: none, ..args) = data

// Handler for Markdown markup
#let handler-markdown(data, ctx: none, ..args) = cmarker.render(
  data,
  math: ctx.handlers.at("application/x.latex-math").with(ctx: ctx),
  scope: (
    // Note that for images specified by disk path, the default markdown-cell
    // handler delegates to the "image/x.path" handler. Users should define
    // that handler to fix image path resolution (until Typst gets a 'path'
    // type).
    image: ctx.handlers.at("image/x.markdown-cell").with(ctx: ctx),
  ),
  ..args,
)

// Handler for LaTeX markup
#let handler-latex(data, ctx: none, ..args) = mitex.mitext(data, ..args)

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

// Make "preamble" string from given list of LaTeX definitions, removing
// redundant duplicates and raising an error if there are non-redundant
// (conflicting) duplicates.
#let _make-preamble(defs) = {
  let deduped = defs
  if deduped.len() > 1 {
    // Remove non-conflicting duplicates (that redefine a command to the same)
    let deduped = defs.dedup(key: latex.normalized-def-string)
    // Raise an error if there are remaining duplicates
    let prev = deduped.first()
    for x in deduped.slice(1) {
      if x.command == prev.command {
        panic("conflicting \\newcommand definitions: " +
         prev.command + " and " + x.command)
      }
      prev = x
    }
  }
  return deduped.map(latex.normalized-def-string).join("\n")
}

// Handler for a LaTeX math item (typically and equation in Markdown).
// This handler gathers all LaTeX \newcommand definitions from the notebook
// (if provided) or cell (if provided and the notebook is not) and use that
// as "preamble" when rendering the math item. This is done to support commands
// defined in one Markdown LaTeX equation and used in a later one (as supported
// by MathJax and often used in Jupyter notebook although it's not valid in
// real LaTeX). There are two caveats:
// 1. Only '\newcommand' gets this special treatment. MathJax also supports
//    definitions through '\def', '\newenvironment', '\renewcommand', etc but
//    these don't get any special treatment here.
// 2. MathJax allows using '\newcommand' instead of '\renewcommand' to
//    redefine an existing command. There's no good way for us to support this
//    in the general case (e.g. when a single equation defines a command
//    several times with different values) so we only allow duplicate
//    definitions when they are redundant (redefining a command to the same
//    value) and raise an error otherwise. This covers the most common case
//    of duplicate definitions, where an equation or cell is duplicated by
//    copy-paste.
#let handler-latex-math(data, ctx: none, ..args) = {
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
  return mitex.mitex(txt, ..args)
}

// Handler for rich objects, where data is a dict of possibly several available
// formats.
#let handler-rich(data, ctx: none, metadata: (:), ..args) = {
  let result = rich-object.process(
    data,
    metadata,
    cell: ctx.cell,
    format: ctx.format,
    all-handlers: ctx.handlers,
    ignore-wrong-format: ctx.ignore-wrong-format,
    handler-args: args,
  )
  if result == none { return none }
  return result.value
}

// Default handlers for supported MIME types.
#let mime-handlers = (
  "image/svg+xml": handler-svg-xml,
  "image/png"    : handler-image-base64,
  "image/jpeg"   : handler-image-base64,
  "image/gif"    : handler-image-base64,
  "text/markdown": handler-markdown,
  "text/latex"   : handler-latex,
  "text/plain"   : handler-text,
  // Special handler for LaTeX math
  "application/x.latex-math": handler-latex-math,
  // Generic image handlers
  "image/x.base64": handler-image-base64, // base64 encoded image
  "image/x.text"  : handler-image-text,   // text encoded image
  "image/x.path"  : handler-image-path,   // image determined by path string
  "image/x.markdown-cell": handler-image-markdown-cell, // image in Markdown cell
  // Special handler for rich objects which can be available in multiple formats
  "application/x.rich-object": handler-rich,
)

#let get-all-handlers(user-handlers) = {
  if user-handlers != auto and type(user-handlers) != dictionary {
    panic("handlers must be auto or a dictionary mapping formats to functions")
  }
  if user-handlers == auto {
    user-handlers = (:)
  }
  return mime-handlers + user-handlers
}
