#import "/callisto.typ"
#import "/core/handlers.typ"
#import "/core/header-pattern.typ"

// With julia.ipynb
#let (
  cells,
  cell,
  errors,
  error,
  results,
  result,
  displays,
  display,
  sources,
  source,
  streams,
  stream,
  full-streams,
  full-stream,
  outputs,
  output,
  render,
  Cell,
  In,
  Out,
) = callisto.config(nb: path("/tests/julia/julia.ipynb"))

// Check that all functions work without error
#assert.ne(cells(0), none)
#assert.ne(cell(0), none)
#assert.ne(errors(0), none)
#assert.ne(error(item: 0), none)
#assert.ne(results(0), none)
#assert.ne(result(item: 0), none)
#assert.ne(displays(0), none)
#assert.ne(display(item: 0), none)
#assert.ne(sources(0), none)
#assert.ne(source(0), none)
#assert.ne(streams(0), none)
#assert.ne(stream(item: 0), none)
#assert.ne(full-streams(0), none)
#assert.ne(full-stream(item: 0), none)
#assert.ne(outputs(0), none)
#assert.ne(output(item: 0), none)
#assert.ne(render(0), none)
#assert.ne(Cell(0), none)
#assert.ne(In(2), none)
#assert.ne(Out(2), none)

// Check for cell deduplication
#assert.eq(cells((..range(2), 0)).len(), 2)

// Check that cell type is considered for literal cells mixed with other cell specs
#assert.eq(cells((0, cell(0)), cell-type: "code").len(), 0)

// Test cell-header-pattern
#let strict-header-pattern = (regex: regex("^#\|\s+(.*?):\s+(.*?)\s*$")) // doesn't allow space between `#` and `|`
#let cell-spec = arguments("pattern-test", name-path: "metadata.callisto.header.name")
#assert.eq(cells(..cell-spec).len(), 1)
#assert.eq(cells(..cell-spec, cell-header-pattern: strict-header-pattern).len(), 0)
#let cpp-pattern = (regex: regex("^//\|\s+(.*?):\s+(.*?)\s*$"))
#let cpp-cell-spec = arguments("calc", nb: path("/tests/api/cpp.ipynb"))
#assert.eq(cells(..cpp-cell-spec).len(), 0)
#assert.eq(cells(..cpp-cell-spec, cell-header-pattern: cpp-pattern).len(), 1)

#let src = "#| label: x\na = 2"
// header-pattern.parse-text
#assert.eq(header-pattern.parse-text(src, pattern: auto), (header: (label: "x"), code: "a = 2"))
// In absence of regex
#assert.eq(header-pattern.parse-text(src, pattern: none), (header: (:), code: src))
// make-text
#assert.eq(header-pattern.make-text((label: "x"), pattern: auto), "# | label: x\n")

// Test keep-cell-header
#assert.eq(source("plot3").text.split("\n").first(), "a = 2")
#assert.eq(source("plot3", keep-cell-header: true).text.split("\n").first(), "#| label: plot3")
// Test code field in cell metadata
#assert.eq(cell("plot3").metadata.callisto.code.split("\n").first(), "a = 2")
// Test header field in cell metadata
#assert.eq(cell("plot3").metadata.callisto.header.type, "scatter")


// Test placeholders and other missing values
#assert.eq(output("no-such-cell", placeholder: [x]), [x])
#assert.eq(output("no-such-cell", handlers: (placeholder-output: (..args) => [x]), placeholder: true), [x])
#assert("expected 1 cell" in catch(() => cell("no-such-cell")))
#assert("expected 1 cell" in catch(() => source("no-such-cell")))
#assert("expected 1 cell" in catch(() => Out("no-such-cell")))

// Invalid index doesn't panic
#assert.eq(cells(range(20)).len(), 9)
// Negative index works
#assert.ne(cell(-1), none)

#assert("`aa` not defined" in error())

#assert(
  "no matching item found" in
    catch(() => display("plots", name-path: "metadata.callisto.header.name", format: "x"))
)
#assert(
  "no matching item found" in
    catch(() => display("plots", name-path: "metadata.callisto.header.name", format: "x", ignore-wrong-format: true))
)

// Tests for 'item'
#{
  let (output,) = callisto.config(nb: path("/tests/julia/julia.ipynb"), item: 4)
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
#assert("Stacktrace" in out.body.child.text)

// Allow multiple items in singular functions, pick the first
#[
  #let (display, result) = callisto.config(nb: path("../julia/julia.ipynb"), item: 0)
  #assert.eq(display("plot3").func(), image)
  #assert.eq(result("scatter", name-path: "metadata.callisto.header.type", theme: "plain").func(), image)
]


// With python.ipynb
#let (
  cells,
  cell,
  full-streams,
  full-stream,
  streams,
  stream,
  output,
  outputs,
) = callisto.config(nb: path("/tests/python/python.ipynb"))


#assert.eq(cells(cell-type: "markdown").len(), 2)

#assert.eq(cell("19cdb152-021b-4811-83de-3610ec97fc5b").index, 3)

#assert.eq(full-streams(result: "dict").map(x => x.cell.index), (3, 4, 6))
#assert.eq(
  full-stream((4, 5)),
  "Error 1\nMessage 1\nError 2\nMessage 2\n",
)
#assert.eq(
  full-streams((3, 4)),
  (
    "Message 1\nMessage 2\nError 1\nError 2\n",
    "Error 1\nMessage 1\nError 2\nMessage 2\n",
  ),
)
#assert.eq(
  streams(4, result: "dict").map(x => x.name),
  ("stderr", "stdout", "stderr", "stdout"),
)
#assert.eq(stream(4, stream: "stderr", item: -1), "Error 2\n")

// Dict result fields
#let out = output(6, item: 2, result: "dict")
#assert.eq(out.metadata.a, "x")
#assert.eq(out.index, 2)
#assert.eq(out.type, "display")
#assert.eq(out.format, "image/png")

// ctx.item-desc fields
#let out = output(
  6,
  item: 2,
  result: "dict",
  handlers: ("image/png": (ctx: none, ..args) => ctx.item-desc),
)
#assert.eq(out.metadata.a, "x")
#assert.eq(out.index, 2)
#assert.eq(out.type, "display")
#assert.eq(out.format, "image/png")

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
    "panicked with: unknown handler \"custom\""
))

// check custom handlers
#let out = output(
  6,
  item: 2,
  handlers: (
    "image/png": callisto.handle.with(mime: "custom"),
  ),
  new-handlers: (
    custom: (..args) => square(stroke: red),
  ),
)
#assert.eq(out.func(), square)

// Check header pattern logic for OCaml syntax
#let pat = "(* %key: %value *)"
#let (regex: pat-regex, writer: pat-writer) = header-pattern.resolve(pat)
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
#let my-nb = (cells: (my-cell,), metadata: (:), nbformat: 4, nbformat_minor: 5)
#assert.eq(callisto.render(my-cell, nb: my-nb).children.at(1).func(), math.equation)

// Check cell header functionality
#let (Cell,) = callisto.config(nb: path("cell-header.ipynb"), theme: "plain")
#assert.eq(Cell("only-input").text, "10 + 1")
#assert.eq(Cell("only-output").text, "12")

// Custom header parsing
#let caption-handler(it, ctx: none) = {
  let header = ctx.cell.metadata.callisto.header
  if "caption" in header {
    figure(kind: image, caption: header.caption, it)
  } else {
    it
  }
}
#let (render,) = callisto.config(
  nb: path("cell-header.ipynb"),
  theme: "neat",
  handlers: (code-cell-output: (auto, caption-handler)),
)
#assert.eq(render("caption-test").caption.body, [My Caption])


// Cell that produces Typst value
#let o = callisto.output("typst-markup", nb: path("/docs/example.ipynb"))
#let elem-funcs = o.children.map(x => x.func())
#assert(heading in elem-funcs)
#assert(math.equation in elem-funcs)
