#import "../common.typ": single-item, final-result, ensure-array, parse-main-args
#import "../ctx.typ": get-ctx
#import "notebook.typ"
#import "cell.typ": cells
#import "rich-object.typ"
#import "stream.typ"
#import "error.typ"

#let all-output-types = ("display_data", "execute_result", "stream", "error")
#let rich-output-types = ("display_data", "execute_result")

// The module that implements 'preprocess' and 'process' for each output type
#let processor-modules = (
  display_data: rich-object,
  execute_result: rich-object,
  stream: stream,
  error: error,
)

// Resolve 'output-type' setting to a list of desired output types
#let _output-types(types) = {
  if types == "all" { return all-output-types }
  let types = ensure-array(types)
  for typ in types {
    if typ not in all-output-types {
      panic("invalid output type: " + repr(typ))
    }
  }
  return types
}

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
#let outputs(..args) = {
  let (cell-spec, cfg) = parse-main-args(args)
  let output-types = _output-types(cfg.output-type)
  let outs = ()
  for cell in cells(..args, cell-type: "code") {
    for (i, item) in cell.outputs.enumerate() {
      // Ignore items with undesired output type
      if item.output_type not in output-types { continue }
      // Make context for processor
      let item-desc = (index: i, type: item.output_type)
      let ctx = get-ctx(cell, cfg: cfg, item: item-desc)
      // Get processor module
      let proc-module = processor-modules.at(item.output_type)
      // Get dict with normalized data for this item
      let preprocessed = proc-module.preprocess(item, ctx: ctx)
      if preprocessed == none { continue }
      // Get processed value
      let value = proc-module.process(preprocessed, ctx: ctx)
      if value == none { continue }
      // Make final result (value or dict)
      let result = final-result(preprocessed, value, ctx: ctx)
      outs.push(result)
    }
  }
  return outs
}

// Return a single output
#let output(..args, item: "unique") = single-item(outputs(..args), item: item)
