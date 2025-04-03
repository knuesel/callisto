#import "/src/callisto.typ": *
#import reading: pick-format

== Function `pick-format`
#pick-format(("xyz", "text/plain", "abc"))

#pick-format(
  ("xyz", "text/plain", "abc"),
  precedence: ("gif", "abc", "text/plain", "xml"),
)

== Cell functions
#let (cells, cell, source, Cell) = config(nb: "/tests/notebooks/python.ipynb")

Markdown cells:
#cells(cell-type: "markdown")

Rendering 5th cell:
#Cell(4)

Cell by id:
#cell("288d448a-380a-4fdd-a907-f5b149f87456")

Source of first cell:
#source(0)


#let (display, results, result, errors) = config(nb: "/tests/notebooks/julia.ipynb")

== Output functions

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

=== The only Markdown display, shown using a custom `repr` handler
#display(format: "text/markdown", ignore-wrong-format: true, handlers: (
  "text/markdown": repr,
))

=== First error in the notebook, in dict form
#errors(result: "dict").first()

#let (streams, stream) = config(nb: "/tests/notebooks/python.ipynb")

=== Stream 
#streams()

=== Stream of cell 5 in dict form
#stream(5, result: "dict")

