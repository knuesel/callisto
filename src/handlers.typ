#import "@preview/based:0.2.0": base64
#import "@preview/cmarker:0.1.6"
#import "@preview/mitex:0.2.5"

#import "reading/rich-object.typ"

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
  math: mitex.mitex,
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
