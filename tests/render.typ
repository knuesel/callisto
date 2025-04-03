#import "/src/callisto.typ" as callisto: *

= Julia notebook
#let (Cell, In, Out) = callisto.config(
  nb: "/tests/notebooks/julia.ipynb",
)

== Cell 2
#Cell(2)

=== Rendered input
#In(2, template: "plain")

=== Rendered output (framed)
#block(stroke: 1pt, Out(2))

==  Cell with execution count = 3

=== Rendered error
#Out(3, count: "execution", output-type: "error")

=== Same but with `plain` template
#Out(3, count: "execution", output-type: "error", template: "plain")

#pagebreak()

= Julia notebook: Markdown and code cells (only results)
#render(
  nb: "/tests/notebooks/julia.ipynb",
  cell-type: ("markdown", "code"),
  output-type: "execute_result",
)
#pagebreak()

= Python notebook
#render(nb: "/tests/notebooks/python.ipynb")

#pagebreak()

= Python notebook with `plain` template and doc template

#let (template, render) = callisto.config(
  nb: "/tests/notebooks/python.ipynb",
  template: "plain",
)
#render()


