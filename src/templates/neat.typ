#import "../common.typ": handle
#import "../reading.typ": outputs

#let _fill = rgb(233, 236, 239)
#let _inset = 8pt
#let _radius = 5pt
#let _extent = 3pt

#let _raw-block-cfg = (
  width: 100%,
  inset: _inset,
  radius: _radius,
  fill: _fill,
)

// Document template
#let doc-template(doc) = {
  set text(font: "Noto Sans")
  show raw: set text(font: "Noto Sans Mono")
  show heading: set text(weight: "semibold")
  show heading: set block(below: 1em)
  show heading.where(level: 1): set text(1.4em)
  show heading.where(level: 2): set text(1.2em)

  show raw.where(block: false): it => {
    let cfg = (fill: _fill, top-edge: 1em, bottom-edge: -0.4em)
    highlight(..cfg, radius: (left: _radius))[~#sym.wj]
    highlight(..cfg, extent: _extent, it)
    highlight(..cfg, radius: (right: _radius))[#sym.wj~]
  }

  show raw.where(block: true): set block(.._raw-block-cfg)

  show math.equation: set text(1.1em)

  doc
}

// Neat template for raw cell
#let raw-cell(cell, ctx: none) = {
  handle(cell.source, mime: "text/x.source-raw-cell", ctx: ctx)
}

// Neat template for Markdown cell
#let markdown-cell(cell, ctx: none) = {
  // Render as inline Markdown to integrate seamlessly in the document
  // without interference from a block container (see
  // https://github.com/knuesel/callisto/issues/13) but add parbreaks
  // to render the content as a distinct unit.
  parbreak()
  handle(cell.source, mime: "text/x.markdown-inline", ctx: ctx)
  parbreak()
}

// Neat template for code cell input
#let code-input(cell, ctx: none) = {
  let has-output = ctx.cfg.output and cell.outputs.len() > 0
  set text(rgb("#005979"))
  show raw: set block(.._raw-block-cfg, above: 1em)
  show raw: set block(below: 1em) if not has-output
  handle(cell.source, mime: "text/x.source-code-cell", ctx: ctx)
}

// Neat template for code cell input
#let code-output(cell, ctx: none) = {
  let outs = outputs(cell, ..ctx.cfg, result: "value")
  if outs.len() == 0 { return }
  // Undo global show rule for raw block
  show raw: set block(width: auto, inset: 0pt, radius: 0pt, fill: none)
  block(
    .._raw-block-cfg,
    fill: none,
    above: if ctx.cfg.input { 0pt } else { 1em },
    below: 1em,
    outs.join(),
  )
}

#let cell-template =(
  raw: raw-cell,
  markdown: markdown-cell,
  input: code-input,
  output: code-output,
)
