#import "@preview/based:0.2.0": base64
#import "@preview/cmarker:0.1.6"
#import "@preview/mitex:0.2.5"

/// Function like std.image, but accepts extra arguments to 'preload'
/// (formal term: partial application)
/// - handlers (dict): When the path is an attachment, key "rich-object" is
///   needed (to recurse). Otherwise key "image/x.path" is used.
/// - attachments (dict): Dict of embedded images from the Jupyter notebook cell
/// -> content (image)
#let image-markdown-cell(path, alt: none, handlers: none, attachments: (:), ..args) = {
  if handlers == none or handlers == auto {
    panic("No valid handlers dict provided for mutual recursion (value was " + repr(handlers) + ")")
  }
  if path.starts-with("attachment:") {
    let filename = path.trim("attachment:", at: start)
    if filename in attachments {
      let file = attachments.at(filename)
      // Mutual recursion. Will profit fromt the existing image handlers.
      let process-rich = handlers.at("application/x.rich-object")
      process-rich(file, ..args).value
    } else {
      panic("Jupyter notebook attachment " + filename + " not found in attachments: " + repr(attachments))
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
  scope: (image: image-markdown-cell.with(..args)),
)
// Handler for LaTeX markup
#let handler-latex(data, ..args) = mitex.mitext(data)

// Default handlers.
// All handlers must accept a positional argument for the data to handle, and
// arbitrary keyword arguments
#let default-handlers = (
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

#let default-cell-header-pattern = regex("^# ?\|\s+(.*?):\s+(.*?)\s*$")
#let default-formats = ("image/svg+xml", "image/png", "image/gif", "text/markdown", "text/latex", "text/plain")
#let default-names = ("metadata.label", "id", "metadata.tags")
#let all-output-types = ("display_data", "execute_result", "stream", "error")

// Convert metadata in code header to cell metadata
#let _process-cell-header(cell, cell-header-pattern, keep-cell-header) = {
  if cell-header-pattern == none {
    return cell
  }
  if cell-header-pattern == auto {
    cell-header-pattern = default-cell-header-pattern
  }
  if type(cell-header-pattern) != regex {
    panic("cell-header-pattern must be a regular expression or auto or none")
  }
  let source_lines = cell.source.split("\n")
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
  // Remove header from source if necessary
  if not keep-cell-header and n > 0 {
    cell.source = source_lines.slice(n).join("\n")
  }
  return cell
}

// Normalize cell dict (ensuring the source is a single string rather than an
// array with one string per line) and convert source header metadata to cell
// metadata, using cell-header-pattern to recognize and parse cell header lines.
#let _process-cell(i, cell, cell-header-pattern, keep-cell-header) = {
  if "id" not in cell {
    cell.id = str(i)
  }
  cell.index = i
    // Normalize source field to a single string
  if "source" in cell and type(cell.source) == array {
    cell.source = cell.source.join() // will be none if array is empty
  }
  if "source" not in cell or cell.source == none {
    cell.source = ""
  }
  if cell.cell_type == "code" {
    cell = _process-cell-header(cell, cell-header-pattern, keep-cell-header)
  }
  return cell
}

#let _read-notebook(nb, cell-header-pattern, keep-cell-header) = {
  if type(nb) not in (str, bytes, dictionary) {
    panic("invalid notebook type: " + str(type(nb)))
  }
  let nb-json = if type(nb) in (str, bytes) { json(nb) } else { nb }
  if not nb-json.metadata.at("nbio-processed", default: false) {
    nb-json.cells = nb-json.cells
      .enumerate().map(
        ((i, c)) => _process-cell(i, c, cell-header-pattern, keep-cell-header)
      )
  }
  return nb-json
}

// Return the language name of the given notebook json
#let _notebook-lang(nb-json) = nb-json.metadata.language_info.name

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

#let name-matches(cell, spec, name) = {
  let value = at-path(cell, name)
  return value == spec or (type(value) == array and spec in value)
}

#let _cell-type-array(cell-type) = {
  if cell-type == "all" {
    cell-type = ("code", "markdown", "raw")
  }
  return ensure-array(cell-type)
}

#let _filter-type(cells, cell-type) = {
  let types = _cell-type-array(cell-type)
  cells.filter(x => x.cell_type in types)
}

// Get cell indices for a single specification.
// If no cell matches, an empty array is returned.
// The cells-of-type array contains cells already filtered to match cell-type.
// The all-cells array contains all cells and can be used for performance for
// cells specified by their index.
#let _cell-indices(spec, cell-type, cells-of-type, all-cells, count, name-path) = {
  if type(spec) == dictionary {
    // Literal cell
    return _filter-type((spec,), cell-type).map(c => c.index)
  }
  if type(spec) == function {
    // Filter with given predicate
    return cells-of-type.filter(spec).map(c => c.index)
  }
  if type(spec) == str {
    // Match on any of the specified names
    let names = if name-path == auto {
      default-names
    } else {
      ensure-array(name-path)
    }
    return cells-of-type
      .filter(x => names.any(name-matches.with(x, spec)))
      .map(c => c.index)
  }
  if type(spec) == int {
    if count == "index" {
      let type-ok = all-cells.at(spec).cell_type in _cell-type-array(cell-type)
      return if type-ok { (spec,) } else { () }
    }
    if count == "execution" {
      // Different cells can have the same execution_count, e.g. when evaluating
      // only some cells after a kernel restart.
      return cells-of-type
        .filter(x => x.at("execution_count", default: none) == spec)
        .map(c => c.index)
    }
    panic("invalid cell count mode:" + repr(count))
  }
  panic("invalid cell specification: " + repr(spec))
}

#let _apply-keep(cells, keep) = {
  if keep == "all" {
    return cells
  }
  if keep == "unique" {
    if cells.len() != 1 {
      panic("expected 1 cell, found " + str(cells.len()))
    }
    return cells
  }
  if type(keep) == int {
    return (cells.at(keep),)
  }
  if type(keep) == array {
    return keep.map(i => cells.at(i))
  }
  panic("invalid keep value: " + repr(keep))
}

#let _cells-from-spec(spec, nb, count, name-path, cell-type, cell-header-pattern, keep-cell-header) = {
  if type(spec) == dictionary and "id" not in spec and "nbformat" in spec {
    panic("invalid literal cell, did you forget the `nb:` keyword while passing a notebook?")
  }
  if type(spec) == dictionary or (
     type(spec) == array and spec.all(x => type(x) == dictionary)) {
    // No need to read the notebook
    return _filter-type(ensure-array(spec), cell-type)
  }
  let all-cells = _read-notebook(nb, cell-header-pattern, keep-cell-header).cells
  let cells-of-type = _filter-type(all-cells, cell-type)
  if spec == none {
    // No spec means select all cells
    return cells-of-type
  }
  let indices = ()
  for s in ensure-array(spec) {
    indices += _cell-indices(s, cell-type, cells-of-type, all-cells, count, name-path)
  }
  return indices.dedup().sorted().map(i => all-cells.at(i))
}

/// Cell selector: return an array of cells according to the 'cell specification'
/// -> array
#let cells(
  ..args,
  nb: none,
  count: "index",
  name-path: auto,
  cell-type: "all",
  keep: "all",
  cell-header-pattern: auto,
  keep-cell-header: false,
) = {
  if args.named().len() > 0 {
    panic("invalid named arguments: " + repr(args.named()))
  }
  if args.pos().len() > 1 {
    panic("expected 1 positional argument, got " + str(args.pos().len()))
  }
  let spec = args.pos().at(0, default: none)
  let cs = _cells-from-spec(spec, nb, count, name-path, cell-type, cell-header-pattern, keep-cell-header)
  return _apply-keep(cs, keep)
}

#let cell(..args, keep: "unique") = cells(..args, keep: keep).first()

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

#let get-all-handlers(handlers) = {
  if handlers == auto {
    return default-handlers
  }
  if type(handlers) != dictionary {
    panic("handlers must be auto or a dictionary mapping formats to functions")
  }
  // Start with default handlers and add/overwrite with provided ones
  return default-handlers + handlers
}

// Interpret data according to the given MIME format string, using the given
// handlers dict for decoding.
#let read-mime(data, format: none, handlers: auto, ..args-handler) = {
  let all-handlers = get-all-handlers(handlers)
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

// Process a "rich" item, which can have various formats.
// Can return none if item is available only in unsupported formats (and
// ignore-wrong-format is true) or if the item is empty (data dict empty in
// notebook JSON).
#let process-rich(
  item-data,
  format: auto,
  handlers: auto,
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
  let recursive-handlers = if handlers == auto { (:) } else { handlers }
  if type(recursive-handlers) != dictionary {
    panic("handlers must be auto or a dictionary mapping formats to functions")
  }
  recursive-handlers.insert(
    "application/x.rich-object",
    process-rich.with(
      format: format,
      handlers: handlers,
      ignore-wrong-format: ignore-wrong-format,
    ),
  )
  let value = read-mime(item-data.at(fmt), format: fmt, handlers: recursive-handlers, ..args-handler)
  return (
    format: fmt,
    value: value,
  )
}
// Process-rich is the entry-point for all recursive handlers. If read-mime
// should be an entry point too, create a convenience function get-recursive-handlers
// here, which would create the recursive-handlers dict

/// Process rich items from the 'outputs' field in a notebook. These contain
/// additional (meta)data besides the rich item itself.
#let process-rich-output(item, ..args) = {
  let processed-rich = process-rich(item.data, ..args)
  if processed-rich == none {
    return none
  }
  return (
    type: item.output_type,
    // TODO: can also contain metadata NOT keyed to MIME type
    metadata: item.metadata.at(processed-rich.format, default: none),
    ..processed-rich,
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
  display_data: process-rich-output,
  execute_result: process-rich-output,
  stream: process-stream,
  error: process-error,
)

#let cell-output-dict(cell) = (
  index: cell.index,
  id: cell.id,
  metadata: cell.metadata,
  type: cell.cell_type,
) + if cell.cell_type == "code" {
  (execution-count: cell.execution_count)
}

/// Return either the 'value' key of dict or return the dict itself, with some
/// added cell data under key 'cell'. See cell-output-dict for the added data.
/// - cell (dict): A cell in json format
/// - result-spec (str): Choose output mode: "value" or "dict"
/// - dict (dict): Contains at least a 'value' key
/// -> any | (value: any, cell: dict)
#let final-output(cell, result-spec, dict) = {
  if result-spec == "value" {
    return dict.value
  }
  if result-spec == "dict" {
    dict.cell = cell-output-dict(cell)
    return dict
  }
  panic("invalid result specification: " + repr(result))
}

/// Extract outputs from cells specified by 'cell-args'.
/// Can return several outputs per cell.
/// - output-type (str | array): The output type(s) to include in the returned array.
///   The valid types are "display_data", "execute_result", "stream" and "error".
/// - format (str | array): The format, or order of preference of formats, to
///   choose in case of "rich" outputs.
/// - handlers (auto | dict): Handler functions for rendering various data formats
/// - ignore-wrong-format (bool): Whether outputs without supported format should be
///   silently ignored.
/// - stream (str | array): The kind(s) of streams to include in the returned array
/// - result (str): Use "value" to return just the outputs themselves, or "dict" to
///   return for each output a dict with fields 'value', 'cell', 'type' and additional
///   fields specific to each output type.
/// -> array of any | array of dict
#let outputs(
  ..cell-args,
  output-type: "all",
  format: default-formats,
  handlers: auto,
  ignore-wrong-format: false,
  stream: "all",
  result: "value",
) = {
  if output-type == "all" {
    output-type = all-output-types
  }
  let output-types = ensure-array(output-type)
  for typ in output-types {
    if typ not in all-output-types {
      panic("invalid output type: " + typ)
    }
  }
  let process-args = (
    format: format,
    handlers: handlers,
    ignore-wrong-format: ignore-wrong-format,
    stream: stream,
  )
  let cs = cells(..cell-args, cell-type: "code")
  let outs = ()
  for cell in cs {
    outs += cell.outputs
      .filter(x => x.output_type in output-types)
      .map(x => (processors.at(x.output_type))(x, ..process-args))
      .filter(x => x != none)
      .map(final-output.with(cell, result))
  }
  return outs
}

#let single-item(items, item: "unique") = {
  if items.len() == 0 {
    panic("No matching item found")
  }
  if item == "unique" {
    if items.len() != 1 {
      panic("expected 1 item, found " + str(items.len()))
    }
    item = 0
  }
  return items.at(item)
}

#let output(..args, item: "unique") = single-item(outputs(..args), item: item)

#let displays     = outputs.with(output-type: "display_data")
#let results      = outputs.with(output-type: "execute_result")
#let errors       = outputs.with(output-type: "error")
#let stream-items = outputs.with(output-type: "stream")

#let display     = output.with(output-type: "display_data")
#let result      = output.with(output-type: "execute_result")
#let error       = output.with(output-type: "error")
#let stream-item = output.with(output-type: "stream")

// Same as stream-items, but merges all streams (matching `stream`) of the same cell, and always returns an item (possibly with an empty string as value) for each selected cell (of code type).
#let streams(
  ..cell-args,
  output-type: "all",
  format: default-formats,
  handlers: auto,
  ignore-wrong-format: false,
  stream: "all",
  result: "value",
) = {
  let cs = cells(..cell-args, cell-type: "code")
  let outs = ()
  for cell in cs {
    // Start value
    let out = (
      type: "stream",
      name: stream,
      value: "",
    )
    // Append all stream items to value
    for item in outputs(cell, output-type: "stream", stream: stream, result: "value") {
      out.value += item
    }
    outs.push(final-output(cell, result, out))
  }
  return outs
}

#let stream(..args, item: "unique") = single-item(streams(..args), item: item)

#let _cell-lang(cell, lang, raw-lang) = (
  markdown: "markdown",
  raw: raw-lang,
  code: lang,
).at(cell.cell_type)

/// Extract the 'source' field from cells as raw blocks.
/// Return type depends on the 'result' parameter.
/// - result (str): Determine the return type of the array↓ (See also the final-output function)
/// -> array of raw | (value: raw, cell: dict)
#let sources(
  ..args,
  nb: none,
  cell-header-pattern: auto,
  keep-cell-header: false,
  result: "value",
  lang: auto,
  raw-lang: none,
) = {
  if lang == auto {
    if nb == none {
      lang = none
    } else {
      lang = _notebook-lang(_read-notebook(nb, cell-header-pattern, keep-cell-header))
    }
  }
  let cs = cells(..args, nb: nb, cell-header-pattern: cell-header-pattern, keep-cell-header: keep-cell-header)
  let srcs = ()
  for cell in cs {
    let cell-lang = _cell-lang(cell, lang, raw-lang)
    let value = raw(cell.source, lang: cell-lang, block: true)
    srcs.push(final-output(cell, result, (value: value)))
  }
  return srcs
}

#let source(..args, item: "unique") = single-item(sources(..args), item: item)
