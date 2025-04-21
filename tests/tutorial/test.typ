#import "/src/callisto.typ"

#let (render, Cell, In, Out) = callisto.config(nb: json("../../docs/example.ipynb"))
#render()
#render(template: "plain")
#block(stroke: red)[
   #render(0)
]
#render(1)
#render("plot3")
#render("plots")
#render(range(4))
#In("plot3")
#Out("plot3")
#Cell("plot3")
#let (source, display, result, output, outputs) = callisto.config(
   nb: json("../../docs/example.ipynb"),
)
#source(0)
#source("plot1")
// #result("plot1") // Doesn't work!
#display("plot1")
#display("plot2")
#result("plot2")
// #display("plot3") // Doesn't work!
#display("plot3", item: 0) // first display
#display("plot3", item: 1) // second display
#output("some-code") // returns the cell result
#output("plot1")     // returns the cell display
#outputs("plot2")
#let my-output = output.with(
  output-type: ("display_data", "execute_result"),
  item: -1
)
#my-output("plot2")
#[
  #set image(width: 75%)
  #align(center, output("plot1"))
]
#let img-data = output("plot1").source
#let img = image(img-data, width: 75%)
#align(center, img)
#output("plot1", format: "image/png")
#output("plot1", format: ("image/png", "image/svg+xml"))
#output("plot1", format: ("image/png", auto))
#output(2, count: "execution")
#let (render, result) = callisto.config(
   nb: json("../../docs/example.ipynb"),
   count: "execution",
)
#render(2)
