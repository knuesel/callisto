#let default-formats = (
  "image/svg+xml",
  "image/png",
  "image/gif",
  "text/markdown",
  "text/latex",
  "text/plain",
)

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

#let pick-format(available, precedence: auto) = {
  precedence = normalize-formats(precedence)
  // Pick the first desired format that is available, or none
  return precedence.find(f => f in available)
}

// Interpret data according to MIME format and handlers specified in ctx.
// The appropriate handler will be called with the data, ctx, and all arguments
// in handler-args.
#let read-mime(data, fmt, ctx: none, handler-args: none) = {
  if fmt not in ctx.handlers {
    panic("format " + repr(fmt) +
      " has no registered handler (is it a valid MIME string?)")
  }
  let handler = ctx.handlers.at(fmt)
  if type(handler) != function {
    panic("handler must be a function or a dict of functions")
  }
  if type(data) == array {
    data = data.join()
  }
  return handler(data, ctx: ctx, ..handler-args)
}

// Process a "rich" object, which can be available in multiple formats.
// The item-data and item-metadata arguments are dicts keyed by MIME types.
// Can return none if item is available only in unsupported formats (and
// ignore-wrong-format is true) or if the item is empty (data dict empty in
// notebook JSON).
// The 'all-handlers' argument must be "resolved" (cannot be auto, and must
// include the default handlers as well as the user-specified handlers).
// The ctx argument is optional. A new context will be created anyway,
// but an existing context can be specified to be included as parent context.
#let process(
  item-data,
  item-metadata,
  cell: none,
  format: auto,
  all-handlers: none,
  ignore-wrong-format: false,
  stream: "all",
  handler-args: none,
  ctx: none,
) = {
  let item-formats = item-data.keys()
  if item-formats.len() == 0 {
    return none
  }
  let fmt = pick-format(item-formats, precedence: format)
  if fmt == none {
    if not ignore-wrong-format {
      panic("output item has no appropriate format: item has " +
        repr(item-formats) + ", we want " + repr(normalize-formats(format)))
    }
    return none
  }
  let data = item-data.at(fmt)
  let new-ctx = (
    cell: cell,
    format: format, // the general format spec, not the format picked here
    handlers: all-handlers,
    ignore-wrong-format: ignore-wrong-format,
    // Item specific fields
    item: (
      selected-format: fmt,
      metadata: item-metadata.at(fmt, default: (:)),
      // Also provide whole item metadata, since the spec says "The metadata of
      // these messages *may* be keyed by mime-type as well" (our emphasis).
      full-metadata: item-metadata,
    ),
    // Parent context if any
    parent: ctx,
  )
  return (
    format: fmt,
    metadata: item-metadata.at(fmt, default: (:)),
    // Also provide whole item metadata, since the spec says "The metadata of
    // these messages *may* be keyed by mime-type as well" (our emphasis).
    full-metadata: item-metadata,
    value: read-mime(data, fmt, ctx: new-ctx, handler-args: handler-args),
  )
}
