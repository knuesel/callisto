// Type pills
#let _stripe-fg = rgb(82%, 99%, 100%)
#let _stripe-bg = rgb(100%, 83%, 92%)
#let _stripe-width = 4pt
#let _tile-size = _stripe-width * 2 * calc.sqrt(2)
#let _stripes-tiling = tiling(size: (_tile-size, _tile-size), {
  place(block(width: 100%, height: 100%, fill: _stripe-bg))
  // Main diagonal
  place(line(start: (0%, 0%), end: (100%, 100%), stroke: _stripe-width + _stripe-fg))
  // Upper-right corner
  place(line(start: (50%, -50%), end: (150%, 50%), stroke: _stripe-width + _stripe-fg))
  // Bottom-left corner
  place(line(start: (-50%, 50%), end: (50%, 150%), stroke: _stripe-width + _stripe-fg))
})
#let _color-gradient = gradient.linear(
   rgb("#7cd5ff"),
   rgb("#a6fbca"),
   rgb("#fff37c"),
   rgb("#ffa49d"),
   angle: -7deg,
)
#let _time-gradient = gradient.linear(
  (rgb("ebf4f9"), 0%),
  (rgb("eff0ec"), 25%),
  (rgb("f4ebdd"), 45%),
  (rgb("f4e8d9"), 66%),
  (rgb("f5e7d8"), 75%),
  (rgb("dbd1ce"), 100%),
)
#let pill-backgrounds = (
  str:        rgb("#d1ffe2"),
  path:        rgb("#d1ffe2"),
  regex:      rgb("#d1ffe2"),
  symbol:     rgb("#d1ffe2"),
  array:      rgb("#fcdfff"),
  dictionary: rgb("#fcdfff"),
  bytes:      rgb("#fcdfff"),
  arguments:  rgb("#fcdfff"),
  version:    rgb("#fcdfff"),
  bool:       rgb("#ffecbf"),
  int:        rgb("#ffecbf"),
  float:      rgb("#ffecbf"),
  angle:      rgb("#ffecbf"),
  decimal:    rgb("#ffecbf"),
  ratio:      rgb("#ffecbf"),
  fraction:   rgb("#ffecbf"),
  length:     rgb("#ffecbf"),
  relative:   rgb("#ffecbf"),
  "auto":     rgb("#ffd2ca"),
  "none":     rgb("#ffd2ca"),
  direction:  rgb("#a6eaff"),
  alignment:  rgb("#a6eaff"),
  content:    rgb("#a6ebe6"),
  function:   rgb("#d1d4fd"),
  module:     rgb("#d1d4fd"),
  type:       rgb("#d1d4fd"),
  label:      rgb("#c6d6ec"),
  selector:   rgb("#c6d6ec"),
  location:   rgb("#c6d6ec"),
  counter:    rgb("#eff0f3"),
  state:      rgb("#eff0f3"),
  any:        rgb("#eff0f3"),
  color:      _color-gradient,
  datetime:   _time-gradient,
  duration:   _time-gradient,
  tiling:     _stripes-tiling,
)
#let _pill-extent = 3pt
#let _pill-box(name, bg) = box(
  fill: bg,
  inset: (x: _pill-extent),
  outset: (y: _pill-extent),
  radius: _pill-extent,
  // text(weight: "regular", raw(name, lang: "typst-pill"),
  raw(name, lang: "typst-pill"),
)
#let pills = for (name, bg) in pill-backgrounds {
  ((name): _pill-box(name, bg))
}

#let _main-text-size = 11pt
#let _terms-sep-space = h(0.7em, weak: true)

#let template(doc) = {
  set text(_main-text-size)

  let code-fill = luma(96%)

  show raw.where(lang: "typst-pill"): set text(font: "Cascadia Mono", size: 1em*14/15)

  let _radius = 5pt
  let inline-code = selector.or(
    raw.where(block: false, lang: "txt"),
    raw.where(block: false, lang: "typ"),
    raw.where(block: false, lang: "typc"),
  )
  show inline-code: it => {
    let cfg = (fill: code-fill, top-edge: 1em, bottom-edge: -0.4em)
    highlight(..cfg, radius: (left: _radius))[~#sym.wj]
    highlight(..cfg, it)
    highlight(..cfg, radius: (right: _radius))[#sym.wj~]
  }

  let code-block = selector.or(
    raw.where(block: true, lang: "txt"),
    raw.where(block: true, lang: "typ"),
    raw.where(block: true, lang: "typc"),
    raw.where(block: true, lang: "bash"),
    raw.where(block: true, lang: "py"),
    raw.where(block: true, lang: "Makefile"),
    raw.where(block: true, lang: "just"),
  )
  show code-block: set block(
    fill: code-fill,
    width: 100%,
    inset: 1em,
    radius: 0.5em,
    breakable: false,
  )

  // Remove underlines in Typst markup (under headlines)
  show raw.where(lang: "typ"): set underline(stroke: 0pt)

  set terms(
    hanging-indent: 0pt,
    separator: text(weight: "bold")[:] + _terms-sep-space,
    spacing: 1.2em,
  )
  // show terms: it => {
  //   show strong: s => text(weight: 400 + strong.delta, s.body)
  //   it
  // }

  show link: set text(blue)

  show selector.or(
    heading.where(level: 1),
    heading.where(level: 2),
    heading.where(level: 3),
  ): set heading(numbering: "1.")
  show heading.where(level: 1): set text(16pt)
  show heading.where(level: 2): set text(14pt)
  show heading.where(level: 3): set text(12pt)

  show selector.or(
    heading.where(level: 1),
    heading.where(level: 2),
    heading.where(level: 3),
  ): set block(below: 0.8em)

  set page(numbering: "1")
  set par(justify: true)

  show title: set text(22pt)
  show title: set par(spacing: 0.6em)
  show title: set block(below: 1em)

  show outline: it => {
    show heading: set heading(numbering: none)
    it
  }
  
  doc
}

#let doc-block(blk) = {
  let sel = raw.where(block: true)
  show sel: set par(leading: 0.9em)
  show sel: set text(font: "Cascadia Mono")
  show sel: set block(
    fill: none,
    stroke: luma(90%),
  )
  show sel: it => {
    show regex("[a-z]+-pill"): s => {
      // Undo text scaling by doc-block raw element
      set text(1em/0.8)
      pills.at(s.text.split("-").first())
    }
    show "yields": sym.arrow
    show "/": h(0.3em)
    it
  }
  blk
}

#let function-doc(it, content: none) = {
  show heading.where(level: 3): set heading(numbering: none)
  if content == none { content = it }
  [#heading(depth: 3, content)#label("function:" + it.text)]
}

#let setting-doc(name, pills, content: none) = {
  show heading.where(level: 3): set heading(numbering: none)
  if content == none { content = name }
  show heading: it => it.body
  block(
    above: 1.6em,
    sticky: true,
    {
      [#heading(depth: 3, content)#label("setting:" + name.text)]
      _terms-sep-space
      pills
    },
  )
}
#let example(it) = heading(depth: 3, [Example: ] + it)

#let _ref-link(it, kind: none, content: none) = link(
  label(kind + ":" + it.text),
  if content == none { raw(it.text) } else { content },
)
#let setting = _ref-link.with(kind: "setting")
#let func = _ref-link.with(kind: "function")
