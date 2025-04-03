#import "/src/callisto.typ": *
#import reading: pick-format

== Function `pick-format`
=== Preferred format among `xyz`, `text/plain`, `abc`
#pick-format(("xyz", "text/plain", "abc"))

=== Same with `precedence: ("abc", "text/plain")`
#pick-format(
  ("xyz", "text/plain", "abc"),
  precedence: ("abc", "text/plain"),
)

== Using `python.ipynb`

#let (cells, cell, source, Cell, streams, stream-item, stream-items) = config(
  nb: "/tests/notebooks/python.ipynb",
)

=== All markdown cells
#cells(cell-type: "markdown")

=== Position of cell with id `"288d448a-380a-4fdd-a907-f5b149f87456"`
#cell("288d448a-380a-4fdd-a907-f5b149f87456").position

=== Merged stream for each code cell, with cell position
#streams(result: "dict").map(x => (cell: x.cell.position, value: x.value))

=== Source of cell 5
#source(5)

=== Rendering of cell 5
#Cell(5)

=== Stream names of stream items of cell 5
#stream-items(5, result: "dict").map(x => x.name)

=== Last stderr item of cell 5
#stream-item(5, stream: "stderr", item: -1)

== Using `julia.ipynb`

#let (display, results, result, errors) = config(
  nb: "/tests/notebooks/julia.ipynb",
)

=== Cell with label `"plot1"`
#display("plot1", item: 0)

=== Cell with `"scatter"` type (custom metadata)
#display("scatter", name-path: "metadata.type", item: 1)

// Must fail with nice error messages
// #display("plots", name-path: "metadata.name", format: "x")
// #display("plots", name-path: "metadata.name", format: "x", ignore-wrong-format: true)

=== All cell results
#results().join()

=== Result of cell matching `"plot1"`
#result("plot1")

=== Results of cells with execution count over 3
#results(c => c.execution_count > 3)

=== The only Markdown display, shown using a custom handler (`repr`)
#display(format: "text/markdown", ignore-wrong-format: true, handlers: (
  "text/markdown": repr,
))

=== First error in the notebook, in dict form
#errors(result: "dict").first()

