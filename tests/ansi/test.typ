#import "/callisto.typ"
#import "/lib/ansi.typ"

#show raw.where(lang: "ansi"): it => ansi.render(it.text)

#let esc = "\u{1b}"

// Big mix
#raw(lang: "ansi",
  esc + "[32m Green " +
  esc + "[38;2;255;128;0;44;1m TrueColor on blue " + 
  esc + "[2J" + // ignored cursor wipe
  esc + "[39m Default fg " + 
  esc + "[4m Underlined " + 
  esc + "[m Reset (empty m)\n" + 
  esc + "[38;5;199m 8-bit cube pink" +
  esc + "[38;5;6m 8-bit cyan" +
  esc + "[38;5;14m 8-bit bright cyan" +
  esc + "[38;5;240m 8-bit gray" +
  esc + "[0m Reset "
)

// 6-level nesting
#raw(lang: "ansi",
 esc + "[31m Level 1 " +
 esc + "[32m Level 2 " +
 esc + "[33m Level 3 " +
 esc + "[34m Level 4 " +
 esc + "[35m Level 5 " +
 esc + "[36m Level 6 " +
 esc + "[0m Normal"
)

// With fg/bg reverse
#raw(lang: "ansi",
  esc + "[31m Red text " +
  esc + "[7m Inverted red " +
  esc + "[34m Still Inverted but blue " +
  esc + "[27m Uninverted blue " +
  esc + "[0m Normal"
)

// #show raw: set text(font: "DejaVu Sans Mono")
// #show raw: set text(font: "Noto Sans Mono")
// #show raw: set text(font: "JuliaMono")

#let ansi-handler(elem, ..args) = {
  // Works well with DejaVu Sans Mono, JuliaMono, Noto Sans Mono
  set par(leading: 0pt)
  set text(top-edge: 1.1em, bottom-edge: 0pt)
  set highlight(top-edge: 0.9em, bottom-edge: -0.2em)

  show raw: it => ansi.render(
    it.text,
    default-bg: block.fill,
    default-fg: text.fill,
  )
  elem
}

#let (render, output) = callisto.config(
  nb: json("ansi-table.ipynb"),
  handlers: (
    "stream": (auto, ansi-handler),
  )
)

#render()
