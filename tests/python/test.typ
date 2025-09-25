#import "/callisto.typ"

#let (
  render,
  source,
  Cell,
) = callisto.config(nb: "/tests/python/python.ipynb")

= Python notebook

#render()

#pagebreak()

== `neat` theme

#v(1em)
#[
  #let (render, template) = callisto.config(
    nb: json("python.ipynb"),
    theme: "neat",
  )
  #show: template
  #render(theme: "neat")
]

#pagebreak()

== `plain` theme, styled raw blocks

#[
  #show raw.where(block: true, lang: "python"): set block(
    inset: (left: 1.2em, y: 1em),
    stroke: (left: 3pt+luma(96%)),
  )
  #render(theme: "plain")
]
#pagebreak()

== Custom theme for `code` cells

#render(theme: (
  code-cell: (c, ..args) => block(inset: (left: 1em), spacing: 2em)[
    [cell #c.index]
    #raw(block: true, c.source)
  ],
))

#pagebreak()

== Source of cell 4
#source(4)

== Rendering of cell 4
#Cell(4)

== Accessing metadata from image handler
#render(
  6,
  output-type: "display",
  handlers: (
    "image/png": (data, ctx: none, ..args) => {
      block[PNG display has metadata: #ctx.item.metadata]
    },
  ),
)

// == `neat` theme with stderr from notebook

// // #render(4, theme: "neat", handlers: (stream-stderr: "notebook"))
// #render(4, theme: callisto.themes.named.neat + (stream-stderr: "notebook"))
