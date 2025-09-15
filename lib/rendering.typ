#import "reading.typ": cell.cells
#import "common.typ": parse-main-args, handle
#import "ctx.typ": get-ctx

// Render the specified cells according to the settings (see common.typ)
#let render(..args) = {
  let (cell-spec, cfg) = parse-main-args(args)
  for cell in cells(..args) {
    handle(cell, mime: "cell", ctx: get-ctx(cell, cfg: cfg))
  }
}
