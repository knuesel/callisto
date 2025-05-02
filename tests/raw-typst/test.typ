#import "/src/callisto.typ" as callisto: *

// Render raw cells as Typst markup
#let render = callisto.render.with(
  nb: json("raw-typst.ipynb"),
  template: (
    code: "notebook",
    markdown: "notebook",
    raw: (cell, ..args) => eval(cell.source, mode: "markup"),
  ),
)

#render()
