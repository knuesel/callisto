# Tutorial: Importing code and outputs from Jupyter notebooks

Let's see how we can use Callisto to render a Jupyter notebook, or to extract the source and result of some computations for use in a Typst document. We will use the notebook [`example.ipynb`](example.ipynb). To compile the Typst examples yourself, you can download it and put it next to your Typst file.

(In the [next tutorial](Export-and-execution-tutorial.md) we will see how to write Python or other language code directly in the Typst document, and use Callisto to execute the code blocks through Jupyter.)

## Configuration

We start by importing the latest version of the package:

```typst
#import "@preview/callisto:0.3.0"
```

We can now call functions such as `callisto.render(nb: json("example.ipynb"))`, but it is more convenient to configure them to work with a particular notebook:

```typst
#let (render, Cell, In, Out) = callisto.config(nb: json("example.ipynb"))
```

However to support Markdown cells that reference external images (using Markdown such as `![](folder/image.png)` we must give Callisto a function that is allowed to read these files. This is done by specifying a "path" handler:

```typst
#let (render, Cell, In, Out) = callisto.config(
  nb: "example.ipynb",
  handlers: (path: (x, ..args) => read(x, encoding: none)),
)
```

(With this path handler, Callisto can also access the notebook file so we don't need to call the `json` function ourselves.)

The `config` call returns Callisto functions preconfigured with our settings. For a list of all functions (and their parameters) that can be configured with `config`, see the [function reference](Reference.md).

Here we only set the notebook, and from all the returned functions we only assign `render`, `Cell`, `In` and `Out`. Now let's use them!

## Rendering

We can render the whole notebook:

```typst
#render()
```

This *renders* the notebook; the cells are inserted in the Typst document:

-  Markdown cells are converted to formatted Typst content,

-  the source of each code cell is inserted as a Typst raw block,

-  the output of each code cell is inserted as a Typst image or text.


### Rendering specific cells

Instead of working with the whole notebook, we can refer to a single cell using its index (that is its position in the notebook):

```typst
This is the first cell, shown in a red box:
#block(stroke: red)[
   #render(0)
]

This is the second cell:
#render(1)
```

We can also select cells by "label": Code cells can start with a **header** that defines metadata, and this can be used to specify a cell label. A header line is a line of the form `#| key: value` (this pattern can be configured). Consider for example this cell source:

```python
#| label: plot3
#| type: lines
plt.plot([1, 2, 3, 4], [1, 4, 9, 16])
plt.show()
plt.plot([1, 2, 3, 4], [1, 3, 7, 3]);
```

When Callisto reads the notebook, it will remove the two header lines and set `label = "plot3"` and `type = "lines"` in the cell metadata (in a `callisto.header` dict).

We can render this particular cell using its label:

```typst
#render("plot3")
```

We can also select cells by *tags*. Tags are not very visible in the Jupyter interface, but in the example notebook all the cells that make plots have the `plots` tag, so we can do

```typst
// Render all cells with `plot` tag
#render("plots")
```

We can also specify multiple cells by position:

```typst
// Render the first 4 cells
#render(range(4))
```

Note: All the `render` calls above render cells from `example.ipynb`, but we can work with other notebooks at anytime, either by calling `config` again, or by overriding the configuration when we call a function, as in `#render(0, nb: json("other-notebook.ipynb"))`.

### Rendering a cell input or output

The functions `In` and `Out` can be used to render just the input or output of a particular code cell, while `Cell` will render both. We can now render the input and and output of `plot3` separately:

```typst
The following code:
#In("plot3")
produces the following figure:
#Out("plot3")
```

or together:

```typst
#Cell("plot3")
```

What's the difference then between `#render("plot3")` and `#Cell("plot3")`? The `Cell` call does an additional check: it raises an error if it finds more than one cell (or no cell) matching `"plot3"`.

Note: the functions `Cell`, `In` and `Out` are implemented as aliases of the `render` function. For example `In` is just the `render` function with argument `output` set to `false` and `keep` set to `"unique"`. See the [reference](Reference.md) for a description of all function arguments and all aliases.

## Item extraction

Let's say we want to extract some part of the notebook, like the source of one cell, or its output. For example we might want to:

* insert a piece of code or output at a specific place in the Typst document, or

* get an output (e.g. a string) from the notebook for further processing in Typst.

We will need other Callisto functions for that. Let's configure them:

```typst
#let (source, display, displays, result, output, outputs) = callisto.config(
   nb: json("example.ipynb"),
)
```

We can now get the source of the first cell:

```typst
#source(0)
```

That's a Markdown cell so we get the Markdown source as raw block (with `lang` set to `"markdown"`). Let's get the source of a code cell:

```typst
#source("plot1")
```

This gives a raw block with `lang` set to `"python"` since it's a notebook with a Python kernel. We could override this by calling `#source("plot1", lang: ...)` or setting `lang` directly in the `config` call.

Now let's get the output of this code cell:

```typst
#output("plot1")
```

Looking at the `callisto.config` call above, you might have noticed the `result` function. Let's try it:

```typst
// Doesn't work!
#result("plot1")
```

This doesn't work, because this cell has no result! In Jupyter, a code cell has a result only if the last line returns a value. Here the last line is `plt.show()`, which returns nothing. The cell still shows a plot, but it's another kind of output: a **display object**. Here the display object is created and updated by the various `plt` commands. The same cell can display many objects, but normally has only one result or none at all.

We can specifically request a "display" output using the `display` function:

```typst
#display("plot1")
```

The `plot2` cell produces both a display object and a result as outputs. We can get each of them:

```typst
#display("plot2")
#result("plot2")
```

If the distinction between display and result is confusing, the Jupyter interface can help us. A cell without result looks like this:

![Jupyter cell without result](cell-no-result.png)

There is an execution count `[1]` next the the source, but nothing next to the output.

A cell with result looks like this:

![Jupyter cell with result](cell-result.png)

The execution count `[2]` in red next to the value `1024` is a visual hint that `1024` is the cell result.

Now the `plot3` cell has two displays, and no result. What happens if we call `display` on it?

```typst
#display("plot3")
```

We get an error:

```
error: panicked with: "expected 1 item, found 2"
```

The `display` function expects only one item and complains if more (or zero) are found. Here the cell produces two displays. We can use the `displays` function to get all displays and pick one:

```typst
#displays("plot3").first() // first display
#displays("plot3").at(1)   // second display
```

A particular cell output can be of type `display`, `result`, `stream` or `error`. Each of these types has a corresponding Callisto function, and a plural counterpart: `displays`, `results`, `streams` and `errors`. In the common case where the cell produces one output and we don't care about the type, we can just use `output`:

```typst
#output("calc")  // returns the cell result
#output("plot1") // returns the cell display
```

The `plot2` cell has both a display and a result. We can get both as an array using the `outputs` function:

```typst
#outputs("plot2")
```

To insert each output in the document we could write `#outputs("plot2").join()`.


## More item extraction

Now let's try something more complicated: we want to get the last display or result produced by a cell. We can define our own function:

```typst
#let last-output(..args) = outputs(
  ..args,
  output-type: ("display_data", "execute_result",
).last()
```

Here we filter on the output type: we don't want stream items (messages written to `stdout` or `stderr`) or errors.

Let's try it on the `plot2` cell:

```typst
#last-output("plot2")
```

Excellent. Maybe we also want to customize the looks of a plot: show it centered, and resized to 75% of the text width. When Callisto returns a plot, it's in the form of a Typst `image` element, so we can change the width with a set rule:

```typst
#[
  #set image(width: 75%)
  #set align(center)
  #output("plot1")
]
```

Here we wrap the code in a `#[...]` block to limit the scope of the set rule, so that it doesn't affect other things in the document.

Another way to change the width would be to extract the image data from the `image` element, and use it to make a new `image` ourselves:

```typst
#let img-data = output("plot1").source
#let img = image(img-data, width: 75%)
#align(center, img)
```

Finally we might want to include a plot in a particular format. In a Jupyter notebook, the same cell output is often stored in multiple formats, to let the viewer choose their preferred one. For example a table can be stored as HTML which looks great for viewers that support it, while another copy is stored as plain text for other viewers.

In Callisto we can request a particular format using the `format` argument:

```typst
// Get the PNG version of this plot
#output("plot1", format: "image/png")
```

This will only work if the cell stores a PNG version of this item. We can also ask for PNG if available, and fall back to SVG otherwise:

```typst
// Get PNG if available, or SVG as fallback
#output("plot1", format: ("image/png", "image/svg+xml"))
```

When `format` is `auto`, a default order of preference is used: `("image/svg+xml", "image/png", "image/gif", "image/jpeg", "text/markdown", "text/latex", "text/plain")`. We can also use the special value `auto` as an element of the array; The default list will then be inserted at that position:

```typst
// Get PNG if available, otherwise use default order
#output("plot1", format: ("image/png", auto))
```

Note: we can specify any format we want with the `format` keyword, but there must be a matching handler function to process values of that format. We can register our own handlers with the `handlers` keyword, see the [reference](Reference.md).

### Using a cell's execution count

Instead of selecting code cells by label, we can use the *execution count*: as we know, when a cell is executed, Jupyter gives it a count shown as `[1]` or `[2]`. For example the `"plot1"` cell has execution count 2, and we can use it to identify the cell:

```typst
// Get "plot1" by execution count
#output(2, count: "execution")
```

If we want to do this a lot, we should make this behavior the default:

```typst
#let (render, result) = callisto.config(
   nb: json("example.ipynb"),
   count: "execution",
)
// Now 2 refers to the execution count
#render(2)
```

Note that the same cell will get a different count if it's executed again, and cells can be executed manually in any order so the order of execution counts might not reflect the position of cells in the document. And the execution count is defined only for code cells. For all these reasons, by default Callisto uses the cell index rather than its execution count.

For example, we might want to write Typst math in our Jupyter notebook, since the syntax is nicer than LaTeX. One way to do that is to write Typst formulas in raw cells, and use a theme that renders raw cells by evaluating their source as Typst markup:

```typst
#render(
  theme: callisto.themes.notebook + (
    raw-cell: (cell, ..args) => eval(cell.source, mode: "markup"),
  ),
)
```

Here we started with the "notebook" theme dictionary and added our own handler for raw cells. For more information on theming, see the [reference](Reference.md#Themes).

### Handlers

There's a lot we can configure with function parameters or in `callisto.config`, but advanced customization is done through *handlers*. Handlers are functions called by Callisto to process elements at various stages in the conversion/rendering pipeline.

For example, the `errors` function returns the errors produced by a cell. The notebook might store a full backtrace, but by default the Callisto `errors` returns only the short text of each error. We can change this by defining a custom `error` handler:

```typst
#let (errors,) = callisto.config(
  nb: json("example.ipynb"),
  handlers: (
    error: (item, ..args) => item.traceback.join("\n"),
  ),
)
```

This works but the backtrace is full of weird characters like `¤[0;31m`. These characters are [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code) used to colorize text in the terminal. If we want the actual text of the error, we can use `callisto.ansi.strip` to remove the escape codes: `callisto.ansi.strip(item.traceback.join("\n"))`.

## Themes

By default the cells are rendered with the "notebook" theme, which adds some styling to get a notebook look. We can choose the "neat" theme to get a cleaner look:

```typst
#render(theme: "neat")
```

There is also the "plain" theme which renders elements without any styling.

We can appy the theme globally in the `config` call with `callisto.config(nb: json("example.ipynb"), theme: "neat")`. This would affect all `render` calls.

We can also define our own theme. A theme is really a dictionary of handlers that are used in place of the default handlers when doing rendering. For example the "notebook" theme redefines the `error` handler a bit like in the previous section, but using the function `callisto.ansi.console-block` to render ANSI escape codes correctly (converting the codes to styles such as color and underline) and showing the whole thing in a red block.

Note that theme handlers are only used during rendering. So with the "notebook" theme for example, errors are shown with a backtrace in a red block when we call `render` or `Cell` or `Out`, which are all rendering functions, but the `output` or `error` functions will still return the short error string (unless the `apply-theme` parameter is explicitly set to `true`).

The standard theme dictionaries are available in `callisto.themes`. We can make a theme by extending one of these dictionaries. For example, let's say we want each cell rendered in a frame. In the [handler reference](Reference.md#Handlers) we see there is a `cell` handler called for each cell. The "neat" theme dict, available as `callisto.themes.neat`, has no `cell` field so Callisto will use the default function `callisto.handlers.cell`. Let's extend the "neat" theme with a `cell` handler that adds a frame: 

```typst
#render(
  theme: callisto.themes.neat + (
    cell: (c, ..args) => rect(
      width: 100%,
      callisto.handlers.cell(c, ..args), // render cell inside the frame
    ),
  ),
)
```
