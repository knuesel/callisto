# API Reference

## Overview

The primary functionality is exposed through the following main functions:

* The rendering functions: `render` and its single-cell aliases `Cell`, `In`, `Out`.
* The extraction functions: `cells`, `sources`, `outputs`, `results`, `displays`, `stream-items`, `streams`, `errors` and the singular variants `cell`, `source`, `output`, `result`, `display`, `stream-item`, `stream`, `error`.
* The export-related functions: `export`, `make-notebook`, `stage-notebook`, `execute`, `evaluate`.

Callisto additionally exports

* The `config` function, to preconfigure the main functions for example to have them work with a particular notebook file.
* The `handle` function, used in themes and custom handlers to process a value according to the current configuration.
* Various utility functions in submodules, such as `header-pattern.parse-text` and `ansi.strip`.

## Configuration

The main functions can be configured by calling `config`, which accepts all the parameters of the main functions, and returns a dictionary with those functions preconfigured accordingly. For example

```typst
#let (output, render) = callisto.config(
   nb: json("notebook.ipynb"),
   output-type: ("display_data", "execution_result"),
   item: 0,
)
```

configures `output` and `render` to use `notebook.ipynb` as notebook, keep only display and result outputs (ignoring errors and streams), and in case of multiple outputs to keep only the first one (index 0).

The dictionary returned by `config` also includes a `template` function, which is either the document template defined by the selected theme, or a do-nothing template if the theme defines no such function. Usage is as follows:

```typst
#let (template, render) = callisto.config(
   nb: json("notebook.ipynb"),
   theme: "neat",
)

#show: template

#render()
```


## Cell specification

Most functions accept a cell specification as positional argument. Below we use the `render` function for illustration. The cell specification can be:

-  An integer: by default this refers to the cell index in the notebook, but `count: "execution"` can be used to have this refer to the execution count. Examples:

   ```typst
   #render(0) // render first cell
   #render(1, count: "execution") // render cell with execution_count equal to 1
   ```

-  A string: by default this can be either a cell label, ID, or tag. A cell label refers to a `label` field in the cell's `metadata.callisto.header` dict. The label can be defined by adding a special [header](#cell-data-and-cell-header) at the top of the cell source:

   ```
   #| label: xyz
   ...
   ```

   The `name-path` parameter can be used to change how the string is matched to cells.

   Examples:

   ```typst
   // Render cell(s) with label or tag "plot1"
   #render("plot1") 
   // Render cell(s) with `metadata.callisto.header.type` field set to "scatter"
   // (for example a cell with `#| type: scatter` in the header).
   #render("scatter", name-path: "metadata.callisto.header.type")
   ```

-  A raw element: this will find all the code cells in the notebook that have exactly the same source code and [header](#cell-data-and-cell-header) as the raw element.

   For the raw element, the header is computed by merging the `cell-header` setting with the header rows found in the raw element text. This is compared to the header built from the source of each notebook code cell. Examples:

   ````typst
   // Render the code cell(s) with label "calc" and single code line `2 + 2`
   #render(
     ```
     #| label: calc
     2 + 2
     ```
   )
   // Another way to do the same thing:
   #render(`2 + 2`, cell-header: (label: "calc"))
   ````

   This kind of specification is used by the `execute` and `evaluate` functions to find exported cells in the executed notebook.

-  A Typst label: this finds cells that were exported from a Typst document from raw blocks with the given Typst label. Example:

   ````typst
   #show raw.where(lang: "python-x"): export

   ```python-x
   sum(range(5))
   ```<sum-calc>

   Here is how to compute $1 + 2 + 3 + 4 + 5$ in Python:
   #render(<sum-calc>)
   ````

   See the [Export and execution tutorial](Export-and-execution-tutorial.md) for more information about this functionality.

   Note: Typst labels should not be confused with cell labels (which are strings defined in the cell header). They are two independent concepts with different features and limitations. For example cell labels are meant to be unique, while the same Typst label can be used on many cells, e.g. to select inline raw elements for export. Ideally we would use different names for the two concepts, but we try to maintain some compatibility with [Quarto chunk options](https://quarto.org/docs/computations/execution-options.html).

-  A function which is passed a cell dict and must return `true` for desired cells, `false` otherwise. Example:

   ```typst
   // Results of cells with execution count larger than 3
   #results(c => c.execution_count > 3)
   ```

-  A literal cell (a dictionary as returned by a `cell` call). Example:

   ```typst
   // Get the cell with label "nice-plot"
   #let c = cell("nice-plot")
   // Render it with the "plain" theme
   #render(c, theme: "plain")
   ```

   Note: if you have a cell dict that you synthesized or extracted from a notebook yourself (rather than going through a Callisto function like `cells` or `cell`), you must preprocess it with `callisto.reading.notebook.preprocess-cell` before passing it to other Callisto functions. See [here](#cell-data-and-cell-header) for more information on cell preprocessing.

-  An array of the above. Cells that match any of the array elements are included in the result. Examples:

   ```typst
   // Render the first 10 cells
   #render(range(10))
   // Render first cell, "plot1" cell and all cells that have an error
   #render((
      0,
      "plot1",
      c => c.at("outputs", default: ()).any(x => x.output_type == "error"),
   ))
   ```

## Main functions

-  `cells([spec], nb: none, count: "index", name-path: auto, cell-type: "all", keep: "all", cell-header-pattern: auto, keep-cell-header: false)`

   Retrieves cells from a notebook. Each cell is returned as a dict. This is a low-level function to be used for further processing.

   -  `spec` is an optional argument used to select cells: if omitted, all cells are selected. See the [cell specification](#cell-specification) section. Example:

      ```typst
      // Get the first five cells
      #cells(range(5))
      ```

   - `nb` can be the path to a notebook file as string (currently this requires defining a "path" handle as in the example below). It can also be the content of a notebook file as `bytes`, or as a dict as returned by the `json` function. Examples:

      ```typst
      // Specify the notebook by path
      #let (output, render) = callisto.config(
         nb: "notebook.ipynb",
         handlers: (path: (x, ..args) => read(x, encoding: none)),
      )

      // Alternative: read notebook before passsing it to config
      #let (output, render) = callisto.config(
         nb: json("notebook.ipynb"),
      )
      ```

      Typst 0.15 will probably introduce a `path` type that will make this "path" handler unnecessary in many cases (a similar handler will still be required to properly process Markdown cells that refer to external files).

   -  `cell-header-pattern` can be a pattern string, or `auto` for the default pattern string: `"# | %key: %value"`, or a dict with `regex` and `writer` fields. This pattern specifies which lines at the start of code cells constitute a [metadata header](#cell-data-and-cell-header). If given as string, the pattern must include the "words" `%key` and `%value`, and any whitespace in the string will be considered as representing any amount of whitespace (possibly none). If given as dict, the `regex` field must be a regular expression that defines a first capture group for the key and a second one for the value, and the `writer` field must be a function that takes key and value strings as positional arguments and returns a header line without trailing newline.

      The default pattern matches lines of the form `#| key: value` and `# | key: value` (a space between `#` and `|` is allowed as it might be added by code formatters and expected by linters). This is appropriate for kernels that recognize `#` as starting a line comment. For other kernels the pattern must be set manually. Examples:

      ```typst
      // Header pattern for languages that start line comments with //
      #let (render,) = callisto.config(
         nb: json("notebook.ipynb"),
         cell-header-pattern: "//| %key: %value",
      )

      // Header pattern with strict format `#| key: value` without whitespace
      // between `#` and `|`
      #let (render,) = callisto.config(
         nb: json("notebook.ipynb"),
         cell-header-pattern: (
            regex: regex("^#\|\s+(.*?):\s+(.*?)\s*$"),
            writer: (key, value) => "#| " + key + ": " + value,
         ),
      )
      ```

   -  `keep-cell-header` is a boolean: when `true`, the [metadata header](#cell-data-and-cell-header) is not removed from the cell source. The default is `false`. Example:

      ```typst
      // Render cells while preserving the cell metadata headers
      #render(keep-cell-header: true)
      ```

   -  `count` can be `"index"` or `"execution"`, to select if a cell number refers to its position in the notebook (zero-based) or to its execution count. Example:

      ```typst
      // Cells with execution count between 5 and 9
      #cells(range(5, 10), count: "execution")
      ```

   -  `name-path` can be a string or an array of strings, or `auto` for the default array `("metadata.callisto.header.label", "id", "metadata.tags")`. These strings define where Callisto will look for cell names for cells that are [specified](#cell-specification) by string: Each string in the `name-path` array specifies a path in the cell dict. A string of the form `x.y` refers to path `y` in path `x` of the cell. The cell is selected if the value at the full path is either the cell specification string, or an array containing that stirng. Example:

      ```typst
      // Render cells that have `#| type: scatter` in the cell header
      #render("scatter", name-path: "metadata.callisto.header.type")
      ```

   -  `cell-type` can be `"markdown"`, `"raw"`, `"code"`, an array of these values, or `"all"`. Example:

      ```typst
      // Get cells with index between 0 and 9 and discard the raw cells
      #cells(range(10), cell-type: ("markdown", "code"))
      ```

   -  `keep` can be a cell index, an array of cell indices, `"all"`, or `"unique"` to raise an error if the call doesn't match exactly one cell. This filter is applied after all the others described above. Example:

      ```typst
      // Get first and last non-raw cells with index between 0 and 9
      #cells(range(10), cell-type: ("markdown", "code"), keep: (0, -1))
      ```

-  `sources(..cell-args, result: "value", lang: auto, raw-lang: none)`

   Retrieves the source from selected cells. The `cell-args` are the same as for the `cells` function.

   -  `cell-args`: these are arguments that can be used to select cells as described for the `cells` function. Example:

      ```typst
      // Get the source of all the code cells
      #sources(cell-type: "code")
      ```

   -  `result`: how the function should return its result: `"value"` to return each result as a simple value, or `"dict"` to return them as dictionaries that contain a `"value"` field, plus other fields holding metadata. Example:

      ```typst
      // Get a dict with source and various metadata for each code cell
      #sources(cell-type: "code", result: "dict")
      ```

   -  `lang`: the language of code cells in the notebook. This will be used as language tag for the raw blocks holding the cell sources. By default this is inferred from the notebook metadata. Example:

      ```typst
      // Get source of all cells, setting the language to python for code cells
      #sources(lang: "python")
      ```

   -  `raw-lang`: the language of raw cells in the notebook. This will be used as language tag for the raw blocks holding the cell sources. Example:

      ```typst
      // Get source of all cells, setting `lang` to `typ` for raw cells
      #sources(raw-lang: "typ")
      ```

-  `outputs(..cell-args, output-type: "all", format: auto, ignore-wrong-format: false, stream: "all", result: "value", handlers: auto, apply-theme: false, theme: "notebook")`

   Retrieves outputs from selected cells. This function operates only on code cells; other cell types are ignored.

   -  `cell-args`: these are arguments that can be used to select cells as described for the `cells` function. Example:

      ```typst
      // Get the outputs of the cell with execution count 3
      #outputs(3, count: "execution")
      ```

   -  `output-type` can be `"display_data"`, `"execute_result"`, `"stream"`, `"error"`, an array of these values, or `"all"`.

      The `execute_result` output is usually the value returned by the last line in a code cell; this output is usually missing if the last line returns nothing. It is possible to have other cell lines generate results (for example using `sys.displayhook` in Python) but that is uncommon and not recommended. A single result can be stored in multiple formats in the notebook, to let the reader choose a preferred format. Use the `format` parameter to choose a particular format for the result (see below).

      A `display_data` output is a display object generated by the cell, in addition to (or instead of) the cell result. A cell can have many display outputs. As for `execute_result` outputs, each display output can be stored in multiple formats in the notebook.

      A `stream` is a piece of text written by the cell either on the standard output or the standard error (see the `stream` parameter below). When a cell produces interleaved messages on both streams, each message is stored in the notebook as a separate stream item so that the order of messages is preserved. To get the stream name for each stream item, set `result` to `"dict"` (see below).

      An `error` stores information on an error raised during the execution of a cell. Set `result` to `"dict"` (see below) to get detailed information on the error, including a backtrace.

      Example:

      ```typst
      // Get the results and/or errors of all code cells
      #outputs(output-type: ("execute_result", "error"))
      ```
      
   -  `format` is used to select an output format for a given output (Jupyter notebooks can store the same output in several formats to let the viewer choose a format). This should be a format MIME string, or an array of such strings. The array order sets the preference: the first match is used. Every listed format must have a corresponding handler (see `handlers`). The value `auto` refers to the default value: `("image/svg+xml", "image/png", "image/gif", "image/jpeg", "text/markdown", "text/latex", "text/plain")`. The value `auto` can also be used as one element of an array of values; in this case the default values will be inserted at that position in the array. Example:

      ```typst
      // Get PNG version of all display outputs, error if a display has no PNG
      #outputs(output-type: "display_data", format: "image/png")
      // Get PNG version where available, use default precedence otherwise
      #outputs(output-type: "display_data", format: ("image/png", auto))
      ```

   -  `ignore-wrong-format`: by default an error is raised if a selected output has no format matching the list of desired formats (see `format`). Set to `true` to skip the output silently. Example:

      ```typst
      // Get PNG version of all display outputs, ignoring displays without PNG
      #outputs(format: "image/png", ignore-wrong-format: true)
      ```

   -  `stream`: for stream outputs, this selects the type of streams that should be returned. Can be `"stdout"`, `"stderr"` or `"all"`. Example:

      ```typst
      // Get all errors, and all messages written to stderr
      #outputs(output-type: ("error", "stream"), stream: "stderr")
      ```

   -  `result`: how the function should return its result: `"value"` to return each result as a simple value, or `"dict"` to return them as dictionaries that contain a `"value"` field, plus other fields holding metadata. Example:

      ```typst
      // Get the traceback of every error
      #outputs(output-type: "error", result: "dict").map(x => x.traceback)
      ```

   -  `handlers`: a dictionary mapping "MIME types" to handler functions. A handler is a function called to process a value of particular type. A particular value is often processed in multiple steps through a chain of handlers. For example, by default a display output holding a PNG image will be processed by calling the `output` handler which will call the `display` handler, etc. resulting in the following sequence of handlers: `output` → `display` → `rich-output-generic` → `image/png`.

      Each handler should accept a positional argument for the data to process and any keyword argument, and return the processed data. The dict passed to `handlers` is merged with the dict of default handlers, overriding default values with the specified ones. Example:

      ```typst
      // Show all text outputs in uppercase
      #outputs(handlers: ("text/plain": (data, ..args) => upper(data)))
      ```

      Instead of a function, the field value can also be `none` (equivalent to a function that returns `none`), or `auto` for the default handler, or an array of handler functions or `auto` or `none` values. In the case of an array, the handler functions are chained by calling the first one, then the second one with the result of the first, etc. Example:

      ```typst
      // Show each cell in a frame by calling the default handler, then putting
      // the result in a rect
      #let frame(it, ..args) = rect(it, width: 100%)
      #outputs(handlers: ("cell": (auto, frame)))
      ```

      See the [handler section](#handlers) for more information.

   -  `apply-theme`: whether the theme handlers should be used also for processing the items returned by `outputs`. The theme defines handlers to use specifically for rendering cells as content, while `outputs` is meant to extract values for further processing by the user, so in principle the theme is not used by `outputs` but this can be changed by setting `apply-theme: true`.

      For example, text outputs can contain ANSI escape codes used by terminals to colorize the text. A string with such codes can look full of gibberish. When a cell output with ANSI codes is rendered, the codes are converted to text styles. We can use `apply-theme` to get outputs with the same conversions done: 

      ```typst
      // Get the outputs of the first cell, transforming them through
      // the theme handlers.
      #outputs(0, apply-theme: true)
      ```

   - `theme`: the theme used for rendering content. This can be the name of a standard theme as string, or a theme dictionary (see [Themes](#Themes) for more information). Note that by default the theme has no effect for `outputs` (see `apply-theme` above).

- `render(..cell-args, input: true, output: true, h1-level: 1, gather-latex-defs: true, ansi: (:), theme: "notebook")`

   Renders selected cells in the Typst document. The `cell-args` are the same as for the `cells` function.

   Markdown cells will be converted to Typst content: Markdown headings to Typst headings, LaTeX equations to Typst equations, etc. By default, both the source and outputs of code cells will be rendered (in a style that depends on the selected theme), and raw cells will be rendered as simple raw blocks.

   -  `cell-args`: these are arguments that can be used to select cells as described for the `cells` function. Example:

      ```typst
      // Render all the Markdown cells
      #render(cell-type: "markdown")
      ```

   -  `input`: whether the input (source code) of code cells should be rendered. Example:

      ```typst
      // Render the first five cells without showing the source of code cells
      #render(range(5), input: false)
      ```

   -  `output`: whether the outputs of code cells should be rendered. Example:

      ```typst
      // Render the first five cells without showing the outputs of code cells
      #render(range(5), output: false)
      ```

   -  `h1-level`: the Typst heading level corresonding to top-level headings in the notebook. If set to 0, the top-level heading(s) in the notebook will be converted to `title` elements in Typst. Examples:

      ```typst
      // Render notebook with top-level headings shown as level 2, second-level
      // headings converted to level 3, etc.
      #render(h1-level: 2)

      // Render notebook with top-level heading converted to document title,
      // second-level headings converted to level 1, etc.
      #render(h1-level: 0)
      ```

   -  `gather-latex-defs`: whether all the LaTeX command definitions (of the form `\newcommand`) in the notebook should be gathered into into a single "preamble" to be used when rendering any part of the notebook.

      Jupyter allows defining a LaTeX command in an equation and using it in another equation (contrary to actual LaTeX, where a definition in some equation is local to that equation). This can cause difficulties during rendering in Callisto: the default LaTeX renderer (mitex) doesn't allow a command local to one equation to be used in another, and it can even happen that the user renders a single cell that uses a command that was defined in another. To address these issues, by default Callisto will gather all command definitions in a single preamble string, and when a math equation from a Markdown cell is rendered, any command definition found in the equation is removed (to avoid duplicate definitions) and the full preamble is inserted at the beginning. This whole processing can be disabled by setting `gather-latex-defs: false`.

   - `ansi`: how to process text that might contain ANSI escape sequences. More precisely, this setting affects every value that is processed through the `text-console-block` handler, which by default means the values of every stream, error and `text/plain` outputs. The default behavior is to look for escape sequences in the string. If none is found, the string is left untouched. If any is found, the string is processed into styled text. This processing also applies the `ansi.highlight-template` which tunes the text and highlight edges to have background colors and box-drawing characters connect nicely from one line to the next.

   - `theme`: the theme used for rendering content. This can be the name of a standard theme as string, or a theme dictionary (see [Themes](#Themes) for more information).

## Alias functions

The main functions have many aliases defined for convenience. Each alias corresponds to a call to a main function with some keyword arguments set to fixed values.

### Aliases for output type

-  The `outputs` function has aliases `displays`, `results`, `stream-items` and `errors` to select only a particular output type. Example:

   ```typst
   // Get the results of the first 10 cells
   #results(range(10))
   // Get all stream items from cell "A" and merge them in one text value
   #stream-items("A").join()
   ```

-  The `outputs` function has a `streams` alias similar to `stream-items`, but `streams` merges all selected streams that belong to the same cell, and always returns an item (possibly with an empty string as value) for each selected code cell. Example:

   ```typst
   // Get the stdout messages as one text value for each of cells 1, 3 and 5:
   #streams((1, 3, 5), stream: "stdout")
   ```

### Aliases for single values

The functions `sources` and `outputs` are in plural form: they always return an array of items. For convenience there is a singular alias defined for each plural form: the functions `cell`, `source`, `output`, `display`, `result`, `stream-item`, `error` and `stream` are the same as the plural form, except that they take an additional `item` keyword (defaulting to `"unique"`) and return always a single value. Example:

   ```typst
   // The first cell
   #cell(0)
   // The unique cell that matches "plot1"
   #cell("plot1")
   // The unique display item in the first cell's output
   #display(0)
   ```

The singular form is useful in two ways:

1. We're often interested in a single value (e.g. the result of one cell), but `results("plot1")` will return an array even if it contains only one element. It's nicer to write `result("plot1")` than `results("plot1").first()`. 

2. A call such as `result("plot1")` will check for us that there is only one item of "result" type that matches the "plot1" cell specification. If more than one is found, by default an error is raised.

The check for uniqueness can be disabled by setting the `item` argument to a value different from `"unique"`. Use for example `cell(..., item: 0)` to get the first matching cell, and `display(..., item: -1)` to get the last display of the matching cell(s).

Note that `keep` is always a filter on the results of the cell specification and can be used for plural as well as singular functions, while `item` is used to select which result is returned by a singular function. Both can be used together. Example:

```typst
// Second display of the first cell matching "plot1"
#display("plot1", keep: 0, item: 1)
```

However these functionalities overlap in the case of `cell`. Using both parameters rarely makes sense for this function.

### Aliases for rendering

The `render` function always returns a `content` value, but it also has an alias to check that only one cell matches the specification:

-  `Cell` is the same as `render` with `keep` set to `"unique"`. Example:

   ```typst
   // Render the unique cell matching "plot1"
   #Cell("plot1")
   ```

The `Cell` function itself has aliases to render only the input or output of a code cell:

-  `In` renders the input of one code cell,

-  `Out` renders the output of one code cell.

Example:

```typst
The following code:
#In(0)
produces the following figure:
#Out(0)
```

## Cell data and cell header

The lower-level `cells` function (and its `cell` alias) can be used to retrieve literal cell dicts reflecting the notebook JSON structure, with minimal processing applied:

-  A cell ID is generated if missing (this field is mandatory since nbformat 4.5).

-  An `index` field is added with the cell index in the notebook, starting at 0.

-  The cell source is normalized to be a simple string (nbformat also allows an array of strings).

-  For code cells, a **metadata header** is processed and removed if present: by default, if the first source lines are of the form `#| key: value` (optionally with whitespace between `#` and `|`), they are treated as metadata. The key-values pairs are added to the `cell.metadata.callisto.header` dictionary, and the header lines are removed from the cell source (unless `keep-cell-header` is set to `true`). For example, a code cell `c` containing the following source:

   ```
   #| label: plot1
   # | type: scatter
   scatter(x)
   ```

   will have the first two lines replaced by two entries in the cell dict: `c.metadata.callisto.header.label = "plot1"` and `c.metadata.callisto.header.type = "scatter"`.

   The format of header lines can be changed using the `cell-header-pattern` keyword.

Cell dicts can be used as a form of cell specification when calling functions such as `sources`, `outputs` or `render`. 


## Handlers

A handler is a function called to process a value such as: a cell's source, a cell output such as a PNG image, or even a whole cell. Each handler is associated with a "MIME type", which is really an arbitrary string used to identify the kind of value being processed. In the case of rich items, which can be available in multiple formats, the item is rendered by calling the handler on the selected format. In this case the type is a real MIME type, for example `image/png`. Other handlers use dummy MIME types such as `code-cell` (without slash character in the "MIME" string).

Handlers offer a powerful mechanism for customization. A particular value is typically processed in several steps by chaining calls to different handlers from more abstract to more concrete. This allows the theme or the user to plug in their code at the right step in the chain. 

The following handlers ("MIME types") are defined by default:

-  Handlers for output item data: `image/svg+xml`, `image/png`, `image/jpeg`, `image/gif`, `text/markdown`, `text/latex`, `text/plain`.

-  Handlers for output items
   - `rich-output-generic`: picks the best format and delegates to the corresponding data handler.
   - `display`: for display output.
   - `result`: for result output.
   - `error`: for error output.
   - `stream-generic`: for processing the actual stream content.
   - `stream-stdout`: for an "stdout" stream.
   - `stream-stderr`: for an "stderr" stream.
   - `stream-merged`: for a stream that merges "stdout" and "stderr".
   - `stream`: for any stream (called before the stream-specific handler).
   - `output`: for any output (called before `display`, `result`, `error` or `stream`).

-  Generic image handlers
   - `image-generic`: base handler used by others.
   - `image-base64`: for base64 encoded image.
   - `image-text`: for text-encoded images such as some SVGs.
   - `image-markdown`: for images in Markdown, which can refer to an external file or to an attachment (an image stored in the notebook itself).

-  Handlers for LaTeX math
   - `math-generic`: base handler for math.
   - `math-markdown`: for processing math in Markdown. This handler is responsible for inserting the "preamble" of all LaTeX command definitions found in the notebook (and removing existing definitions from the equation to avoid duplicate definitions).

-  Handlers for cell rendering
   - `raw-cell` for raw cells.
   - `markdown-cell`: for Markdown cells.
   - `code-cell-input`: for the source of code cells.
   - `code-cell-output`: for the output of code cells.
   - `code-cell`: for a whole code cell (this handler will generally call the handlers for `code-cell-input` and/or `code-cell-output`).
   - `cell`: for any type of cell (this handler will generally call the type-specific handler).

-  Other handlers
   - `markdown-generic`: for rendering Markdown (should return inline content).
   - `text-ansi-generic`: for rendering text with ANSI escape sequences.
   - `text-console-block`: for rendering text as console output, correctly handling ANSI escape sequences and adjusting text edges to have the background color and box-drawing characters connect nicely from one line to the next.
   - `source-code-generic`: for rendering source code (called by default handlers for code cell inputs an raw cells).
   - `attachment`: for items stored as attachment in the notebook.
   - `path`: for reading the content of files specified by path. Having the user set this handle gives Callisto permission to read any file under the project root.

Handlers with names ending in `-generic` are close to the bottom of the chain: they correspond to fairly concrete value types that need to be processed by several higher-level handlers.

Handlers are always called with a positional argument for the data to render, and a `ctx` keyword argument for contextual data (see [Handler context](#handler-context). Some handlers also take additional arguments:

- Image handlers must accept an `alt` argument.
- Math handlers must accept a `block` argument (`true` for block equations).
- The `source-code-generic` handler (used by the default raw cell and code input handlers) takes a `lang` argument.
- The `attachment` handler gets `metadata`, `type` and `subhandler-args` arguments.

When defining a handler, it is good practice to add an `..args` sink for possible extra arguments (especially as additional arugments might be introduced in a future version).

To call a particular handler from inside your own, use `callisto.handle`. For example, the default handler for raw cells is

```typst
#let raw-cell(cell, ctx: none, ..args) = handle(
 cell.source,
 mime: "source-code-generic",
 ctx: ctx,
 lang: ctx.raw-lang,
 ..args,
)
```

This simply delegates the processing of the cell source to the `source-code-generic` handler, while also setting the `lang` parameter to the notebooks "raw lang" (as configured by the user). The default `source-code-generic` handler is defined as

```typst
#let source-code-generic(txt, ctx: none, lang: none, ..args) = {
  // Ensure the source has at least one (possibly empty) line
  // (without this the raw block looks weird for empty cells)
  if txt == "" {
    txt = "\n"
  }
  raw(txt, lang: lang, block: true)
}
```

which renders the source as a raw block.

The "notebook" theme redefines the `raw-cell` handler to the following:

```typ
#let _raw-cell(cell, ctx: none) = block(
  spacing: 1.5em,
  width: 100%,
  inset: 0.5em,
  fill: luma(240),
  handle(cell.source, mime: "source-code-generic", ctx: ctx, lang: ctx.raw-lang),
)
```

This also calls the `source-code-generic` handler to process the cell source, but wraps the result in a block with light-gray background color.

### Handler configuration

When Callisto processes a particular value, which handler gets called is determined as follows:

- During rendering (when the user calls `render`, `Cell`, `In` or `Out`), the handlers defined by the theme replace the default handlers. For example the "plain" theme replaces the handlers `text/plain`, `stream-generic` and `error` (to convert ANSI escape sequences that might appear in these text messages into text styles).

- During other function calls (like `source` or `outputs`), the theme handlers are *not* used unless the user set `apply-theme: true`.

- The handlers defined by the user through `handlers` always take precedence.

### Handler context

A `ctx` dict is passed to all handler calls and holds resolved settings (replacing most `auto` values with resolved values) as well as contextual data including at least the following fields:

-  `cfg`: a dict with all the settings supported by callisto.config, using default values for settings not set by the user (this holds the non-resolved settings values).

-  `cell`: the dict of the cell being processed.

-  `item-desc`: a dict with information on the cell item (output item or attachment) being processed if any, or `none` otherwise. When not `none`, the
  dict contains at least the following fields:

   - `index`: the item index in the cell output list (`none` for attachments),

   - `type`: the output type, or `"attachment"` for attachments.

  For rich items, this dict contains also

   - `rich-format`: the format selected for this rich item.

   - `metadata`: the format-specific metadata if present, or the whole metadata dict associated with this item otherwise.

-  `latex-preamble`: a string with all the LaTeX command definitions (of the `\newcommmand` form) found in the notebook, or `none` if `gather-latex-defs` is `false`.


## Themes

A theme is simply a dictionary of handlers to be used in place of the default handlers during rendering (i.e. during calls to `render`, `Cell`, `In` or `Out`).

The theme dictionary can also include an additional field `template` to define a document template. This can be useful to maintain a cohesive style in documents that mix Typst-native content with notebook cells, or simply to separate global styles from element-specific styles. 

For example the "neat" theme defines a template function that changes the text font, increases some spacings and and styles raw elements. The template can be used as follows:

```typst
#let (template, render) = callisto.config(nb: json(...), theme: "neat")

#show: template

#render(...)
```

Here's the complete code for the "neat" theme (with the import paths adapted to work as user code):

```typst
#import "@preview/callisto:0.3.0"

#let _fill = rgb(233, 236, 239)
#let _inset = 8pt
#let _radius = 5pt
#let _extent = 3pt

#let _raw-block-cfg = (
  width: 100%,
  inset: _inset,
  radius: _radius,
  fill: _fill,
)

// Document template
#let _template(doc, set-fonts: true) = {
  set text(font: "Noto Sans") if set-fonts
  show raw: set text(font: "Noto Sans Mono") if set-fonts
  show heading: set text(weight: "semibold") if set-fonts

  show heading: set block(below: 1em)
  show heading.where(level: 1): set text(1.4em)
  show heading.where(level: 2): set text(1.2em)

  show raw.where(block: false): it => {
    let cfg = (fill: _fill, top-edge: 1em, bottom-edge: -0.4em)
    highlight(..cfg, radius: (left: _radius))[~#sym.wj]
    highlight(..cfg, extent: _extent, it)
    highlight(..cfg, radius: (right: _radius))[#sym.wj~]
  }

  show raw.where(block: true): set block(.._raw-block-cfg)

  show math.equation: set text(1.1em)

  doc
}

#let _code-cell-input(cell, ctx: none, ..args) = {
  let has-output = ctx.output and cell.outputs.len() > 0
  set text(rgb("#005979"))
  show raw: set block(.._raw-block-cfg, above: 1em)
  show raw: set block(below: 1em) if not has-output
  callisto.handle(
   cell.source,
   mime: "source-code-generic",
   ctx: ctx,
   lang: ctx.lang,
)
}

#let _code-cell-output(cell, ctx: none, ..args) = {
  let outs = callisto.outputs(cell, ..ctx.cfg, result: "value")
  if outs.len() == 0 { return }
  // Undo global show rule for raw block
  // (we don't want simple text outputs to be shown in rounded gray rects)
  show raw: set block(width: auto, inset: 0pt, radius: 0pt, fill: none)
  block(
    .._raw-block-cfg,
    fill: none,
    above: if ctx.input { 0pt } else { 1em },
    below: 1em,
    outs.join(),
  )
}

#let theme = callisto.themes.plain + (
  template: _template,
  code-cell-input: _code-cell-input,
  code-cell-output: _code-cell-output,
)
```
