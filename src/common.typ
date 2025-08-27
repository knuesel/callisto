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

/// Return either the 'value' key of dict or return the dict itself, with some
/// added cell data under key 'cell'. See cell-output-dict for the added data.
/// - cell (dict): A cell in json format
/// - result-spec (str): Choose output mode: "value" or "dict"
/// - dict (dict): Contains at least a 'value' key
/// -> any | (value: any, cell: dict)
#let final-result(cell, result-spec, dict) = {
  if result-spec == "value" {
    return dict.value
  }
  if result-spec == "dict" {
    dict.cell = _cell-output-dict(cell)
    return dict
  }
  panic("invalid result specification: " + repr(result))
}

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

#let handle(data, mime, ctx: none, ..args) = {
  if ctx == none {
    panic("ctx not set")
  }
  if mime not in ctx.handlers {
    panic("format " + repr(mime) +
      " has no registered handler (is it a valid MIME string?)")
  }
  ctx.handlers.at(mime)(data, ctx: ctx, ..args)
}
