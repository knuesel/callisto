#import "../common.typ": single-item, final-result, parse-main-args, handle
#import "../ctx.typ": get-ctx
#import "cell.typ": cells
#import "notebook.typ"

#let _cell-source-mimes = (
  "markdown": "text/x.source-code-cell",
  "code": "text/x.source-code-cell",
  "raw": "text/x.source-raw-cell",
)

/// Extract the 'source' field from cells as raw blocks.
/// Return type depends on the 'result' parameter.
/// - result (str): Use "value" to return just the raw items, or "dict" to
///   return for each matching cell a dict with fields 'cell' and 'value'.
/// -> array of any | array of dict
#let sources(..args) = {
  let (cell-spec, cfg) = parse-main-args(args)
  let srcs = ()
  for cell in cells(..args) {
    let ctx = get-ctx(cell, cfg: cfg)
    let mime = _cell-source-mimes.at(cell.cell_type)
    let value = handle(cell.source, mime, ctx: ctx)
    srcs.push(final-result(cell, cfg.result, (value: value)))
  }
  return srcs
}

#let source(..args, item: "unique") = single-item(sources(..args), item: item)
