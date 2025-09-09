// All settings for the main functions, with default values
#let settings = (
  // Cell selection
  nb: none,
  count: "index",
  name-path: auto,
  cell-type: "all",
  keep: "all",
  cell-header-pattern: auto,
  keep-cell-header: false,
  // Other
  lang: auto,
  raw-lang: none,
  result: "value",
  stream: "all",
  format: auto,
  handlers: auto,
  ignore-wrong-format: false,
  template: "notebook",
  item: "unique",
  // Special (should not override args set in pre-configured functions)
  output-type: "all",
  input: true,
  output: true,
)

// Parse the arguments of the main functions
#let parse-main-args(args) = {
  if args.pos().len() > 1 {
    panic("expected 0 or 1 positional argument for the cell specification, " +
      "got " + repr(args.pos()))
  }
  if args.pos().len() == 1 and args.at(0) == none {
    panic("invalid cell specification: 'none'")
  }
  let cell-spec = args.at(0, default: none)
  let user-cfg = args.named()
  for k in user-cfg.keys() {
    if k not in settings {
      panic("unexpected keyword argument '" + k + "'")
    }
  }
  return (
    cell-spec: cell-spec,
    cfg: settings + user-cfg,
  )
}

// Wrap the argument in an array if it is not itself an array
#let ensure-array(x) = if type(x) == array { x } else { (x,) }

// Return the first positional argument that is different from `on`,
// or return `on` if none is different.
#let coalesce(on: none, ..args) = {
  for x in args.pos() {
    if x != on { return x }
  }
  return on
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
// Depending on ctx.cfg.result, this returns either 'value', or the
// 'preprocessed' dict with 'output_type' renamed to 'type' and with additional
// fields:
// - value: the rendered item
// - cell (dict): the cell index, id, metadata and type.
#let final-result(preprocessed, value, ctx: none) = {
  if ctx.cfg.result not in ("value", "dict") {
    panic("invalid result specification: " + repr(ctx.cfg.result))
  }
  if ctx.cfg.result == "value" {
    return value
  }
  // Remove "output_type" field if present (will be replaced by type field from
  // ctx.item)
  _ = preprocessed.remove("output_type", default: none)
  return preprocessed + ctx.item + (
    cell: _cell-output-dict(ctx.cell),
    value: value,
  )
}

// Returns a single item from the given list, raising an error if the list is
// empty or if 'item' is "unique" and the list contains more than one.
#let single-item(items, item: "unique") = {
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

// Handle the given data using the handler registered for the given mime
// type, forwarding the 'args' arguments to the handler.
// Before calling the handler, the context is updated to include
// 'mime' as an extra field.
#let handle(data, mime: none, ctx: none, ..args) = {
  if ctx == none {
    panic("ctx not set")
  }
  if mime not in ctx.handlers {
    panic("format " + repr(mime) +
      " has no registered handler (is it a valid MIME string?)")
  }
  ctx.mime = mime
  ctx.handlers.at(mime)(data, ctx: ctx, ..args)
}
