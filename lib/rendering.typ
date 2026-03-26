#import "reading/cell.typ": cells
#import "util.typ": handle
#import "config.typ": parse-main-args, read-enabled
#import "ctx/ctx.typ": get-ctx

// Render the specified cells according to the settings (see common.typ).
// By default this function does apply the theme.
#let render(..args, apply-theme: true) = {
  // Make sure the handlers are called with a context with result: "value"
  let (cell-spec, cfg) = parse-main-args(
    ..args,
    apply-theme: apply-theme,
    result: "value",
  )
  if read-enabled(cfg: cfg) == false { return none }
  for cell in cells(..args) {
    handle(cell, mime: "cell", ctx: get-ctx(cell, cfg: cfg))
  }
}
