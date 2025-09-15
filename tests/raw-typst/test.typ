#import "/callisto.typ" as callisto: *

// Render raw cells as Typst markup
#let render = callisto.render.with(
  nb: json("raw-typst.ipynb"),
  handlers: (
    raw-cell: (cell, ..args) => eval(cell.source, mode: "markup"),
  ),
)

#render()
