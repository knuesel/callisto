#import "theming.typ"

// All settings for the main functions, with default values
#let settings = (
  // Notebook
  nb: none,
  cell-header-pattern: auto,
  keep-cell-header: false,
  lang: auto,
  raw-lang: none,
  latex-preamble: auto,
  // Cell selection
  count: "index",
  name-path: auto,
  cell-type: "all",
  keep: "all",
  // Other
  h1-level: 1,
  // Outputs
  result: "value",
  stream: "all",
  format: auto,
  handlers: auto,
  ignore-wrong-format: false,
  item: "unique",
  output-type: "all",
  // Rendering
  input: true,
  output: true,
  default-handlers: (:), // to be filled in callisto.typ
  named-themes: (:), // to be filled in callisto.typ
  theme: "notebook",
  apply-theme: false, // default for all but render functions
  // Export
  disabled: auto,
  export-name: "notebook",
  cell-label: none,
  kernel: none,
)

// Parse the arguments of the main functions
#let parse-main-args(..args) = {
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

// Return true if notebook functions should be disabled in this configuration,
// that is if the user set disabled=true or if disabled=auto and export was
// enabled on the command-line (--input callisto-export=true).
#let disabled(cfg: none) = {
  if cfg.disabled != auto {
    return cfg.disabled
  }
  let cli-export = sys.inputs.at("callisto-export", default: "false")
  if cli-export == "false" {
    return false
  }
  if cli-export == "true" {
    return true
  }
  panic("unsupported value for callisto-export input: " + cli-export)
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
  // ctx.item-desc)
  _ = preprocessed.remove("output_type", default: none)
  return preprocessed + ctx.item-desc + (
    cell: _cell-output-dict(ctx.cell),
    value: value,
  )
}

// Calls the specified function with the given arguments and returns a single
// item as specified in by the `item` setting, raising an error if the list is
// empty or if 'item' is "unique" and the list contains more than one.
#let single-item(func, args) = {
  let (cell-spec, cfg) = parse-main-args(..args)
  if disabled(cfg: cfg) { return none }

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

// Handle the given data using the handler registered for the given mime
// type, forwarding the 'args' arguments to the handler.
// Before calling the handler, the context is updated to include
// 'mime' as an extra field.
#let handle(data, mime: none, ctx: none, ..args) = {
  if ctx == none {
    panic("ctx not set")
  }
  if mime not in ctx.handlers {
    panic("no handle registered for MIME " + repr(mime))
  }
  let handler = ctx.handlers.at(mime)
  if handler == none {
    return none
  }
  ctx.mime = mime
  handler(data, ctx: ctx, ..args)
}

// A handler function that composes the functions specified in the given list.
// If a list value is 'none' instead of a function, the next function is called
// with 'none' as argument.
#let _composed-handler(list, data, ..args) = list.fold(
  data,
  (value, f) => if f == none { none } else { f(value, ..args) },
)

// Given a default handler and the user value, return a resolved handler, which
// is always a function or none.
#let _resolve-one-handler(default-handler, mime, value) = {
  if value == auto {
    return default-handler
  }
  if type(value) == array {
    // Replace auto with default
    let list = value.map(x => if x == auto { default-handler } else { x })
    return _composed-handler.with(list)
  }
  if type(value) == function or value == none {
    return value
  }
  panic("invalid handler type \"" + repr(type(value)) + "\" for handler "
    + repr(value))
}

// Given the default handler dict and user handler dict, return a dict of
// resolved user handlers, where each value is a handler function or none.
// Each user handler can be given as none or auto or a function or an array of
// values representing functions to compose, where the auto value represent the
// default handler.
#let _resolve-user-handlers(default, user) = {
  if user == auto { return (:) }
  if type(user) != dictionary {
    panic("handlers must be auto or a dictionary mapping formats to functions")
  }
  for (k, v) in user.pairs() {
    if k not in default {
      panic("unknown handler " + repr(k) +
        " (custom handlers must be registered with default-handlers)")
    }
    ((k): _resolve-one-handler(default.at(k), k, v))
  }
}

// Get final handlers from default, theme and user handlers.
#let all-handlers(cfg: none) = {
  let handlers = cfg.default-handlers
  if cfg.apply-theme {
    let (template, ..theme-handlers) = theming.resolve(cfg.theme, cfg.named-themes)
    handlers += theme-handlers
  }
  let user-handlers = _resolve-user-handlers(handlers, cfg.handlers)
  return handlers + user-handlers
}

// Return the notebook as JSON, without any processing
#let nb-json(cfg: none) = {
  if type(cfg.nb) not in (str, bytes, dictionary) {
    panic("invalid notebook type: " + str(type(nb)))
  }
  if type(cfg.nb) == bytes {
    return json(cfg.nb)
  }
  if type(cfg.nb) == str {
    let handlers = all-handlers(cfg: cfg)
    return json(handlers.at("path")(cfg.nb, ctx: none))
  }
  return cfg.nb
}
