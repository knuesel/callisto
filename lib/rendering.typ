#import "reading/cell.typ": cells
#import "util.typ": handle
#import "config.typ": parse-main-args, disabled
#import "ctx/ctx.typ": get-ctx

// Render the specified cells according to the settings (see common.typ).
// By default this function does apply the style.
#let render(..args, apply-style: true) = {
  // Make sure the handlers are called with a context with result: "value"
  let (cell-spec, cfg) = parse-main-args(
    ..args,
    apply-style: apply-style,
    result: "value",
  )
  if disabled(cfg: cfg) { return none }
  for cell in cells(..args) {
    handle(cell, mime: "cell", ctx: get-ctx(cell, cfg: cfg))
  }
}
