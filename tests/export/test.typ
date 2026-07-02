#import "/callisto.typ"

#show heading: set block(below: 1em)
#show heading.where(level: 1): set text(14pt)
#show heading.where(level: 2): set text(12pt)
#set heading(numbering: "1.")

#let (
  cell,
  source,
  sources,
  result,
  render,
  Cell,
  In,
  Out,
  export,
  make-notebook,
  execute,
  evaluate,
) = callisto.config(
  nb: path("export-python.ipynb"),
  kernel: "python3",
  export-name: "python",
)

// Export all notebooks under the same label
#context for name in callisto.export-names() {
  callisto.stage-notebook(export-name: name, export-label: <notebook>)
}

// Embed the notebook (unexecuted) in the PDF
#context pdf.attach(
  "notebook.ipynb",
  bytes(json.encode(make-notebook())),
  mime-type: "application/x-ipynb+json",
  relationship: "supplement",
  description: "Notebook of all code blocks in the document",
)

// Check that the exported notebook is up to date with this document
#context {
  let external = sources()
  let internal = sources(nb: make-notebook())
  if external.len() != internal.len() or array.zip(external, internal).any(
    ((a, b)) => a.text != b.text
  ) {
    rect(width: 100%, inset: 1em, stroke: red)[Exported notebook outdated]
  }
}

= Using `#show: <label>: execute`

#let revoke-and-execute(..args) = { set text(1em/0.8); execute(..args) }

#show <g>: revoke-and-execute

```python
x = 1 + 2; x
```<g>

```python
x += 1; x
```<g>

Same code again, different result:

```python
x += 1; x
```<g>

== Control what part to show from the cell header

#show <with-header>: revoke-and-execute

```python
#| label: x
#| output: false
2 + 3
```<with-header>

```python
#| echo: false
3 + 4
```<with-header>

== Get cell by name

Cell `x` result: #result("x")

== Select by Typst label
#render(<with-header>)

== Render input/output/both based on label

#show <cell>: revoke-and-execute
#show <in>:   revoke-and-execute.with(output: false)
#show <out>:  revoke-and-execute.with(input: false)

```python
10 + 1
```<cell>

```python
10 + 2
```<in>

```python
10 + 3
```<out>

#pagebreak()

= Select exports using raw lang

(The raw lang will be "fixed" automatically by the kernel upon execution.)

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

== Select with Typst label

#Cell(<a>)

== Select with raw lang query

#context render(query(raw.where(lang: "python-x")))

== Select with raw lang in cell metadata

#render(c => c.metadata.callisto.export.lang == "python-x")

== Select with raw lang and execute

#show raw.where(lang: "python-xx"): revoke-and-execute

```python-xx
c = 91; c
```

#pagebreak()

= Inline raw elements

== With `evaluate`

The square of 3 is #evaluate(`3*3`).

=== Using `transform`

Multiplied by ten: #evaluate(
  `3*3`,
  transform: x => int(x) * 10,
).

A table with $3^2$ cells:

#let my-table(n) = {
  set align(center)
  table(
    columns: int(n),
    ..range(int(n)).map(str),
  )
}
#evaluate(`3*3`, transform: my-table)

== Exported by label

// Outputs in the the context of a raw element so will use monospace font
#show <x>: evaluate

The square of 4 is `4*4`<x>, and that of 5 is `5*5`<x>.

== Work around issue of raw context in show rule

#show <x2>: it => {
  set text(font: "Libertinus Serif", size: 1em/0.8)
  // Add something in cell header to avoid exporting twice exactly the same thing
  evaluate(it, cell-header: (dedup: "2"))
}

The square of 4 is `4*4`<x2>, and that of 5 is `5*5`<x2>.

= Second export with another name

#let (
  result: result-sympy,
  export: export-sympy,
) = callisto.config(
  nb: path("export-sympy.ipynb"),
  kernel: "python3",
  export-name: "sympy",
)

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
#align(center, table(
  columns: 2,
  inset: 0.5em,
  stroke: none,
  table.header($f$, $f'$),
  table.hline(),
  ..for i in range(exprs.len()) {
    (
      result-sympy(str(i)),
      result-sympy(str(i) + "-diff"),
    )
  }
))

#pagebreak()

= Third export with another kernel and with "neat" theme

#let (
  template,
  In: In-julia,
  Out: Out-julia,
  output: output-julia,
  export: export-julia,
  execute: execute-julia,
  evaluate: evaluate-julia,
) = callisto.config(
  nb: path("export-julia.ipynb"),
  kernel: "julia-1.11",
  export-name: "julia",
  theme: "neat",
  console-text: (bg: luma(30%)),
)

#show: template.with(set-fonts: false)
// Simulate a template that also applies show-set rules on inline raws
// (to check that we can avoid styling evaluation outputs that aren't raw)
#show raw.where(block: false): set text(red)

#show <exec>: export-julia

```julia
# Regular raw block (not exported/executed)
2 + 2
```


```
#| label: sin
sin(1.2)
```<exec>

Here's Julia code to compute a sine value (`raw` lang set upon execution by the
kernel):

#In-julia("sin")

And here is the result:

#Out-julia("sin")

== Rendering through `execute`

#show <exec2>: it => {
  set text(1em/0.8)
  execute-julia(it)
}

```
#| label: cos
cos(1.2)
```<exec2>

== Custom handler to handle fig-cap in cell metadata

#let fig-wrapper(it, ctx: none, ..args) =  {
  let caption = ctx.cell.metadata.callisto.header.at("fig-cap", default: none)
  if caption != none {
    figure(caption: caption, rect(it))
  } else {
    it
  }
}

#show raw.where(lang: "julia-x"): it => {
  set text(1em/0.8, font: "Libertinus Serif")
  set block(fill: none, inset: 0pt) // undo some styling from neat theme
  execute-julia(it, handlers: (code-cell-output: (auto, fig-wrapper)))
}

```julia-x
#| label: tan
#| fig-cap: Tangent of 1.2
tan(1.2)
```

== Output with ANSI escape sequences

```
println(read("../ansi/model_summary_output.txt", String))
```<exec2>

== Inline computations

#show raw.where(lang: "jx").or(<jx>): it => {
  set text(1em/0.8, font: "Libertinus Serif", fill: black)
  evaluate-julia(it)
}

Here's an inline computation: ```jx 2+3``` and another one: `2+4`<jx>
