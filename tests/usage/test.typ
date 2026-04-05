#import "/callisto.typ"

// Render whole notebook
#callisto.render(nb: json("../../docs/example.ipynb"))

// Render code cells named/tagged with "plots", showing only the cell output
#callisto.render(
   "plots",
   nb: json("../../docs/example.ipynb"),
   cell-type: "code",
   input: false,
)

// Get functions preconfigured to use this notebook
#let (render, Cell, In, Out) = callisto.config(
   nb: json("../../docs/example.ipynb"),
)

// Render the first 4 cells using the "neat" theme
#render(range(4), theme: "neat")

// Render cell with execution number 4.
// Compared to `render`, `Cell` checks there's only one match.
// (It could make sense to set count: "execution" globally with config().)
#Cell(4, count: "execution")

// Render separately the input and output of cell "plot2"
// The cell defines its label "plot2" in a header at the top of the cell:
// the first source line is `#| label: plot2`
#In("plot2")
#Out("plot2")

// Get more functions preconfigured for this notebook
#let (output, outputs, result, source) = callisto.config(
   nb: json("../../docs/example.ipynb"),
)

// Get the single output of cell with label "calc"
#output("calc")

// This doesn't work: "plot2" has two outputs!
// #output("plot2")

// Get first and last output of "plot2"
#output("plot2", item: 0)
#output("plot2", item: -1)

// Get all outputs as an array
#outputs("plot2")

// Get the "plot2" output that is the cell result
#result("plot2")

// This doesn't work: cell "plot1" produces a display item but no result!
// #result("plot1")

// Get the source of cell "plot1" as raw block
#source("plot1")

// Change the width of an image read from the notebook
#{
   set image(width: 100%)
   output("plot1")
}
