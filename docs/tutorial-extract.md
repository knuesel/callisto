# Tutorial 2: Extracting Items from Notebooks

To follow this tutorial, download [`example.ipynb`](example.ipynb) and place it next to your Typst file.

Let's say we want to extract some part of the notebook. For example, the `plot1` cell imports Matplotlib and produces one plot, and `plot2` produces two output items: the text value `"1024"` and a plot. We want to

* Check if the source of the `plot1` cell contains the word `"matplotlib"`.

* Insert the `plot2` plot at a specific place in the Typst document.

* Get the text value for further processing in Typst.

We will need new Callisto functions for that. Let's configure them:

```typst
#import "@preview/callisto:0.3.0"

#let (source, display, result, output, outputs) = callisto.config(
   nb: path("example.ipynb"),
)
```

## Source Extraction

Let's get the source of the `plot1` cell:

```typst
#source("plot1")
```

This gives us a raw block with `lang` set to `python` (it's a Python notebook). The source itself can be accessed through the `text` field:

```typst
#source("plot1").text.contains("matplotlib")
```

We can also get the source of Markdown cells and raw cells:

```typst
// Returns a raw block with lang: "markdown"
#source(0)
```

## Output Item Extraction

Now let's get the plot produced by the `plot1` cell:

```typst
#output("plot1")
```

Looking at the `callisto.config` call above, you might have noticed the `result` function. Let's try it:

```typst
// Doesn't work
#result("plot1")
```

This doesn't work, because this cell has no result! In Jupyter, a code cell has a result only if the last line returns a value. Here the last line is `plt.show()`, which returns nothing. The cell still shows a plot, but it's another kind of output item: a **display** item. Here the display item is created and updated by the various `plt` commands. The same cell can display many items, but normally has only one result or none at all.

We can specifically request a "display" output item using the `display` function:

```typst
#display("plot1")
```

The `plot2` cell produces a plot as display item and a string as result. We can get each of them:

```typst
#display("plot2")
#result("plot2")
```

## Output Item Types

If the distinction between display and result is confusing, the Jupyter interface can help us. A cell without result looks like this:

<img src="cell-no-result.png" alt="Jupyter cell without result" width=450>

There is an execution count `[1]` next to the source, but nothing next to the output.

A cell with result looks like this:

<img src="cell-result.png" alt="Jupyter cell with result" width=400>

The execution count `[2]` in red next to the value `1024` is a visual hint that `1024` is the cell result.

The possible output types are `display`, `result`, `stream` and `error`. Each of these types has a corresponding Callisto function. There is additionally the function `full-stream`: while `stream` returns a single stream item produced by a cell (that is one text message written on the "standard output" or "standard error"), `full-stream` gathers all stream items into one value.

In the common case where the cell produces one output and we don't care about the type, we can just use `output`:

```typst
#output("calc")
#output("plot1")
```

## Why not just `Out` ?

Why use `output`, `display`, etc. when `Out` also gives a cell's output?
`Out` renders the whole cell output, and depending on the selected [theme](#Themes) it can return complex content that includes much more than the output items. With `output` and friends we can get a single item in a predictable format: for example `display("plot2")` returns an `image` element and `result("plot2")` returns an `str` value.

The way this works is that theme handlers are only used during rendering. So with the "notebook" theme for example, errors are shown with a backtrace in a red block when we call `render` or `Cell` or `Out`, which are all rendering functions, but the `output` and `error` functions will still return the short error string (unless the [`apply-theme`](callisto-manual.pdf#nameddest=setting:apply-theme) setting is explicitly set to `true`).


## Dealing with Multiple Output Items

The `output` function retrieves and returns a single item. The `plot2` cell however has two outputs. What happens if we call `output` on it?

```typst
#output("plot2")
```

We get an error:

```
error: panicked with: expected 1 item, found 2. Cell spec was "plot2"
```

We can pick one of the outputs with the `item` setting:

```typst
#output("plot2", item: 0) // first item
#output("plot2", item: 1) // second item
```

To get several items from one call we can use the "plural" version `outputs`:

```typst
#outputs("plot2")
```

This function always returns an array, here with two elements: the string `"1024"` and the plot image. To insert both outputs in the document we could write `#outputs("plot2").join()`.

Each "singular" function like `source` and `result` has a plural counterpart (`sources`, `results`, ...) that returns an array of values and doesn't complain if zero or several items are found.

## More Complex Operations

Now let's try something more complicated: we want to get the last display or result produced by a cell. We can configure our own function to do just that:

```typst
#let last-output = output.with(
  output-type: ("display", "result"),
  item: -1,
)
```

This takes the `output` function and "pre-applies" some arguments: we filter on the output type (we don't want streams or errors) and from all the matching items we pick the last one.
Now writing for example `#last-output("plot2")` will return the plot produced by the `plot2` cell, since it's the last item.

Maybe we also want to customize the looks of a plot: show it centered, and resized to 75% of the text width. When Callisto returns a plot, it's in the form of a Typst `image` element, so we can change the width with a set rule:

```typst
#[
  #set image(width: 75%)
  #set align(center)
  #output("plot1")
]
```

Here we wrap the code in `#[...]` to limit the scope of the set rule, so that it doesn't affect other things in the document. Another way to change the width would be to extract the image data from the `image` element, and use it to make a new `image` ourselves:

```typst
#let img-data = output("plot1").source
#let img = image(img-data, width: 75%)
#align(center, img)
```

## Selecting the Item Format (PNG, SVG...)

In a Jupyter notebook, the same cell output is often stored in multiple formats, to let the viewer choose their preferred one. For example a table can be stored as HTML which looks great for viewers that support it, while another copy is stored as plain text for other viewers. Or a plot image can be stored in both SVG and PNG.

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

When `format` is `auto`, the following order of preference is used (with preferred formats listed first):

```
"text/vnd.typst"
"image/svg+xml"
"image/png"
"image/jpeg"
"image/gif"
"text/markdown"
"text/latex"
"text/html"
"text/plain"
"application/json"
```

We can also use the special value `auto` as an element of the array; The default list will then be inserted at that position:

```typst
// Get PNG if available, otherwise use default order
#output("plot1", format: ("image/png", auto))
```

Every value given in `format` must have a matching handler function to process values of that format. To add support for a new format we can register our own handlers with the `new-handlers` setting, see the [reference manual](callisto-manual.pdf#nameddest=setting:new-handlers).

## Producing Typst code from Notebook Cells

You might have noticed that the first format in the list above is `text/vnd.typst`. That's the MIME type for Typst source code. The default handler for this format evaluates the value as Typst markup.

The `typst-markup` cell shows how a Python notebook can generate an output of this type:

```py
#| label: typst-markup
from IPython.display import display

typst_code = """
= Basel Problem

$ sum_(i=1)^oo = pi^2/6 $
"""

display({
    'text/vnd.typst': typst_code,
    'text/plain': '<Typst Document>'
}, raw=True)
```

This `display` call generates an output item with two formats: Typst markup and a `text/plain` placeholder. Including a `text/plain` placeholder is good practice so that notebook viewers can show something meaningful if they don't know how to render Typst source code.

An `output` call will include the evaluated markup in our document:

```typ
#output("typst-markup")
```

## Getting Arbitrary Values from Notebook Cells

Cell outputs are generally stored either as images or text. For example the `calc` cell which computes 2+2 stores the result `"4"` as string:

```typst
#type(output("calc"))
```

However `IPython.display.JSON` we be used to produce an output item in the JSON format. We can encode pretty much anything as JSON so that's a powerful way to transfer data from Python to Typst. See for exampe the `json-result` cell:

```py
#| label: json-result
from IPython.display import display, JSON
some_dict = {
  'a': 0,
  's': 'some string',
}
JSON(some_dict)
```

The notebook stores the JSON value under the MIME type `application/json`, and an uninformative description `"<IPython.core.display.JSON object>"` under the MIME type `text/plain`. By default the `text/plain` value has priority. To get the JSON we can request it explicitly:

```typst
#output("json-result", format: "application/json")
```

We can also redefine the priority to always take the JSON value if available:

```typst
#let (output,) = callisto.config(
  nb: path("example.ipynb"),
  format: ("application/json", auto),
)
#output("json-result")
```

## Next

In the [next tutorial](tutorial-export.md) we will see how code blocks in Python (or other languages) written directly in the Typst file can be executed through Jupyter, to have the execution result included in the document.




