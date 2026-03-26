#import "/lib/config.typ"
#import "/lib/ctx/ctx.typ"
#import "common.typ": final-result
#import "cell.typ": cells

// Return the lang of the cell's source
#let _cell-lang(cell, ctx: none) = (
  markdown: "markdown",
  raw: ctx.raw-lang,
  code: ctx.lang,
).at(cell.cell_type)

/// Extract the 'source' field from cells as raw blocks.
/// Return type depends on the 'result' parameter.
/// - result (str): Use "value" to return just the raw items, or "dict" to
///   return for each matching cell a dict with fields 'cell' and 'value'.
/// -> array of any | array of dict
#let sources(..args) = {
  let (cell-spec, cfg) = config.parse-main-args(..args)
  if config.read-enabled(cfg: cfg) == false { return none }
  let srcs = ()
  for cell in cells(..args) {
    let ctx = ctx.get-ctx(cell, cfg: cfg)
    let cell-lang = _cell-lang(cell, ctx: ctx)
    let value = raw(cell.source, lang: cell-lang, block: true)
    srcs.push(final-result((text: cell.source), value, ctx: ctx))
  }
  return srcs
}
