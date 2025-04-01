#import "/src/callisto.typ": *
#import reading: pick-format

#pick-format(("xyz", "text/plain", "abc"))

#pick-format(
  ("xyz", "text/plain", "abc"),
  precedence: ("gif", "abc", "text/plain", "xml"),
)

#let (cells, cell, source, Cell) = config(nb: "/tests/notebooks/python.ipynb")

#cells(cell-type: "markdown")

#Cell(4)

#cell("288d448a-380a-4fdd-a907-f5b149f87456")

#source(0)


#let (outputs, displays, display, results, result, error, streams, stream) = config(nb: "/tests/notebooks/julia.ipynb")

#display("plot1", item: 0)

#display("plots", name: "metadata.name", item: 1)

// Must fail with nice error messages
// #display("plots", name: "metadata.name", format: "x")
// #display("plots", name: "metadata.name", format: "x", ignore-wrong-format: true)

#results().join()

#result("plots", name: "metadata.name")

#result("plots", name: "metadata.name", result: "dict")

#error(5)

#streams()

#stream(5, result: "dict")

#result(7)

#result(6, handlers: ("text/plain": repr))
