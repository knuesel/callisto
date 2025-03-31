#import "callisto.typ": *
#import "input.typ": pick-format

#pick-format(("xyz", "text/plain", "abc"))

#pick-format(
  ("xyz", "text/plain", "abc"),
  precedence: ("gif", "abc", "text/plain", "xml"),
)

#let (cells, cell, source) = config(nb: "examples/python.ipynb")

#cells(type: "markdown")

#cell(4)

#cell("288d448a-380a-4fdd-a907-f5b149f87456")

#source(0)


#let (outputs, displays, display, results, result, error, streams, stream) = config(nb: "examples/cairomakie.ipynb")

#displays().join()

#display("plots", name: "metadata.name", item: 1)

// Must fail with nice error messages
// #display("plots", name: "metadata.name", format: "x")
// #display("plots", name: "metadata.name", format: "x", ignore-wrong-format: true)

#results().join()

#result("plots", name: "metadata.name")

#result("plots", name: "metadata.name", output: "dict")

#error(4)

#streams()

#stream(4, output: "dict")

#result(6)

#result(5, handlers: ("text/plain": repr))
