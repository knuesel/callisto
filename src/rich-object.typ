// TODO: deduplicate this and reading.typ's version
#let default-formats = ("image/svg+xml", "image/png", "image/gif", "text/markdown", "text/latex", "text/plain")

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

// Interpret data according to the given MIME format string, using the given
// handlers dict for decoding.
#let read-mime(data, format: none, handlers: none, ..args-handler) = {
  // let all-handlers = get-all-handlers(handlers)
  let all-handlers = handlers // TODO: fix
  if format == none or format not in all-handlers {
    panic("format " + repr(format) + " has no registered handler (is it a valid MIME string?)")
  }
  let handler = all-handlers.at(format)
  if type(handler) != function {
    panic("handler must be a function or a dict of functions")
  }
  if type(data) == array {
    data = data.join()
  }
  // Pass expanded(!) handlers along for mutual recursion: https://github.com/typst/typst/issues/744
  return handler(data, handlers: all-handlers, ..args-handler)
}

// Process a "rich" object, which can be available in multiple formats.
// Can return none if item is available only in unsupported formats (and
// ignore-wrong-format is true) or if the item is empty (data dict empty in
// notebook JSON).
// The 'handlers' argument must be a valid dict (cannot be auto).
#let process(
  item-data,
  format: auto,
  handlers: none,
  ignore-wrong-format: false,
  ..args-handler,
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
  // Add rich object handler (this must be done in every call to this function
  // since the handlers dict cannot refer to itself, so the 'handlers' argument
  // received by this function and pre-applied below in process.with(...)
  // contains no rich object handler.
  handlers.insert(
    "application/x.rich-object",
    process.with(
      format: format,
      handlers: handlers,
      ignore-wrong-format: ignore-wrong-format,
    ),
  )
  let value = read-mime(item-data.at(fmt), format: fmt, handlers: handlers, ..args-handler)
  return (
    format: fmt,
    value: value,
  )
}

