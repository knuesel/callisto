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
// Can return none if item is available only in unsupported formats (and
// ignore-wrong-format is true) or if the item is empty (data dict empty in
// notebook JSON).
// The 'handlers' argument must be a valid dict (cannot be auto).
#let process(
  item-data,
  cell: none,
  format: auto,
  handlers: none,
  ignore-wrong-format: false,
  stream: "all",
  handler-args: none,
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
  let ctx = (
    cell: cell,
    format: format, // the general format spec, not the format picked here
    handlers: handlers,
    ignore-wrong-format: ignore-wrong-format,
  )
  return (
    format: fmt,
    value: read-mime(data, fmt, ctx: ctx, handler-args: handler-args),
  )
}
