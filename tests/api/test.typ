#import "/src/callisto.typ"

// Preferred format among `xyz`, `text/plain`, `abc`
#assert.eq(
  callisto.reading.pick-format(("xyz", "text/plain", "abc")),
  "text/plain",
)

// Same with `precedence: ("abc", "text/plain")`
#assert.eq(
  callisto.reading.pick-format(
    ("xyz", "text/plain", "abc"),
    precedence: ("abc", "text/plain"),
  ),
  "abc",
)

// With julia.ipynb
#let (
  cells,
  cell,
  error,
  results,
  result,
  display,
  source,
) = callisto.config(nb: "/tests/julia/julia.ipynb")

// Check for cell deduplication
#assert.eq(cells((..range(2), 0)).len(), 2)

// Check that cell type is considered for literal cells mixed with other cell specs
#assert.eq(cells((0, cell(0)), cell-type: "code").len(), 0)

// Test cell-header-pattern
#let strict-header-pattern = regex("^#\|\s+(.*?):\s+(.*?)\s*$") // doesn't allow space between `#` and `|`
#let cell-spec = arguments("pattern-test", name-path: "metadata.name")
#assert.eq(cells(..cell-spec).len(), 1)
#assert.eq(cells(..cell-spec, cell-header-pattern: strict-header-pattern).len(), 0)
#let cpp-pattern = regex("^//\|\s+(.*?):\s+(.*?)\s*$")
#let cpp-cell-spec = arguments("calc", nb: "/tests/markdown-images/Cpp.ipynb")
#assert.eq(cells(..cpp-cell-spec).len(), 0)
#assert.eq(cells(..cpp-cell-spec, cell-header-pattern: cpp-pattern).len(), 1)

// Test keep-cell-header
#assert.eq(source("plot3").text.split("\n").first(), "a = 2")
#assert.eq(source("plot3", keep-cell-header: true).text.split("\n").first(), "#| label: plot3")

#assert("`aa` not defined" in error(result: "dict").value)

#assert.eq(
  catch(() => display("plots", name-path: "metadata.name", format: "x")),
  "panicked with: \"No matching item found\"",
)
#assert.eq(
  catch(() => display("plots", name-path: "metadata.name", format: "x", ignore-wrong-format: true)),
  "panicked with: \"No matching item found\"",
)

#assert.eq(results(c => c.execution_count > 3).len(), 2)

#assert.eq(result("plot3"), "5")

#assert.eq(display("plot3", item: 0).func(), image)

#assert.eq(display("scatter", name-path: "metadata.type", item: 1).func(), image)

// Allow multiple items in singular functions, pick the first
#[
  #let (display, result) = callisto.config(nb: json("../julia/julia.ipynb"), item: 0)
  #assert.eq(display("plot3").func(), image)
  #assert.eq(result("scatter", name-path: "metadata.type").func(), image)
]

// With python.ipynb
#let (
  cells,
  cell,
  streams,
  stream-items,
  stream-item,
) = callisto.config(nb: "/tests/python/python.ipynb")


#assert.eq(cells(cell-type: "markdown").len(), 2)

#assert.eq(cell("19cdb152-021b-4811-83de-3610ec97fc5b").index, 3)

#assert.eq(streams(result: "dict").map(x => x.cell.index), (1, 3, 4, 5, 6))
#assert.eq(
  streams((4, 5), result: "dict").map(x => x.value),
  ("Error 1\nMessage 1\nError 2\nMessage 2\n", ""),
)
#assert.eq(
  stream-items(4, result: "dict").map(x => x.name),
  ("stderr", "stdout", "stderr", "stdout"),
)
#assert.eq(stream-item(4, stream: "stderr", item: -1), "Error 2\n")
