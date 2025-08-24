#import "common.typ": single-item, final-result, ensure-array
#import "notebook.typ"
#import "cell.typ": cells
#import "rich-object.typ"
#import "../handlers.typ": get-all-handlers

#let all-output-types = ("display_data", "execute_result", "stream", "error")

// Process a rich item, i.e. an item that can be available in multiple formats.
// Can return none if item is available only in unsupported formats (and
// ignore-wrong-format is true) or if the item is empty (data dict empty in
// notebook JSON).
#let process-rich(item, ..args) = {
  let result = rich-object.process(item.data, item.metadata, ..args)
  if result == none {
    return none
  }
  return (
    type: item.output_type,
    ..result,
  )
}

// Process a stream item.
// Can return none if the item is from an undesired stream (cf 'stream' arg.)
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

/// Extract outputs from cells specified by 'cell-args'.
/// Can return several outputs per cell.
/// - output-type (str | array): Output type(s) to include in returned array.
///   Valid types are "display_data", "execute_result", "stream" and "error".
/// - format (str | array): The format, or order of preference of formats, to
///   choose in case of "rich" outputs.
/// - handlers (auto | dict): Handler functions for rendering various formats
/// - ignore-wrong-format (bool): Whether outputs without supported format
///   should be silently ignored.
/// - stream (str | array): Kind(s) of streams to include in the returned array
/// - result (str): Use "value" to return just the outputs themselves, or
///   "dict" to return for each output a dict with fields 'value', 'cell',
///   'type' and additional fields specific to each output type.
/// -> array of any | array of dict
#let outputs(
  nb: none,
  ..other-cell-args,
  output-type: "all",
  format: rich-object.default-formats,
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
    nb: nb,
    format: format,
    all-handlers: get-all-handlers(handlers),
    ignore-wrong-format: ignore-wrong-format,
    stream: stream,
  )
  let cs = cells(nb: nb, ..other-cell-args, cell-type: "code")
  let outs = ()
  for cell in cs {
    outs += cell.outputs
      .filter(x => x.output_type in output-types)
      .map(x => (processors.at(x.output_type))(
        x,
        cell: cell,
        ..process-args),
      )
      .filter(x => x != none)
      .map(final-result.with(cell, result))
  }
  return outs
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

// Same as stream-items, but merges all streams (matching 'stream') of the
// same cell, and always returns an item (possibly with an empty string as
// value) for each selected cell (of code type).
#let streams(
  ..cell-args,
  output-type: "all",
  format: rich-object.default-formats,
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
    for item in outputs(
      cell,
      output-type: "stream",
      stream: stream,
      result: "value",
    ) {
      out.value += item
    }
    outs.push(final-result(cell, result, out))
  }
  return outs
}

#let stream(..args, item: "unique") = single-item(streams(..args), item: item)
