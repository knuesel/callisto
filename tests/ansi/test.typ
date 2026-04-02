#import "/callisto.typ"

#set page(margin: 2cm)
#set heading(numbering: "1.")
#let esc = "\u{1b}"


= Test strings

#[
  #show raw.where(lang: "ansi"): it => callisto.ansi.render(
    it.text,
    conceal: (it, ..args) => text(rgb(0, 0, 0, 50), it),
    bold-is-bright: true,
    bg: white,
  )

  // Big mix
  #raw(lang: "ansi",
    esc + "[32;1m Green bold " +
    esc + "[38;2;255;128;0;44m TrueColor on blue " + 
    esc + "[2J" + // ignored cursor wipe
    esc + "[39m Default fg " + 
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

  // Dimming, concealed text and overline
  #raw(lang: "ansi",
    esc + "[34;2m Dim blue " +
    esc + "[22m Normal " +
    esc + "[53m Over " +
    esc + "[4m Under " +
    esc + "[9m Strike " +
    esc + "[24;29;55m Default " +
    esc + "[39;m| Password: [" + esc + "[8mSecret123" + esc + "[28m] | " +
    esc + "[0m Reset"
  )
]

== Using `ansi.console-block`

#rect(stroke: red, inset: 0pt,
callisto.ansi.console-block(
  fg: white,
  bg: luma(30%),
  "Hello " + esc + "[33;7mWorld!\n" + "Still reversed" + esc + "[0m Reset",
))

= `ansi-table.ipynb`

// The text color when colors are reversed will be wrong here as the background
// cannot be guessed.

#let (render,) = callisto.config(
  nb: json("ansi-table.ipynb"),
  ansi: (bg: white),
)
#render()

== Custom fg/bg and Gruvbox palette

#let gruvbox = (
  rgb("#282828"), rgb("#cc241d"), rgb("#98971a"), rgb("#d79921"),
  rgb("#458588"), rgb("#b16286"), rgb("#689d6a"), rgb("#a89984"),
  rgb("#928374"), rgb("#fb4934"), rgb("#b8bb26"), rgb("#fabd2f"),
  rgb("#83a598"), rgb("#d3869b"), rgb("#8ec07c"), rgb("#ebdbb2"),
)

// #show raw: set text(font: "DejaVu Sans Mono")
// #show raw: set text(font: "JuliaMono")
// #show raw: set text(font: "Noto Sans Mono")

#let (Out,) = callisto.config(
  nb: json("ansi-table.ipynb"),
  theme: "plain",
  ansi: (palette: gruvbox, bg: gruvbox.first(), fg: orange),
)
#Out(0)

#let (Out,) = callisto.config(
  nb: json("ansi-table.ipynb"),
  theme: "plain",
  ansi: (process: "strip"),
)
#Out(0)

#pagebreak()

= `errors.ipynb`

#callisto.render(
  nb: json("errors.ipynb"),
)
