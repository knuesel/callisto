#import "common.typ": single-item, final-result
#import "cell.typ": cells
#import "notebook.typ"

#let _cell-lang(cell, lang, raw-lang) = (
  markdown: "markdown",
  raw: raw-lang,
  code: lang,
).at(cell.cell_type)

/// Extract the 'source' field from cells as raw blocks.
/// Return type depends on the 'result' parameter.
/// - result (str): Use "value" to return just the raw items, or "dict" to
///   return for each matching cell a dict with fields 'cell' and 'value'.
/// -> array of any | array of dict
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
      lang = notebook.lang(notebook.read(nb, cell-header-pattern, keep-cell-header))
    }
  }
  let cs = cells(..args, nb: nb, cell-header-pattern: cell-header-pattern, keep-cell-header: keep-cell-header)
  let srcs = ()
  for cell in cs {
    let cell-lang = _cell-lang(cell, lang, raw-lang)
    let value = raw(cell.source, lang: cell-lang, block: true)
    srcs.push(final-result(cell, result, (value: value)))
  }
  return srcs
}

#let source(..args, item: "unique") = single-item(sources(..args), item: item)
