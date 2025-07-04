#import "/src/callisto.typ"

#let (
  Cell,
  In,
  Out,
  render,
  display,
  results,
  result,
  errors,
  error,
) = callisto.config(nb: "/tests/julia/julia.ipynb")

= Julia notebook

== Cell 2
#Cell(2)

=== Rendered input
#In(2, template: "plain")

=== Rendered output (framed)
#block(stroke: 1pt, Out(2))

== Cell with execution count = 3

=== Rendered error
#Out(3, count: "execution", output-type: "error")

=== Same but with `plain` template
#Out(3, count: "execution", output-type: "error", template: "plain")

#pagebreak()

== Markdown and code cells\ (only source and result, no display)
#render(
  cell-type: ("markdown", "code"),
  output-type: "execute_result",
)

#pagebreak()

== All cell results
#results().join()

== Markdown display, shown with custom handler (`repr`)
#display(format: "text/markdown", ignore-wrong-format: true, handlers: (
  "text/markdown": (data, ..args) => repr(data),
))
