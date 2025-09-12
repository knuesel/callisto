#import "reading.typ"
#import "rendering.typ"
#import "common.typ": parse-main-args

#let config(..args) = {
  if args.pos().len() > 0 {
    panic("unexpected positional argument(s): " + repr(args.pos()))
  }
  // Validate named arguments
  let (cfg,) = parse-main-args(args)
  return (
    cells:        reading.cells       .with(..args),
    cell:         reading.cell        .with(..args),
    outputs:      reading.outputs     .with(..args),
    output:       reading.output      .with(..args),
    displays:     reading.displays    .with(..args),
    display:      reading.display     .with(..args),
    results:      reading.results     .with(..args),
    result:       reading.result      .with(..args),
    stream-items: reading.stream-items.with(..args),
    stream-item:  reading.stream-item .with(..args),
    errors:       reading.errors      .with(..args),
    error:        reading.error       .with(..args),
    streams:      reading.streams     .with(..args),
    stream:       reading.stream      .with(..args),
    sources:      reading.sources     .with(..args),
    source:       reading.source      .with(..args),
    render:       rendering.render    .with(..args),
    Cell:         rendering.Cell      .with(..args),
    In:           rendering.In        .with(..args),
    Out:          rendering.Out       .with(..args),
  )
}
