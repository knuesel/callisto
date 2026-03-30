#import "/callisto.typ"

#let (
  render,
  source,
  Cell,
) = callisto.config(nb: json("/tests/python/python.ipynb"))

= Python notebook

#render()

#pagebreak()

== `neat` theme with customization to show cell indices

#v(1em)
#[
  #let (render, template) = callisto.config(
    nb: json("python.ipynb"),
    theme: "neat",
  )
  #show: template
  #render(handlers: ("cell": (
    auto,
    (data, ctx: none, ..args) => {
      place(dx: -4em)[Cell #ctx.cell.index]
      data
    }
  )))
]

#pagebreak()


== `plain` theme, styled raw blocks

#[
  #show raw.where(block: true, lang: "python"): set block(
    inset: (left: 1.2em, y: 1em),
    stroke: (left: 3pt+luma(96%)),
  )
  #render(range(4), theme: "plain")
]

=== With Codly

#[
  #import "@preview/codly:1.3.0": *
  #import "@preview/codly-languages:0.1.1": *

  #show raw.where(block: true, lang: "python"): codly-init
  #codly(languages: codly-languages)
  #render(range(4), theme: "plain")
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
      block[PNG display has metadata: #ctx.item-desc.metadata]
    },
  ),
)

