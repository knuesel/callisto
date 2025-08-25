#import "cell.typ": cells
#import "../common.typ": handle, parse-main-args, final-result, ensure-array
#import "../ctx.typ": get-ctx

#let all-stream-names = ("stdout", "stderr")

// Resolve 'stream' setting to a list of desired streams' names
#let _stream-names(stream) = {
  if stream == "all" { return all-stream-names }
  let names = ensure-array(stream)
  for name in names {
    if name not in all-stream-names {
      panic("invalid stream name: " + repr(name))
    }
  }
  return names
}

// Get stream item text as a single string, if the item is a stream with
// name matching ctx.stream. Returns none otherwise.
#let _stream-text(item, ctx: none) = {
  let names = _stream-names(ctx.cfg.stream)
  if item.name not in names { return none }
  if type(item.text) == array {
    return item.text.join()
  }
  return item.text
}

// Process a stream output item.
// Can return none if the item is from an undesired stream (cf 'stream' arg.)
#let process-output(item, ctx: none) = {
  let txt = _stream-text(item, ctx: ctx)
  if txt == none { return none }
  return (
    type: "stream",
    name: item.name,
    value: handle(txt, "text/x.stream", ctx: ctx, name: item.name),
    raw-text: txt,
  )
}

// Same as stream-items function, but merges all streams (matching 'stream')
// of the same cell, and always returns an item (possibly with an empty string
// as value) for each selected cell (of code type).
#let streams(..args) = {
  let (cell-spec, cfg) = parse-main-args(args)
  let names = _stream-names(cfg.stream)
  let cs = cells(..args, cell-type: "code")
  let outs = ()
  for cell in cs {
    let ctx = get-ctx(cell, cfg: cfg)
    // Concatenate all stream items
    let txt = for item in cell.outputs {
      if item.output_type == "stream" {
        _stream-text(item, ctx: ctx)
      }
    }
    if txt == none {
      continue
    }
    let out = (
      type: "stream",
      name: cfg.stream,
      value: handle(txt, "text/x.stream", ctx: ctx, name: cfg.stream),
    )
    outs.push(final-result(cell, cfg.result, out))
  }
  return outs
}

#let stream(..args, item: "unique") = single-item(streams(..args), item: item)
