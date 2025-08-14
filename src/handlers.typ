#import "@preview/based:0.2.0": base64
#import "@preview/cmarker:0.1.6"
#import "@preview/mitex:0.2.5"

/// Function like std.image, but also supports images given by path of the form
// "attachment:name" where 'name' refers to a cell attachment.
// - handler-args: 
//  in this case the image data is 
// when the image is given by path and the path
//
//  but accepts extra arguments to 'preload'
/// (formal term: partial application)
/// - handlers (dict): When the path is an attachment, key "rich-object" is
///   needed (to recurse). Otherwise key "image/x.path" is used.
/// - attachments (dict): Dict of embedded images from the Jupyter notebook cell
/// -> content (image)
#let markdown-cell-image(path, alt: none, handlers: none, attachments: (:), ..args) = {
  if handlers == none or handlers == auto {
    panic("No valid handlers dict provided for mutual recursion (value was " + repr(handlers) + ")")
  }
  if path.starts-with("attachment:") {
    let name = path.trim("attachment:", at: start)
    if name in attachments {
      // Get data dict (keyed by MIME type) for this attachment
      let data = attachments.at(name)
      // Mutual recursion. Will profit fromt the existing image handlers.
      let process-rich = handlers.at("application/x.rich-object")
      process-rich(data, ..args).value
    } else {
      panic("Jupyter notebook attachment " + name + " not found in attachments: " + repr(attachments))
    }
  } else {
    handlers.at("image/x.path")(path, alt: alt)
  }
}

// Handler for base64-encoded images
#let handler-image-base64(data, alt: none, ..args) = image(
  base64.decode(data.replace("\n", "")),
  alt: alt,
)
// Handler for text-encoded images, for example svg+xml
#let handler-image-text(data, alt: none, ..args) = image(bytes(data), alt: alt)
// Handler for images given by path
#let handler-image-path(data, alt: none, ..args) = image(data, alt: alt)
// Smart svg+xml handler that handles both text and base64 data
#let handler-svg-xml(data, handlers: none, ..args) = {
  // Get the base64 and str handlers from the dict so the user can override them
  if handlers == none { panic("Smart svg+xml handler needs a handlers dict to delegate, but " + repr(handlers) + " was given.") }
  // base64 encoded version of:     "<?xml "                        "<sv"
  let handler = if data.starts-with("PD94bWwg") or data.starts-with("PHN2") {
    handlers.at("image/x.base64")
  } else if data.starts-with("<?xml ") or data.starts-with("<svg") {
    handlers.at("image/x.text")
  } else {
    panic("Unrecognized svg+xml data")
  }
  handler(data, ..args)
}

// Handler for simple text
#let handler-text(data, ..args) = data
// Handler for Markdown markup
#let handler-markdown(data, ..args) = cmarker.render(
  data,
  math: mitex.mitex,
  // Like the std.image function, but 'preload' it with extra arguments
  // to resolve 'attachments'
  scope: (image: markdown-cell-image.with(..args)),
)
// Handler for LaTeX markup
#let handler-latex(data, ..args) = mitex.mitext(data)

// Default handlers for supported MIME types.
// All handlers must accept a positional argument for the data to handle, and
// arbitrary keyword arguments
#let mime-handlers = (
  "image/svg+xml": handler-svg-xml,
  "image/png"    : handler-image-base64,
  "image/jpeg"   : handler-image-base64,
  "image/gif"    : handler-image-base64,
  "text/markdown": handler-markdown,
  "text/latex"   : handler-latex,
  "text/plain"   : handler-text,
  // Abstract handlers to process images based on their data encoding
  // Luckily, Typst can detect what the actual image format is (png, svg, ...)
  "image/x.base64": handler-image-base64, // data is a base64 encoded image
  "image/x.text"  : handler-image-text,   // data is a text encoded image
  "image/x.path"  : handler-image-path,   // data is a image determined by 'path' string
  // Add handler for a rich object. Used for mutual recursion.
  "application/x.rich-object": (..args) => panic("rich object handler is not replaced by a working function"),
)

#let get-all-handlers(user-handlers, rich-handler) = {
  if user-handlers != auto and type(user-handlers) != dictionary {
    panic("handlers must be auto or a dictionary mapping formats to functions")
  }
  // Start with default handlers
  let handlers = mime-handlers
  // Override with user handlers if any
  if user-handlers != auto {
    handlers += user-handlers
  }
  // Add special handler for rich objects
  handlers.insert("application/x.rich-object", rich-handler.with(handlers: handlers))
  return handlers
}
