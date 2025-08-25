#import "../common.typ": single-item, final-result, ensure-array, parse-main-args
#import "../ctx.typ": get-ctx
#import "notebook.typ"
#import "cell.typ": cells
#import "rich-object.typ"
#import "stream.typ"
#import "error.typ"

#let all-output-types = ("display_data", "execute_result", "stream", "error")

#let processors = (
  display_data: rich-object.process-output,
  execute_result: rich-object.process-output,
  stream: stream.process-output,
  error: error.process-output,
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
    let ctx = get-ctx(cell, cfg: cfg)
    // TODO: keep track of output item index and add it in ctx and result dict
    // (good for error messages and for handler flexibility
    outs += cell.outputs
      .filter(x => x.output_type in output-types)
      .map(x => processors.at(x.output_type)(x, ctx: ctx))
      .filter(x => x != none)
      .map(final-result.with(cell, cfg.result))
  }
  return outs
}

#let output(..args, item: "unique") = single-item(outputs(..args), item: item)
