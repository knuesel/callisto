#import "input.typ"
#import "templates.typ"
#import "rendering.typ"

#let config(
  // Cell args
  nb: none,
  count: "position",
  name: auto,
  // Source args
  lang: auto,
  // Output args
  format: auto,
  handlers: auto,
  ignore-wrong-format: false,
  stream: "all",
  output: "value", // doesn't apply to errors and streams
  // Render args
  cmarker: (:),
  template: "notebook",
) = {
  if handlers != auto {
    // Start with default handlers and add/overwrite with provided ones
    handlers = input.default-handlers + handlers
  }
  let cell-args = (nb: nb, count: count, name: name)
  let input-args = (lang: lang)
  let output-args = (
    format: format,
    handlers: handlers,
    ignore-wrong-format: ignore-wrong-format,
    stream: stream,
    output: output,
  )
  let render-args = (
    input-args: input-args,
    output-args: output-args,
    cmarker: cmarker,
    template: template,
  )
  return (
    cells:        input.cells.with(..cell-args),
    cell:         input.cell.with(..cell-args),
    outputs:      input.outputs.with(..cell-args, ..output-args),
    output:       input.output.with(..cell-args, ..output-args),
    displays:     input.displays.with(..cell-args, ..output-args),
    display:      input.display.with(..cell-args, ..output-args),
    results:      input.results.with(..cell-args, ..output-args),
    result:       input.result.with(..cell-args, ..output-args),
    stream-items: input.stream-items.with(..cell-args),
    stream-item:  input.stream-item.with(..cell-args),
    errors:       input.errors.with(..cell-args),
    error:        input.error.with(..cell-args),
    streams:      input.streams.with(..cell-args),
    stream:       input.stream.with(..cell-args),
    sources:      input.sources.with(..cell-args, ..input-args, output: output),
    source:       input.source.with(..cell-args, ..input-args, output: output),
    template:     templates.doc-template,
    render:       rendering.render.with(..cell-args, ..render-args),
    Cell:         rendering.Cell.with(..cell-args, ..render-args),
    In:           rendering.In.with(..cell-args, ..render-args),
    Out:          rendering.Out.with(..cell-args, ..render-args),
  )
}
