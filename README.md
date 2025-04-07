# Callisto

A Typst package for reading from Jupyter notebooks. It currently addresses the following use cases:

- Extracting specific cell sources and cell outputs, for example to include a plot in a Typst document.

- Rendering a notebook in Typst (embedding selected cells or the whole notebook).

<img src="docs/lorenz-extract.png" width="600px" alt="Rendering of the first cells of the Lorenz.ipynb notebook">

## Quick start

The examples below illustrate the basic functionality. For more information see

-  the [tutorial](docs/Tutorial.md),
-  the [function reference](docs/Reference.md).

```typst
#import "@preview/callisto:0.2.0"

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
```

The manual call to `json(...)` is currently required to avoid issues with relative file paths between the user root and the package root. This should be solved once Typst gets a `path` type.

## Design

The API is centered on the following main functions:

- `render`: takes a cell specification and returns content for the selected cells, rendered using the selected template.

- `sources`: takes a cell specification and returns raw blocks with the cell sources. The raw block can be used as as content. Alternatively, the source text and source language can be accessed as fields.

- `outputs`: takes a cell specification and returns cell outputs of the desired type (result, displays, errors, streams).

The function parameters are described in detail in the [function reference](docs/Reference.md).

The cell specification can be a cell index, execution count, tag, ID, metadata label, user-defined cell field or filter function. Code cells can start with header lines of the form `#| key: value`. When a notebook is processed, header lines are used to define corresponding fields in the cell metadata, and are removed from the cell source.

For convenience, many additional functions are derived from the main functions by preconfiguring some of their parameters. For example, `render` has `Cell`, `In` and `Out` as preconfigured aliases to render a single cell, either in entirety (`Cell`) or just the input or output (`In` and `Out`). And `outputs` has aliases such as `results` and `displays` to get an array of results or displays for the selected cells.

Most aliases have a singular and a plural form, e.g. `result` and `results`: the singular form will return a single value (which can often be used directly as content), while a plural form always returns an array. By default the singular form also checks that there is a single value to return: for example `result("figure1")` will raise an error if the call matches more than one cell.

All the functions can be further preconfigured by calling `config`, which returns a dict of preconfigured functions. This is most commonly used to set the notebook for all functions, but can also be used for any parameter such as the rendering template or the preferred image formats.


## Markdown and LaTeX rendering configuration

By default Markdown and LaTeX are rendered using [cmarker](https://github.com/SabrinaJewson/cmarker.typ) and [mitex](https://github.com/mitex-rs/mitex). These cannot (yet) render everything.

The Markdown and LaTeX processing can be configured by changing the handlers for `text/markdown` and `text/latex`. For example to get working rendering of image files references in Markdown, the following can be used:

   ```typ
   #import "@preview/cmarker:0.1.3"
   #import "@preview/mitex:0.2.5": mitex

   #callisto.render(
     nb: "notebook.ipynb",
     handlers: (
       "text/markdown": cmarker.render.with(
           math: mitex,
           scope: (image: (path, alt: none) => image(path, alt: alt)),
       ),
     ),
   )
   ```

(This should become unnecessary once Typst adds a `path` type for file paths.)
   

## Current features and roadmap

- [x] Easy reading of cell source and outputs from notebooks

- [x] Render notebooks in Typst

   - [x] Markdown
   - [x] results (basic types)
   - [x] displays (basic types)
   - [x] stdout and stderr
   - [x] errors
   - [ ] ANSI escape sequences in text outputs

- Supported output types

   - [x] text/plain
   - [x] image/png
   - [x] image/jpeg
   - [x] image/svg+xml
   - [x] text/markdown
   - [x] text/latex
   - [ ] text/html

- [ ] Export, e.g. for round-tripping similar to prequery
