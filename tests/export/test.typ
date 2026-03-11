#import "/callisto.typ"

#show heading: set block(below: 1em)
#set heading(numbering: "1.")

// Work around https://github.com/typst/typst/issues/1331
#show raw: set text(8.8pt)

#let (cell, render, Cell, In, Out, export, make-notebook, stage-notebook) = callisto.config(
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

= Select exports using a label

== Show rule to show + export + render

#show <g>: it => rect(it, width: 100%) + export(it) + render(it)

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

// Get bool from cell metadata
#let get-bool(c, key) = c.metadata.at(key, default: "true") == "true"

#let render-conditional(it) = {
  let c = cell(it)
  if c == none { return }
  render(c, input: get-bool(c, "echo"), output: get-bool(c, "output"))
}

#show <check-header>: it => export(it) + render-conditional(it)

Cell with `output: false` in header:

```python
#| output: false
2 + 3
```<check-header>

Cell with `echo: false` in header:

```python
#| echo: false
10 + 1
```<check-header>

== Get cell name

Cell `x`:
#Cell("x")

== Render all exported cells with a given label
#render(<g>)

== Render input/output/both based on label

#show <cell>: it => export(it) + Cell(it)
#show <in>:   it => export(it) + In(it)
#show <out>:  it => export(it) + Out(it)

Whole cells:

```python
10 + 1
```<cell>

```python
10 + 2
```<cell>

Only input:

```python
10 + 3
```<in>

Only output:

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
a = 23
```<a>

```python-x
b = 42
```<b>

== Render cell selected by label

#Cell(<a>)

== Render exported cells using raw lang query

#context render(query(raw.where(lang: "python-x")))

== Render exported cells using raw lang in cell metadata

#render(c => c.metadata.callisto.lang == "python-x")

= Second export with another name

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
