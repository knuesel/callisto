#import "/lib/configuration.typ": parse-main-args, read-enabled
#import "/lib/util.typ": handle, ensure-array
#import "/lib/ctx/ctx.typ": get-ctx
#import "common.typ": final-result
#import "cell.typ": cells

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
  let names = _stream-names(ctx.stream)
  if item.name not in names { return none }
  if type(item.text) == array {
    return item.text.join()
  }
  return item.text
}

// Generic preprocessing that doesn't require context
#let preprocess(item, ctx: none) = {
  item.text = _stream-text(item, ctx: ctx)
  if item.text == none { return none }
  return item
}

// Same as stream-items function, but merges all streams (matching 'stream')
// of the same cell.
#let streams(..args) = {
  let (cell-spec, cfg) = parse-main-args(..args)
  if read-enabled(cfg: cfg) == false { return none }
  let names = _stream-names(cfg.stream)
  let cs = cells(..args, cell-type: "code")
  let outs = ()
  for cell in cs {
    // item-desc.index is undefined since we gather outputs from different cells
    let ctx = get-ctx(cell, cfg: cfg, item-desc: (type: "stream", index: none))
    // Concatenate all stream items
    let txt = for item in cell.outputs {
      if item.output_type == "stream" {
        _stream-text(item, ctx: ctx)
      }
    }
    if txt == none { continue }
    let preprocessed = (output_type: "stream", name: cfg.stream, text: txt)
    let value = handle(preprocessed, mime: "stream", ctx: ctx)
    outs.push(final-result(preprocessed, value, ctx: ctx))
  }
  return outs
}
