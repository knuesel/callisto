#import "/callisto.typ"

== Render

#[
]

== Extract

#[
#let (source, display, result, output, outputs) = callisto.config(
   nb: path("/docs/example.ipynb"),
)

#source("plot1")
#source("plot1").text.contains("matplotlib")
#source(0)
#output("plot1")
// Doesn't work
// #result("plot1")
#display("plot1")
#display("plot2")
#result("plot2")
#output("calc")
#output("plot1")
// #output("plot2")
#output("plot2", item: 0) // first item
#output("plot2", item: 1) // second item
#outputs("plot2")
#let last-output = output.with(
  output-type: ("display", "result"),
  item: -1,
)
#[
  #set image(width: 75%)
  #set align(center)
  #output("plot1")
]
#let img-data = output("plot1").source
#let img = image(img-data, width: 75%)
#align(center, img)
#output("plot1", format: "image/png")
#output("plot1", format: ("image/png", "image/svg+xml"))
#output("plot1", format: ("image/png", auto))

#output("typst-markup")

#output("json-result", format: "application/json")
#let (output,) = callisto.config(
  nb: path("/docs/example.ipynb"),
  format: ("application/json", auto),
)

#output("json-result")
]

== Export

#[
#let (output, export, execute, evaluate, stage-notebook, Out) = callisto.config(
  nb: path("export.ipynb"),
  kernel: "python3",
)
#stage-notebook()

#export(
  ```
  #| label: pandas-setup
  import pandas as pd
  pd.options.display.float_format = '{:.2f}'.format
  ```
)

The square of 3 is #evaluate(`3+3`).

The square of 3 is #evaluate(`3+3`, cell-header: (label: "square")).

Recall that the square of 3 is #output("square").

#show raw.where(lang: "py-x"): it => {
  set text(1em/0.8)
  execute(it)
}

```py-x
import random
random.randint(0, 6)
```

Executed block, rendering only the output:
```py-x
#| echo: false
2 + 3
```

Executed block, rendering only the source:
```py-x
#| label: calc
#| output: false
2 + 3
```

Showing the output here:
#Out("calc")

#show <exec>: execute

```python
2 + 3
```<exec>

```python
2 + 4
```<exec>


#show <x>: evaluate

The square of 3 is `3*3`<x>.

// Make table with n columns holding numbers 0 to n-1
#let my-table(n) = table(columns: n, ..range(n).map(str))

// Configure output function for example.ipynb, and name it output-ex
#let (output: output-ex,) = callisto.config(nb: path("/docs/example.ipynb"))

// Use output of "calc" cell for the number of columns
#my-table(int(output-ex("calc")))


#evaluate(`2+3`, transform: x => my-table(int(x)))
]
