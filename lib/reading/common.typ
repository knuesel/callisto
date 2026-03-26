#import "/lib/config.typ": parse-main-args, read-enabled

// Calls the specified function with the given arguments and returns a single
// item as specified in by the `item` setting, raising an error if the list is
// empty or if 'item' is "unique" and the list contains more than one.
#let single-item(func, args) = {
  let (cell-spec, cfg) = parse-main-args(..args)
  if read-enabled(cfg: cfg) == false { return none }

  let items = func(..args)
  let item = cfg.item
  if items.len() == 0 {
    panic("no matching item found")
  }
  if item == "unique" {
    if items.len() != 1 {
      panic("expected 1 item, found " + str(items.len()))
    }
    item = 0
  }
  return items.at(item)
}

// A dictionary of cell-related data, to be used as one field in the result
// dict.
#let _cell-output-dict(cell) = (
  index: cell.index,
  id: cell.id,
  metadata: cell.metadata,
  type: cell.cell_type,
) + if cell.cell_type == "code" {
  (execution-count: cell.execution_count)
}

// Final result for an output item.
// Depending on ctx.result, this returns either 'value', or the
// 'preprocessed' dict with 'output_type' renamed to 'type' and with additional
// fields:
// - value: the rendered item
// - cell (dict): the cell index, id, metadata and type.
#let final-result(preprocessed, value, ctx: none) = {
  if ctx.result not in ("value", "dict") {
    panic("invalid result specification: " + repr(ctx.result))
  }
  if ctx.result == "value" {
    return value
  }
  // Remove "output_type" field if present (will be replaced by type field from
  // ctx.item-desc)
  _ = preprocessed.remove("output_type", default: none)
  return preprocessed + ctx.item-desc + (
    cell: _cell-output-dict(ctx.cell),
    value: value,
  )
}

// Gets a boolean value from the cell header
#let get-header-bool(cell, key, default) = {
  let value = cell.metadata.callisto.header.at(key, default: default)
  if value not in ("true", "false") {
    panic("value for " + key + " in cell header must be \"true\" or \"false\"")
  }
  return value == "true"
}
