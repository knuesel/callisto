#import "../common.typ": handle
#import "../reading.typ": outputs

// Plain template for raw cell
#let raw(cell, ctx: none) = {
  handle(cell.source, mime: "text/x.source-raw-cell", ctx: ctx)
}

// Plain template for Markdown cell
#let markdown(cell, ctx: none) = {
  // Render as inline Markdown to integrate seamlessly in the document
  // without interference from a block container (see
  // https://github.com/knuesel/callisto/issues/13) but add parbreaks
  // to render the content as a distinct unit.
  parbreak()
  handle(cell.source, mime: "text/x.markdown-inline", ctx: ctx)
  parbreak()
}

// Plain template for code cell input
#let input(cell, ctx: none) = {
  handle(cell.source, mime: "text/x.source-code-cell", ctx: ctx)
}

// Plain template for code cell output
#let output(cell, ctx: none) = {
  // Get outputs with user config, but override 'result' to get just the values
  outputs(cell, ..ctx.cfg, result: "value").join()
}

#let cell-template =(
  raw: raw,
  markdown: markdown,
  input: input,
  output: output,
)

#let doc-template(x) = x
