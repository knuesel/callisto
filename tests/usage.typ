#import "/src/callisto.typ"

// Render whole notebook
#callisto.render(nb: json("../docs/example.ipynb"))

// Render code cells named/tagged with "plots", showing only the cell output
#callisto.render(
   "plots",
   nb: json("../docs/example.ipynb"),
   cell-type: "code",
   input: false,
)

// Get functions preconfigured to use this notebook
#let (render, Cell, In, Out) = callisto.config(
   nb: json("../docs/example.ipynb"),
)

// Render the first 3 cells using the plain template
#render(range(3), template: "plain")

// Render only cell among the first two that is of type "code"
#Cell(range(2), cell-type: "code")

// Render cell with execution number 4.
// Compared to `render`, `Cell` checks there's only one match.
// (It could make sense to set `count` globally with `config()`.)
#Cell(4, count: "execution")

// Render separately the input and output of cell "plot2"
// The cell defines its label "plot2" in a header at the top of the cell:
// #| label: plot2
#In("plot2")
#Out("plot2")

// Use notebook template for code inputs, custom template for markdown cells
#let repr-template(cell, ..args) = repr(cell.source)
#render(template: (input: "notebook", markdown: repr-template))

// Get more functions preconfigured for this notebook
#let (display, result, source, output, outputs) = callisto.config(
   nb: json("../docs/example.ipynb"),
)

// Get the result of cell with label "some-code"
#result("some-code")

// Get the source of cell "plot1" as raw block
#source("plot1")

// This doesn't work: cell "plot1" produces a display but no result!
// #result("plot1")

// Get the display output of that cell
#display("plot1")

// Force using the PNG version of this output
#display("plot1", format: "image/png")

// Get the output (display or result, we don't care) of some cells
#output("some-code")
#output("plot1")

// This doesn't work: "plot2" has two outputs!
// #output("plot2")

// Get first and last output of "plot2"
#output("plot2", item: 0)
#output("plot2", item: -1)

// Get all outputs as an array
#outputs("plot2")

// Change the width of an image read from the notebook
#{
   set image(width: 100%)
   output("plot1")
}

// Another way to do the same thing
#image(output("plot1").source, width: 100%)
