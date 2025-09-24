#import "reading.typ": cell.cells
#import "common.typ": parse-main-args, handle
#import "ctx.typ": get-ctx

// Render the specified cells according to the settings (see common.typ)
#let render(..args) = {
  // Make sure the handlers are called with a context with result: "value"
  let (cell-spec, cfg) = parse-main-args(..args, result: "value")
  for cell in cells(..args) {
    handle(cell, mime: "cell", ctx: get-ctx(cell, cfg: cfg))
  }
}
