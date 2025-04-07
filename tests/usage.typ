#import "/src/callisto.typ"

// Render whole notebook
#callisto.render(nb: json("notebooks/julia.ipynb"))

// Render code cells named/tagged with "plots", showing only the cell output
#callisto.render(
   "plots",
   nb: json("notebooks/julia.ipynb"),
   cell-type: "code",
   input: false,
)

// Let's get functions preconfigured to use this notebook
#let (render, result, source) = callisto.config(
   nb: json("notebooks/julia.ipynb"),
)

// Render only the first 3 cells using the plain template
#render(range(3), template: "plain")

// Get the source of that cell as a raw block, then get the text of it
#source("plot1").text

// Get the result of cell with label "plot1"
#result("plot1")

// Force using the PNG version of this output
#result("plot1", format: "image/png")

// This doesn't work: cell "plot2" produces a display but no result!
// #result("plot2")

// We need `display` or `output` to get a display
#let (display, output, outputs) = callisto.config(
   nb: json("notebooks/julia.ipynb"),
)

// "plot2" makes two displays, we can choose one
#display("plot2")

// This doesn't work: cell "plot3" produces several displays!
// #display("plot3")

// We must choose one (or use `displays` to get an array of displays)
#display("plot3", item: 0)

// Output returns any kind of output (display, result, error, stream)
#output("plot3", item: -1) // get last item

// Cell 4 has two outputs: a stream and an error, let's get the stream
#output(4, output-type: "stream")

// Or we can use `outputs` to get all outputs as an array
#outputs(4, result: "dict") // get each result as a dict

// Change the width of an image read from the notebook
#{
   set image(width: 100%)
   result("plot1")
}

// Another way to do the same thing
#image(result("plot1").source, width: 100%)

// Functions to render a single cell (raise an error if several cells match)
#let (Cell, In, Out) = callisto.config(nb: json("notebooks/julia.ipynb"))

// Render cell with execution number 4 (count can also be set by config())
#Cell(4, count: "execution")

// Render separately the input and output of cell "plot1"
#In("plot1")
#Out("plot1")

// Use notebook template for code inputs, custom template for markdown cells
#let my-template(cell, ..args) = repr(cell.source)
#render(template: (input: "notebook", markdown: my-template))
