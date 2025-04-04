#import "/src/callisto.typ"

#let nb = json("notebooks/julia.ipynb")

// Use notebook template for code cells, custom template for markdown cells
// We use the render function that had the notebook preconfigured above
#let markdown-template(cell, ..args) = repr(cell.source)
#callisto.render(
  nb: nb,
  template: (input: "notebook", markdown: markdown-template),
)

#pagebreak()

// Render notebook with plain template, using the matching document template
#let (template, render) = callisto.config(nb: nb, template: "plain")

#show: template
#render()
