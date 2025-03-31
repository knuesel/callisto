#import "@preview/based:0.2.0": base64

#let handler-base64-image(data) = image(base64.decode(data.trim()))
#let handler-str-image(data) = image(bytes(data))
#let handler-text(data) = raw(data, block: true)

#let cell-header-pattern = regex("^#\|\s+(.*?):\s+(.*?)\s*$")
#let default-formats = ("image/svg+xml", "image/png", "text/plain")
#let default-handlers = (
  "image/svg+xml": handler-str-image,
  "image/png": handler-base64-image,
  "image/jpeg": handler-base64-image,
  "text/plain": handler-text,
)
#let default-names = ("metadata.label", "id", "tags")

// Normalize cell dict (ensuring the source is a single string rather than an
// array with one string per line) and convert source header metadata to cell
// metadata.
#let process-cell(i, cell) = {
  if "id" not in cell {
    cell.id = str(i)
  }
  let source = cell.at("source", default: "")
  if type(source) == array {
    // Normalize source field to a single string
    source = if source.len() == 0 { "" } else { source.join() }
  }
  if cell.cell_type == "code" {
    let source_lines = source.split("\n")

    // Convert metadata in code header to cell metadata
    let n = 0
    for line in source_lines {
      let m = line.match(cell-header-pattern)
      if m == none {
        break
      }
      n += 1
      let (key, value) = m.captures
      cell.metadata.insert(key, value)
    }
    // If there was a header, remove it from the source
    if n > 0 {
      source = source_lines.slice(n).join("\n")
    }
  }
  return (
    ..cell,
    source: source,
  )
}

#let read-notebook(nb) = {
  if type(nb) not in (str, bytes, dictionary) {
    panic("invalid notebook type: " + str(type(nb)))
  }
  if type(nb) in (str, bytes) {
    nb = json(nb)
  }
  if not nb.metadata.at("nbio-processed", default: false) {
    nb.cells = nb.cells.enumerate().map( ((i, c)) => process-cell(i, c) )
  }
  return nb
}

#let notebook-lang(nb) = {
  if nb == none {
    return none
  }
  return read-notebook(nb).metadata.language_info.name
}

// Get value at given path in recursive dict.
// The path can be a string of the form `key1.key2....`, or an array
// `(key1, key2, ...)`.
#let at-path(dict, path, default: none) = {
  if type(path) == str { return at-path(dict, path.split(".")) }
  let (key, ..rest) = path
  if key not in dict { return default }
  let value = dict.at(key)
  if rest == () { return value }
  return at-path(value, rest)
}

#let ensure-array(x) = if type(x) == array { x } else { (x,) }

// Get cells for a single specification
#let _cells(spec, nb-cells, count, name) = {
  if type(spec) == dictionary {
    // Literal cell. We must still return an array.
    return (spec,)
  }
  if spec == none {
    // Select all cells
    return nb-cells
  }
  if type(spec) == function {
    // Filter with given predicate
    return nb-cells.filter(spec)
  }
  if type(spec) == str {
    // Match on any of the specified names
    let names = if name == auto {
      default-names
    } else {
      ensure-array(name)
    }
    return nb-cells.filter(x => names.any(path => at-path(x, path) == spec))
  }
  if type(spec) == int {
    if count == "position" {
      // Cell specified by its index. We must still return an array.
      return (nb-cells.at(spec),)
    }
    if count == "execution" {
      return nb-cells
        .filter(x => x.at("execution_count", default: none) == spec)
    }
    panic("invalid cell count mode:" + repr(count))
  }
  panic("invalid cell specification: " + repr(spec))
}

// Cell selector. The type parameter is a filter applied at the end.
#let cells(
  ..args,
  nb: none,
  count: "position",
  name: auto,
  type: "all",
) = {
  if args.named().len() > 0 {
    panic("invalid named arguments: " + repr(args.named()))
  }
  if type == "all" {
    type = ("code", "markdown", "raw")
  }
  let types = ensure-array(type)
  let specs = args.pos()
  if specs.len() == 0 {
    // Note: none (no selector) means all cells in notebook
    specs = (none,)
  }
  if specs.all(x => std.type(x) == dictionary) {
    // No need to read the notebook
    return specs
  }
  let nb = read-notebook(nb)
  let cells = ()
  for spec in specs {
    // Concatenate cells for each spec
    cells += _cells(spec, nb.cells, count, name)
      .filter(x => x.cell_type in types)
  }
  return cells
}

#let cell(..args) = {
  let cs = cells(..args)
  if cs.len() == 0 {
    panic("no cell found for specification " + repr(spec))
  }
  if cs.len() > 1 {
    panic("multiple cells founds for specification " + repr(spec))
  }
  return cs.first()
}

#let normalize-formats(formats) = {
  formats = ensure-array(formats)
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

#let read-mime(format, data, handlers) = {
  if type(data) == array {
    data = data.join()
  }
  if handlers == auto {
    handlers = default-handlers
  }
  if type(handlers) != dictionary {
    panic("handlers must be a dictionary mapping formats to functions")
  }
  if format not in handlers {
    panic("format " + repr(format) + " has no registered handler")
  }
  let handler = handlers.at(format)
  if type(handler) != function {
    panic("handler must be a function or a dict of functions")
  }
  return handler(data)
}

// Process a "rich" item, which can have various formats.
// Can return none if item is available only in unsupported formats.
#let process-rich(
  item,
  format: auto,
  handlers: auto,
  ignore-wrong-format: false,
  ..args,
) = {
  let item-formats = item.data.keys()
  let fmt = pick-format(item-formats, precedence: format)
  if fmt == none {
    if not ignore-wrong-format {
      panic("output item has no appropriate format: item has " +
        repr(item-formats) + ", we want " + repr(normalize-formats(format)))
    }
    return none
  }
  let value = read-mime(fmt, item.data.at(fmt), handlers)
  return (
    type: item.output_type,
    format: fmt,
    metadata: item.metadata.at(fmt, default: none),
    value: value,
  )
}

// Process a stream item.
// Can return none if the item is from an undesired stream (cf `stream` arg.)
#let process-stream(item, stream: "all", ..args) = {
  if stream == none {
    return none
  }
  if stream == "all" {
    stream = ("stdout", "stderr")
  }
  let streams = ensure-array(stream)
  if item.name not in streams {
    return none
  }
  let value = item.text
  if type(value) == array {
    value = value.join()
  }
  return (
    type: "stream",
    name: item.name,
    value: value,
  )
}

// Process an error item.
#let process-error(item, ..args) = (
  type: "error",
  name: item.ename,
  value: item.evalue,
  traceback: item.traceback,
)

#let processors = (
  display_data: process-rich,
  execute_result: process-rich,
  stream: process-stream,
  error: process-error,
)

#let cell-output-dict(cell) = (
  id: cell.id,
  execution-count: cell.execution_count,
  metadata: cell.metadata,
  type: cell.cell_type,
)

#let final-output(cell, output-spec, dict) = { 
  if output-spec == "value" {
    return dict.value
  }
  if output-spec == "dict" {
    dict.cell = cell-output-dict(cell)
    return dict
  }
  panic("invalid output specification: " + repr(output))
}

#let outputs(
  ..cell-args,
  type: "all",
  format: default-formats,
  handlers: auto,
  ignore-wrong-format: false,
  stream: "all",
  output: "value",
) = {
  if type == "all" {
    type = ("display_data", "execute_result", "stream", "error")
  }
  let types = ensure-array(type)
  let process-args = (
    format: format,
    handlers: handlers,
    ignore-wrong-format: ignore-wrong-format,
    stream: stream,
  )
  let cs = cells(..cell-args, type: "code")
  let outs = ()
  for cell in cs {
    outs += cell.outputs
      .filter(x => x.output_type in types)
      .map(x => (processors.at(x.output_type))(x, ..process-args))
      .filter(x => x != none)
      .map(final-output.with(cell, output))
  }
  return outs
}

#let single-item(items, item: "unique") = {
  if item == "unique" {
    if items.len() != 1 {
      panic("expected 1 item, found " + str(items.len()))
    }
    item = 0
  }
  return items.at(item)
}

#let output(..args, item: "unique") = single-item(outputs(..args), item: item)

#let displays     = outputs.with(type: "display_data")
#let results      = outputs.with(type: "execute_result")
#let errors       = outputs.with(type: "error")
#let stream-items = outputs.with(type: "stream")

#let display     = output.with(type: "display_data")
#let result      = output.with(type: "execute_result")
#let error       = output.with(type: "error")
#let stream-item = output.with(type: "stream")

// Same as stream-items, but merges all streams (matching `type`) of the same cell, and always returns an item (possibly with an empty string as value) for each selected cell (of code type).
#let streams(
  ..cell-args,
  stream: "all",
  output: "value",
) = {
  let cs = cells(..cell-args, type: "code")
  let outs = ()
  for cell in cs {
    // Start value
    let out = (
      type: "stream",
      name: stream,
      value: "",
    )
    // Append all stream items to value
    for item in outputs(cell, type: "stream", stream: stream, output: "value") {
      out.value += item
    }
    outs.push(final-output(cell, output, out))
  }
  return outs
}

#let stream(..args, item: "unique") = single-item(streams(..args), item: item)

#let sources(..args, output: "value", lang: auto) = {
  if lang == auto {
    let nb = args.named().at("nb", default: none)
    lang = notebook-lang(nb)
  }
  let cs = cells(..args)
  let srcs = ()
  for cell in cs {
    let value = raw(cell.source, lang: lang, block: true)
    srcs.push(final-output(cell, output, (value: value)))
  }
  return srcs
}

#let source(..args, item: "unique") = single-item(sources(..args), item: item)
