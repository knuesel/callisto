#import "/callisto.typ"

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
) = callisto.config(nb: json("/tests/julia/julia.ipynb"))

= Julia notebook

== Cell 2
#Cell(2)

=== Rendered input (plain style)
#In(2, style: "plain")

=== Rendered output (framed)
#block(stroke: 1pt, Out(2))

== Cell with execution count = 3

=== Rendered error
#Out(3, count: "execution", output-type: "error")

=== Same but with plain style
#Out(3, count: "execution", output-type: "error", style: "plain")

== Raw cells
#render(cell-type: "raw")

=== With plain style
#render(cell-type: "raw", style: "plain")

#pagebreak()

== Markdown cells and code results (no display)
#render(
  cell-type: ("markdown", "code"),
  output-type: "result",
  input: false,
)

#pagebreak()

== All cell results
#results().join()

== Markdown display, shown with custom handler (blue frame)
#let blue-frame(data, ..args) = block(data, stroke: blue, outset: 3pt)
#display(
  format: "text/markdown",
  ignore-wrong-format: true,
  handlers: ("text/markdown": (auto, blue-frame)),
)
