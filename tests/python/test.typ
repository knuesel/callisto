#import "/src/callisto.typ"

#let (
  render,
  source,
  Cell,
) = callisto.config(nb: "/tests/python/python.ipynb")

= Python notebook

#render(nb: json("python.ipynb"))

#pagebreak()

== `plain` template, styled raw blocks

#[
  #show raw.where(block: true, lang: "python"): set block(
    inset: (left: 1.2em, y: 1em),
    stroke: (left: 3pt+luma(96%)),
  )
  #render(template: "plain")
]
#pagebreak()

== Custom template for `code` cells

#render(template: (
  code: (c, ..args) => block(inset: (left: 1em), spacing: 2em)[
    [cell #c.index]
    #raw(block: true, c.source)
  ],
  markdown: "plain",
  raw: none,
))

#pagebreak()

== Source of cell 4
#source(4)

== Rendering of cell 4
#Cell(4)


