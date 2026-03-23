#import "/callisto.typ"

#show heading: set block(below: 1em)
#set heading(numbering: "1.")

// Work around https://github.com/typst/typst/issues/1331
#show raw: set text(8.8pt)

#let (
  cell,
  result,
  render,
  Cell,
  In,
  Out,
  export,
  make-notebook,
  stage-notebook,
  execute,
  evaluate,
) = callisto.config(
  nb: "export.ipynb",
  kernel: "python3",
  handlers: (path: (x, ..args) => read(x, encoding: none)),
)

// Expose the exported notebook as labelled metadata for `typst query`
#stage-notebook()

// Embed the notebook (unexecuted) in the PDF
#context pdf.attach(
  "notebook.ipynb",
  bytes(json.encode(make-notebook())),
  mime-type: "application/x-ipynb+json",
  relationship: "supplement",
  description: "Notebook of all code blocks in the document",
)

#outline()

= Select exports using a label

== Show rule to show + export + render

#show <g>: it => rect(it, width: 100%) + execute(it)

```python
#| label: x
a = 1
b = 2
c = a + b
c
```<g>

```python
"a" + "b"
```<g>

== Control what part to show from the cell header

#show <with-header>: execute

Cell with `output: false` in header:

```python
#| output: false
2 + 3
```<with-header>

Cell with `echo: false` in header:

```python
#| echo: false
10 + 1
```<with-header>

== Get cell by name

Cell `x`:
#Cell("x")

== Render all exported cells with a given Typst label
#render(<g>)

== Render input/output/both based on label

#show <cell>: execute
#show <in>:   execute.with(output: false)
#show <out>:  execute.with(input: false)

Cells that should be rendered in whole:

```python
10 + 1
```<cell>

```python
10 + 2
```<cell>

Cell that should show only input:

```python
10 + 3
```<in>

Cell that should show only output:

```python
10 + 4
```<out>

= Select exports using raw lang

(The raw lang fill be "fixed" automatically by the kernel upon execution.)

#show raw.where(lang: "python-x"): export

```python
# Some raw block, not exported
[1,2,3]
```

```python-x
a = 23; a
```<a>

```python-x
b = 42; b
```<b>

== Cell exported by lang and selected for render using Typst label

#Cell(<a>)

== Render exported cells using raw lang query

#context render(query(raw.where(lang: "python-x")))

== Render exported cells using raw lang in cell metadata

#render(c => c.metadata.callisto.export.lang == "python-x")

== Inline raw elements with `evaluate`

The square of 3 is #evaluate(`3*3`).

== Inline raw exported by label

// Outputs in the the context of a raw element so will use monospace font
#show <x>: evaluate

The square of 4 is `4*4`<x>, and that of 5 is `5*5`<x>.

== With workaround for issue of raw context in show rule

// Add something in cell header to avoid exporting twice exactly the same thing
#show <x2>: evaluate.with(cell-header: (dedup: "2"))

#show <x2>: set text(font: "Libertinus Serif", size: 1em/0.8)

The square of 4 is `4*4`<x2>, and that of 5 is `5*5`<x2>.

= Second export with another name

#let (
  result: result-sympy,
  export: export-sympy,
  stage-notebook: stage-sympy,
) = callisto.config(
  nb: "export-sympy.ipynb",
  kernel: "python3",
  export-name: "sympy",
  handlers: (path: (x, ..args) => read(x, encoding: none)),
)

#stage-sympy()

#export-sympy(
  ```
  from sympy import *
  x = symbols('x')
  ```
)

== Generated code blocks

Code can be generated dynamically for execution:

#let exprs = (
  "2*x**3 + 4*x",
  "sin(2*x)",
  "log(x + 1)",
)

// Generate two cells for each expr: one for the expr, one for its derivative
#for (i, expr) in exprs.enumerate() {
  export-sympy(raw(expr), cell-header: (label: str(i)))
  export-sympy(raw("diff(" + expr + ")"), cell-header: (label: str(i) + "-diff"))
}

// Build table from results
#table(
  columns: 2,
  inset: 1em,
  stroke: none,
  table.header($f$, $f'$),
  table.hline(),
  ..for i in range(exprs.len()) {
    (
      result-sympy(str(i)),
      result-sympy(str(i) + "-diff"),
    )
  }
)

= Third export with another kernel

#let (
  In: In-julia,
  Out: Out-julia,
  export: export-julia,
  stage-notebook: stage-julia,
) = callisto.config(
  nb: "export-julia.ipynb",
  kernel: "julia-1.11",
  export-name: "julia",
  handlers: (path: (x, ..args) => read(x, encoding: none)),
)

#stage-julia()

#show <exec>: export-julia

```
#| label: sin
sin(1.2)
```<exec>

Here's Julia code to compute a sine value (`raw` lang set upon execution by the
kernel):

#In-julia("sin")

And here is the result:

#Out-julia("sin")
