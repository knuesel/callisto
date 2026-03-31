#import "/callisto.typ"
#import "/lib/ansi.typ"

#set heading(numbering: "1.")

= Test strings

#show raw.where(lang: "ansi"): it => ansi.render(
  it.text,
  conceal: (it, ..args) => text(rgb(0, 0, 0, 50), it),
  bold-is-bright: true,
  bg: white,
)

#let esc = "\u{1b}"

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
  esc + "[53m Overline " +
  esc + "[4m Underline " +
  esc + "[9m Strike " +
  esc + "[24;29;55m Default " +
  esc + "[39;m| Password: [" + esc + "[8mSecret123" + esc + "[28m] | " +
  esc + "[0m Reset"
)

= `ansi-table.ipynb`

#let (render,) = callisto.config(
  nb: json("ansi-table.ipynb"),
)
#render()

== Custom foreground and background colors and Gruvbox palette


#let gruvbox = (
  rgb("#282828"), rgb("#cc241d"), rgb("#98971a"), rgb("#d79921"),
  rgb("#458588"), rgb("#b16286"), rgb("#689d6a"), rgb("#a89984"),
  rgb("#928374"), rgb("#fb4934"), rgb("#b8bb26"), rgb("#fabd2f"),
  rgb("#83a598"), rgb("#d3869b"), rgb("#8ec07c"), rgb("#ebdbb2"),
)

#let (Out,) = callisto.config(
  nb: json("ansi-table.ipynb"),
  theme: "plain",
  handlers: (
    "text-ansi-generic": (data, ..args) => ansi.render(
      data,
      palette: gruvbox,
      fg: yellow,
      bg: eastern.darken(70%),
    ),
  )
)
#Out(0)

#pagebreak()

= `errors.ipynb`

#callisto.render(
  nb: json("errors.ipynb"),
)
