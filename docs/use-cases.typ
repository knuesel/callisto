#set page(width: 110mm, height: auto, margin: 5mm)

#[
  #set page(margin: (left: 20mm))

  #import "@local/callisto:0.3.0"
  
  #set text(font: "Pennstander")
  #show math.equation: set text(font: "Pennstander Math")
  #set heading(numbering: "I.")
  
  #callisto.render(
   nb: path("example.ipynb"),
   (0, 1), // first two cells
  )
]

#counter(heading).update(0)

#[
 #import "@local/callisto:0.3.0"
 #set heading(numbering: "1.")
 
 = Introduction
 Some text.
 
 #callisto.render(
   nb: path("example.ipynb"),
   theme: "neat",
   cmarker: (h1-level: 2), // subsection
   (0, 1), // first two cells
 )
]

#pagebreak()

#[
  #import "@local/callisto:0.3.0"
  #let (source, output, errors) = callisto.config(
    nb: path("example.ipynb"),
  )

  The source of the "plot1" cell:
  #source("plot1", keep-cell-header: true)

  And its output:
  #output("plot1")

  #if errors().len() > 0 [
    There are errors in this notebook...
  ]
]

#pagebreak()

#[
  #import "@local/callisto:0.3.0"
  #let (output, execute, evaluate, stage-notebook) = callisto.config(
    nb: path("export.ipynb"),
    kernel: "python3",
    theme: "neat",
  )
  #show raw.where(lang: "py-x"): it => {
    set text(1em/0.8)
    execute(it)
  }
  #stage-notebook()

  Here is a plot of $y = x^2$ :

  ```py-x
  import matplotlib.pyplot as plt
  plt.rcParams['figure.figsize'] = (3, 2)
  x = [1, 2, 3, 4]
  y = [1, 4, 9, 16]
  plt.plot(x, y);
  ```

  The plot uses #evaluate(`len(x)`) data points.

  Here is how to expand $(a+b)^2$ with SymPy:

  ```py-x
  #| output: false
  import sympy as sp
  a, b = sp.symbols('a b')
  sp.expand((a+b)**2)
  ```<sympy-calc>

  The result is: #output(<sympy-calc>)
]
