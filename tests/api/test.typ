#import "/callisto.typ"
#import "/lib/ctx/cells.typ": resolve-header-pattern

// With julia.ipynb
#let (
  cells,
  cell,
  error,
  results,
  result,
  display,
  source,
  output,
  Out,
) = callisto.config(nb: json("/tests/julia/julia.ipynb"))

// Check for cell deduplication
#assert.eq(cells((..range(2), 0)).len(), 2)

// Check that cell type is considered for literal cells mixed with other cell specs
#assert.eq(cells((0, cell(0)), cell-type: "code").len(), 0)

// Test cell-header-pattern
#let strict-header-pattern = (regex: regex("^#\|\s+(.*?):\s+(.*?)\s*$"), writer: none) // doesn't allow space between `#` and `|`
#let cell-spec = arguments("pattern-test", name-path: "metadata.callisto.header.name")
#assert.eq(cells(..cell-spec).len(), 1)
#assert.eq(cells(..cell-spec, cell-header-pattern: strict-header-pattern).len(), 0)
#let cpp-pattern = (regex: regex("^//\|\s+(.*?):\s+(.*?)\s*$"), writer: none)
#let cpp-cell-spec = arguments("calc", nb: json("/tests/api/cpp.ipynb"))
#assert.eq(cells(..cpp-cell-spec).len(), 0)
#assert.eq(cells(..cpp-cell-spec, cell-header-pattern: cpp-pattern).len(), 1)

// Test keep-cell-header
#assert.eq(source("plot3").text.split("\n").first(), "a = 2")
#assert.eq(source("plot3", keep-cell-header: true).text.split("\n").first(), "#| label: plot3")
// Test header-text field in cell metadata
#assert.eq(cell("plot3").metadata.callisto.header-text.split("\n").first(), "#| label: plot3")

#assert("`aa` not defined" in error())

#assert.eq(
  catch(() => display("plots", name-path: "metadata.callisto.header.name", format: "x")),
  "panicked with: \"no matching item found\"",
)
#assert.eq(
  catch(() => display("plots", name-path: "metadata.callisto.header.name", format: "x", ignore-wrong-format: true)),
  "panicked with: \"no matching item found\"",
)

// Tests for 'keep' and 'item'
#assert.eq(
  catch(() => Out("non-existing")),
  "panicked with: \"expected 1 cell, found 0\"",
)
#{
  let (output,) = callisto.config(nb: json("/tests/julia/julia.ipynb"), item: 4)
  assert.eq(output("plot3"), "5")
}

#assert.eq(results(c => c.execution_count > 3).len(), 2)

#assert.eq(result("plot3", result: "dict").data, "5")
#assert.eq(result("plot3"), "5")

#assert.eq(display("plot3", item: 0).func(), image)

#assert.eq(display("scatter", name-path: "metadata.callisto.header.type", item: 1).func(), image)

// Check override of a single handler by theme name
#let out = error(
  5,
  theme: callisto.themes.plain + (
    error: "notebook",
  ),
  apply-theme: true,
)
#assert("Stacktrace" in out.body.text)

// Allow multiple items in singular functions, pick the first
#[
  #let (display, result) = callisto.config(nb: json("../julia/julia.ipynb"), item: 0)
  #assert.eq(display("plot3").func(), image)
  #assert.eq(result("scatter", name-path: "metadata.callisto.header.type", theme: "plain").func(), image)
]


// With python.ipynb
#let (
  cells,
  cell,
  streams,
  stream-items,
  stream-item,
  output,
  outputs,
) = callisto.config(nb: json("/tests/python/python.ipynb"))


#assert.eq(cells(cell-type: "markdown").len(), 2)

#assert.eq(cell("19cdb152-021b-4811-83de-3610ec97fc5b").index, 3)

#assert.eq(streams(result: "dict").map(x => x.cell.index), (3, 4, 6))
#assert.eq(
  streams((4, 5)),
  ("Error 1\nMessage 1\nError 2\nMessage 2\n",),
)
#assert.eq(
  stream-items(4, result: "dict").map(x => x.name),
  ("stderr", "stdout", "stderr", "stdout"),
)
#assert.eq(stream-item(4, stream: "stderr", item: -1), "Error 2\n")

// Dict result fields
#let out = output(6, item: 2, result: "dict")
#assert.eq(out.metadata.a, "x")
#assert.eq(out.index, 2)
#assert.eq(out.type, "display")
#assert.eq(out.rich-format, "image/png")

// ctx.item-desc fields
#let out = output(
  6,
  item: 2,
  result: "dict",
  handlers: ("image/png": (ctx: none, ..args) => ctx.item-desc),
)
#assert.eq(out.index, 2)
#assert.eq(out.type, "display")
#assert.eq(out.rich-format, "image/png")

// check that none handlers work
#assert.eq(outputs(6, handlers: ("image/png": none)).len(), 2)
#assert.eq(output(6, item: 2, handlers: (
  "image/png": (none, (data, ..args) => block(data)),
)), block(none))

// check that unknown handlers don't work
#let handlers = (
  "custom": (..args) => square(stroke: red),
  "image/png": callisto.handle.with(mime: "custom"),
)
#assert(catch(() => outputs(handlers: handlers)).starts-with(
    "panicked with: \"unknown handler \\\"custom\\\""
))

// check that custom handlers work if registered
#let out = output(
  6,
  item: 2,
  default-handlers: callisto.handlers.default + ("custom": none),
  handlers: (
    "custom": (..args) => square(stroke: red),
    "image/png": callisto.handle.with(mime: "custom"),
  ),
)
#assert.eq(out.func(), square)

// Check header pattern logic for OCaml syntax
#let pat = "(* %key: %value *)"
#let (regex: pat-regex, writer: pat-writer) = resolve-header-pattern(pat)
#let header-line = "(* some key: some value *)   "
#assert.eq(header-line.match(pat-regex).captures, ("some key", "some value"))
#assert.eq(
  (pat-writer)("some key", "some value"),
  "(* some key: some value *)"),
)

// Check latex definition processing for literal cell
#let my-cell = (
  cell_type: "markdown",
  id: "a",
  metadata: (callisto: (header: (:))),
  source: ```
$$
  \newcommand{\AA}{A}
  \newcommand{\BB}[1]{B(#1)}
  \newcommand{\CC}{C}
  \newcommand{\AA}{A}
  \AA\BB{x}\CC
$$
```.text
)
#assert.eq(callisto.render(my-cell).children.at(1).func(), math.equation)


// Check cell header functionality
#let (Cell,) = callisto.config(nb: json("/tests/cell-header/cell-header.ipynb"), theme: "plain")
#assert.eq(Cell("only-input").text, "10 + 1")
#assert.eq(Cell("only-output").text, "12")
