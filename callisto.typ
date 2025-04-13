// This file defines all the aliases of the main functions `cells`, `sources`,
// `outputs`, `render` and `streams`.

// It also pre-configures the `default-handlers` and `named-themes` parameters
// of all exposed functions (doing this here avoids circular import issues).

#import "themes/themes.typ"
#import "lib/common.typ"
#import "lib/reading.typ"
#import "lib/theming.typ"
#import "lib/rendering.typ"
#import "lib/handlers.typ"
#import "lib/exporting.typ"

#import common: handle

#let cells = reading.cell.cells.with(
  default-handlers: handlers.default,
  named-themes: themes.named,
)
#let cell(..args, keep: "unique") = {
  let (cell-spec, cfg) = parse-main-args(..args)
  if common.disabled(cfg: cfg) { return none }
  cells(..args, keep: keep).first()
}

#let outputs = reading.output.outputs.with(
  default-handlers: handlers.default,
  named-themes: themes.named,
)
#let output(..args, item: "unique") = common.single-item(
  outputs(..args),
  item: item,
)

#let displays(..args)     = outputs(..args, output-type: "display")
#let results(..args)      = outputs(..args, output-type: "result")
#let errors(..args)       = outputs(..args, output-type: "error")
#let stream-items(..args) = outputs(..args, output-type: "stream")

#let display(..args)     = output(..args, output-type: "display")
#let result(..args)      = output(..args, output-type: "result")
#let error(..args)       = output(..args, output-type: "error")
#let stream-item(..args) = output(..args, output-type: "stream")

#let streams = reading.stream.streams.with(
  default-handlers: handlers.default,
  named-themes: themes.named,
)
#let stream(..args, item: "unique") = common.single-item(
  streams(..args),
  item: item,
)

#let sources = reading.source.sources.with(
  default-handlers: handlers.default,
  named-themes: themes.named,
)
#let source(..args, item: "unique") = common.single-item(
  sources(..args),
  item: item,
)

#let render = rendering.render.with(
  default-handlers: handlers.default,
  named-themes: themes.named,
)
// Render a single cell
#let Cell(..args) = render(..args, keep: "unique")
// Render a single cell's input
#let In(..args) = Cell(..args, cell-type: "code", input: true, output: false)
// Render a single cell's output
#let Out(..args) = Cell(..args, cell-type: "code", input: false, output: true)

#let export = exporting.export.with(
  default-handlers: handlers.default,
  named-themes: themes.named,
)
#let make-notebook = exporting.make-notebook.with(
  default-handlers: handlers.default,
  named-themes: themes.named,
)

#let config(..args) = {
  if args.pos().len() > 0 {
    panic("unexpected positional argument(s): " + repr(args.pos()))
  }
  // Validate named arguments
  let (cfg,) = common.parse-main-args(..args)
  return (
    template: theming.resolve(cfg.theme, cfg.named-themes).template,
    cells:          cells         .with(..args),
    cell:           cell          .with(..args),
    outputs:        outputs       .with(..args),
    output:         output        .with(..args),
    displays:       displays      .with(..args),
    display:        display       .with(..args),
    results:        results       .with(..args),
    result:         result        .with(..args),
    stream-items:   stream-items  .with(..args),
    stream-item:    stream-item   .with(..args),
    errors:         errors        .with(..args),
    error:          error         .with(..args),
    streams:        streams       .with(..args),
    stream:         stream        .with(..args),
    sources:        sources       .with(..args),
    source:         source        .with(..args),
    render:         render        .with(..args),
    Cell:           Cell          .with(..args),
    In:             In            .with(..args),
    Out:            Out           .with(..args),
    export:         export        .with(..args),
    make-notebook:  make-notebook .with(..args),
  )
}
// Preconfigure named-themes in a way that they are included in
// the 'args' of the above config definition, and without introducing another
// exported binding in this module.
#let config = config.with(named-themes: themes.named)
