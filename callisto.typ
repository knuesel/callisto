// This file defines all the aliases of the main functions `cells`, `sources`,
// `outputs`, `render` and `streams`.

// It also pre-configures the `default-handlers` and `named-styles` parameters
// of all exposed functions (doing this here avoids circular import issues).

#import "styles/styles.typ"
#import "lib/config.typ": parse-main-args
#import "lib/util.typ"
#import "lib/reading/reading.typ"
#import "lib/styling.typ"
#import "lib/rendering.typ"
#import "lib/handlers.typ"
#import "lib/exporting.typ"

#import util: handle

#let cells = reading.cell.cells.with(
  default-handlers: handlers.default,
  named-styles: styles.named,
)
#let cell(..args) = reading.single-item(cells, args)

#let outputs = reading.output.outputs.with(
  default-handlers: handlers.default,
  named-styles: styles.named,
)
#let output(..args) = reading.single-item(outputs, args)

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
  named-styles: styles.named,
)
#let stream(..args) = reading.single-item(streams, args)

#let sources = reading.source.sources.with(
  default-handlers: handlers.default,
  named-styles: styles.named,
)
#let source(..args) = reading.single-item(sources, args)

#let render = rendering.render.with(
  default-handlers: handlers.default,
  named-styles: styles.named,
)
// Render a single cell. The `keep` value is enforced.
#let Cell(..args) = render(..args, keep: "unique")
// Render a single cell's input
#let In(..args) = Cell(..args, cell-type: "code", input: true, output: false)
// Render a single cell's output
#let Out(..args) = Cell(..args, cell-type: "code", input: false, output: true)

#let export = exporting.export.with(
  default-handlers: handlers.default,
  named-styles: styles.named,
)
#let make-notebook = exporting.make-notebook.with(
  default-handlers: handlers.default,
  named-styles: styles.named,
)
#let stage-notebook = exporting.stage-notebook.with(
  default-handlers: handlers.default,
  named-styles: styles.named,
)

#let config(..args) = {
  if args.pos().len() > 0 {
    panic("unexpected positional argument(s): " + repr(args.pos()))
  }
  // Validate named arguments
  let (cfg,) = parse-main-args(..args)
  // Preconfigure functions with user args, not with cfg as cfg includes all
  // settings (using defaults for values not specified by the user) while we
  // want functions to be able to have defaults different from the global
  // common.settings defaults. This is used by render() to have default true
  // for apply-style while the global default is false.
  return (
    template: styling.resolve(cfg.style, cfg.named-styles).template,
    cells:            cells           .with(..args),
    cell:             cell            .with(..args),
    outputs:          outputs         .with(..args),
    output:           output          .with(..args),
    displays:         displays        .with(..args),
    display:          display         .with(..args),
    results:          results         .with(..args),
    result:           result          .with(..args),
    stream-items:     stream-items    .with(..args),
    stream-item:      stream-item     .with(..args),
    errors:           errors          .with(..args),
    error:            error           .with(..args),
    streams:          streams         .with(..args),
    stream:           stream          .with(..args),
    sources:          sources         .with(..args),
    source:           source          .with(..args),
    render:           render          .with(..args),
    Cell:             Cell            .with(..args),
    In:               In              .with(..args),
    Out:              Out             .with(..args),
    export:           export          .with(..args),
    make-notebook:    make-notebook   .with(..args),
    stage-notebook:   stage-notebook  .with(..args),
  )
}
// Preconfigure named-styles in a way that they are included in
// the 'args' of the above config definition, and without introducing another
// exported binding in this module.
#let config = config.with(named-styles: styles.named)
