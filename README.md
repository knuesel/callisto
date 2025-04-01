# Callisto

A Typst package for reading from Jupyter notebooks. It currently adresses the following use cases:

- Extracting specific cell sources and cell outputs, for example to include a plot in a Typst document.

- Rendering a notebook in Typst (embedding selected cells or the whole notebook).

## Usage example

```typst
#import "@local/callisto:0.0.1"

// Render whole notebook
#callisto.render(nb: json("notebook.ipynb"))

// Render all code cells named/tagged with "plot", showing only the cell output
#callisto.render("plot", nb: json("notebook.ipynb"), cell-type: "code", input: false)

// Let's get functions preconfigured to use this notebook
#let (render, display, source, Cell, In, Out) = callisto.config(
   nb: json("notebook.ipynb"),
)

// Render only the first 10 cells
#render(range(10))

// Get the only display output of the third cell
#display(2)

// Force using the PNG version of that output
#display(2, format: "image/png")

// Get the source of that cell as a raw block, then get the text of it
#source(2).text

// Render the cell with execution number 4 (count can also be set by config())
#Cell(4, count: "execution")

// Render separately the input and output of cell named/tagged "abc"
#In("abc")
#Out("abc")
```

### Main functions

-  `config`: accepts all the parameters of the other main functions, and returns a dict with all main and auxiliary functions preconfigured accordingly. Also returns a `template` function for the whole document, to be used together with `render(template: "plain")`.

-  `cells([spec], nb: none, count: "position", name: auto, cell-type: "all", keep: "all")`

   Retrieves cells from a notebook. Each cell is returned as a dict. This is a low-level function to be used for further processing.

   The optional `spec` argument is used to select cells: if omitted, all cells are selected. Possible values:

   -  An integer: by default this refers to the cell position in the notebook, but `count: "execution"` can be used to have this refer to the execution count.
   -  A string: by default this can be either a cell label, ID, or tag. Cell labels must be set as a "label" field in the cell metadata, or on the first line of cell code:

      ```
      #| label: xyz
      ...
      ```

      The `name` parameter can be used to change how the string is matched to cells.

   -  A function which is passed a cell dict and must return `true` for desired cells, `false` otherwise.

   -  A literal cell (a dictionary as returned by another `cells` call).

   `count` can be `"position"` or `"execution"`, to select if a cell number refers to its position in the notebook (zero-based) or to its execution count.

   `name` can be a string or an array of strings, or `auto` for the default names: `("metadata.label", "id", "metadata.tags")`. Each name in the array will be tried in order to check if a particular cell should be selected. A name of the form `x.y` refers to field `y` in field `x` of the cell.

   `cell-type` can be `"markdown"`, `"raw"`, `"code"`, an array of these values, or `"all"`.

   `keep` can be a cell index, an array of cell indices, `"all"`, or `"unique"` to raise an error if the call doesn't match exactly one cell. This filter is applied after all the others described above.

-  `sources(..cell-args, result: "value", lang: auto)`

   Retrieves the source from selected cells. The `cell-args` are the same as for the `cells` function.

   `result`: how the function should return its result: `"value"` to return a list of values that can be inserted, or `"dict"` to return a dictionary that contains a `"value"` field as well as metadata.

   `lang`: the language to set on the returned raw blocks. By default this is inferred from the notebook metadata.

-  `outputs(..cell-args, output-type: "all", format: default-formats, handlers: auto, ignore-wrong-format: false, stream: "all", result: "value")`

   Retrieves outputs from selected cells. The `cell-args` are the same as for the `cells` function.

   `output-type` can be `"display_data"`, `"execute_result"`, `"stream"`, `"error"`, an array of these values, or `"all"`.

   `format` is used to select an output format for a given output (Jupyter notebooks can store the same output in several formats to let the reader choose a format). This should be a format MIME string, or an array of such strings. The array order sets the preference: the first match is used. Only formats that have a corresponding handler are valid (see `handlers`). The default value is `("image/svg+xml", "image/png", "text/markdown", "text/latex", "text/plain")`.

   `handlers` is a dictionary mapping MIME strings to handler functions. Each handler function should accept a data string and return the value that should be included in the Typst document. These handlers expand/override the default dict of handlers.

   `ignore-wrong-format`: by default an error is raised if a selected output has no format matching the list of desired formats (see `format`). Set to `true` to skip the output silently.

   `stream`: for stream outputs, this selects the type of streams that should be returned. Can be `"stdout"`, `"stderr"` or `"all"`.

   `result`: how the function should return its result: `"value"` to return a list of values that can be inserted, or `"dict"` to return a dictionary that contains a `"value"` field as well as metadata.

- `render(..cell-args, ..input-args, ..output-args, input: true, output: true, template: "notebook")`

   Renders selected cells in the Typst document.

   `cell-args` can be passed to select cells as described for the `cells` function.

   `input-args` can be passed to affect the rendering of cell inputs, as described in the `sources` function.

   `output-args` can be passed to select outputs as described for the `outputs` function.

   `input` specifies if cell inputs should be rendered.

   `output` specifies if cell outputs should be rendered.

   `template` can be one of the built-in template names: `"notebook"` or `"plain"`, or a function, or a dict with keys among `raw`, `markdown`, `code`, `input` and `output`. A function should accept a `cell` positional argument (dict) for the cell to render, `input` and `output` keyword arguments (booleans) to enable/disable rendering of the input or output, and `input-args` and `output-args` keyword arguments (dicts) which the function can forward to other functions such as `outputs` and `sources` respectively. When a dict is passed, each value can be a function, or a built-in template name to use that template for that type of cell/cell component. The template specified for `code` if specified will be used for both code input and output.

### Auxiliary functions

The package also provides many functions that are mostly aliases of the main functions but with some parameters preconfigured:

`displays`, `results`, `stream-items`, `errors`: same as `outputs` but preconfigured to select only one type of output.

`streams` is similar to `stream-items`, but merges all selected streams that belong to the same cell, and always returns an item (possibly with an empty string as value) for each selected code cell.

`cell`: same as `cells` but always returns a single cell (not an array). By default it also checks that there is only one cell to return by calling `cells` with `keep: "unique"` but this can be changed by setting `keep` to another value.

`source`, `output`, `display`, `result`, `stream-item`, `error`, `stream`: same as the "plural form" but always return a single item. By default these functions also check that there is only one item to return. This can be changed by setting the `item` keyword argument to an integer (the default value is `"unique"`).

`Cell`: same as `render` but preconfigured with `keep: "unique"` to render a single cell and raise an error if not exactly one cell was selected.

`In` and `Out:` same as `Cell` but preconfigured to render only the cell input and output respectively.

## Features

- [x] Easy reading of cell source and outputs from notebooks

- [x] Render notebooks in Typst

      - [x] Markdown
      - [x] results (basic types)
      - [x] displays (basic types)
      - [x] stdout and stderr
      - [x] errors

- Supported output types

      - [x] text/plain
      - [x] image/png
      - [x] image/jpeg
      - [x] image/svg+xml
      - [x] text/markdown
      - [x] text/latex
      - [ ] text/html

- [ ] Export, e.g. for round-tripping similar to prequery

Limitations:

- By default Markdown and LaTeX are rendered using [cmarker](https://github.com/SabrinaJewson/cmarker.typ) and [mitex](https://github.com/mitex-rs/mitex). These cannot (yet) render everything. Note that the Markdown and LaTex processing can be configured by setting different `handlers` for `text/markdown` and `text/latex`. For example to get working rendering of image files references in Markdown, the following can be used:

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
   

## Related projects

- [pandoc](https://pandoc.org/): a universal markup converter that can translate Jupyter notebooks.

- [Quarto](https://quarto.org/): a publishing system that can read Jupyter notebooks and render with Typst as backend.

- [Jlyfish](https://github.com/andreasKroepelin/TypstJlyfish.jl/): a package for Julia and Typst to integrate Julia computations in Typst documents.

- [typst_of_jupyter](https://github.com/dermesser/typst_of_jupyter): an OCaml project to render Jupyter notebooks using Typst.
