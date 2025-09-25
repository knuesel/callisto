#import "reading.typ": cell.cells
#import "common.typ": parse-main-args, handle
#import "ctx.typ": get-ctx

// Render the specified cells according to the settings (see common.typ).
// By default this function does apply the theme.
#let render(..args, apply-theme: true) = {
  // Make sure the handlers are called with a context with result: "value"
  let (cell-spec, cfg) = parse-main-args(
    ..args,
    apply-theme: apply-theme,
    result: "value",
  )
  for cell in cells(..args) {
    handle(cell, mime: "cell", ctx: get-ctx(cell, cfg: cfg))
  }
}
