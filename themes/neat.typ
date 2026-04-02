#import "plain.typ"
#import "/lib/util.typ": handle
#import "/lib/reading/output.typ": outputs

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
#let _template(doc, set-fonts: true) = {
  set text(font: "Noto Sans") if set-fonts
  show raw: set text(font: "Noto Sans Mono") if set-fonts
  show heading: set text(weight: "semibold") if set-fonts

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

#let _code-cell-input(cell, ctx: none) = {
  let has-output = ctx.output and cell.outputs.len() > 0
  set text(rgb("#005979"))
  show raw: set block(.._raw-block-cfg, above: 1em)
  show raw: set block(below: 1em) if not has-output
  handle(cell.source, mime: "source-code-generic", ctx: ctx, lang: ctx.lang)
}

#let _code-cell-output(cell, ctx: none) = {
  let outs = outputs(cell, ..ctx.cfg, result: "value")
  if outs.len() == 0 { return }
  // Undo global show rule for raw block
  // (we don't want simple text outputs to be shown in rounded gray rects)
  show raw: set block(width: auto, inset: 0pt, radius: 0pt, fill: none)
  block(
    .._raw-block-cfg,
    fill: none,
    above: if ctx.input { 0pt } else { 1em },
    below: 1em,
    outs.join(),
  )
}

#let theme = plain.theme + (
  template: _template,
  code-cell-input: _code-cell-input,
  code-cell-output: _code-cell-output,
)
