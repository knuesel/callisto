#import "../common.typ": handle

// Functions to handle rich objects. A rich object is an object that can be
// available in multiple formats. It is given as a dict with MIME types as keys
// and data in the corresponding MIME type as values. This is how
// display_data/execute_result values and Markdown cell attachments are stored
// in the notebook.

// Default list of supported formats, in order of precedence: we will use
// the first format in this list that is available in the object dict.
#let default-formats = (
  "image/svg+xml",
  "image/png",
  "image/gif",
  "text/markdown",
  "text/latex",
  "text/plain",
)

// Return a normalized list of desired formats:
// - a single value is wrapped in an array
// - if the array contains the value 'auto', the default list is spliced at
//   that position
#let normalize-formats(formats) = {
  if type(formats) != array {
    formats = (formats,)
  }
  let i = formats.position(x => x == auto)
  if i != none {
    // Replace auto value with list of default formats
    formats = formats.slice(0, i) + default-formats + formats.slice(i + 1)
  }
  return formats
}

// Pick one format in the list of available formats according to the given
// precedence which can be 'auto', a single format, or a list of formats
// (which can itself contain 'auto' to represent the default list)
#let pick-format(available, precedence: auto) = {
  precedence = normalize-formats(precedence)
  // Pick the first desired format that is available, or none
  return precedence.find(f => f in available)
}

// Process a "rich" object, which can be available in multiple formats.
// The item-data and item-metadata arguments are dicts keyed by MIME types.
// Can return none if item is available only in unsupported formats (and
// ignore-wrong-format is true) or if the item is empty (data dict empty in
// notebook JSON).
// - handler-args: extra arguments to pass to the handler that will handle the
//   item data (there is no such arguments when processing an output item, but
//   for an image attachment in a Markdown cell for example the Markdown can
//   define an 'alt' value that will be passed as a handler argument.
#let process-value(
  item-data,
  item-metadata,
  ctx: none,
  handler-args: none,
) = {
  if item-data.len() == 0 { return none }
  let fmt = pick-format(item-data.keys(), precedence: ctx.cfg.format)
  if fmt == none {
    if not ctx.cfg.ignore-wrong-format {
      panic("output item has no appropriate format: item has " +
        repr(item-data.keys()) + ", we want " +
        repr(normalize-formats(ctx.cfg.format)))
    }
    return none
  }
  if item-metadata == none {
    item-metadata = (:)
  }
  let fmt-data = item-data.at(fmt)
  if type(fmt-data) == array {
    fmt-data = fmt-data.join()
  }
  let fmt-metadata = item-metadata.at(fmt, default: (:))
  let rich-desc = (
    format: fmt,
    metadata: fmt-metadata,
    // Also provide whole item metadata, since the spec says "The metadata of
    // these messages *may* be keyed by mime-type as well" (our emphasis).
    full-metadata: item-metadata,
  )
  let new-ctx = (..ctx, rich-item: rich-desc)
  let val = handle(fmt-data, fmt, ctx: new-ctx, ..handler-args)
  return (..rich-desc, value: val)
}


// Process a rich item, i.e. an item that can be available in multiple formats.
// Can return none if item is available only in unsupported formats (and
// ignore-wrong-format is true) or if the item is empty (data dict empty in
// notebook JSON).
#let process-output(item, ctx: none) = {
  // When processing an output item, there's no handler-args
  let result = process-value(item.data, item.metadata, ctx: ctx)
  if result == none { return none }
  return (
    type: item.output_type,
    ..result,
  )
}
