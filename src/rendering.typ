#import "reading.typ": cells
#import "templates.typ"
#import "ctx.typ": get-ctx
#import "common.typ": parse-main-args

// A code template function that uses input and output template functions.
// Both input and output keywords are forwarded to the input/output templates to
// let them use this information for example to produce smaller spacing between
// input and output when both components are rendered.
#let _code-template(cell, ctx: none, input-func: none, output-func: none) = {
  if ctx.cfg.input and input-func != none {
    input-func(cell, ctx: ctx)
  }
  if ctx.cfg.output and output-func != none {
    output-func(cell, ctx: ctx)
  }
}

// A template function that delegates to a dict field for each cell type
#let _merged-template(cell, ctx: none, func-dict: none) = {
  let f = func-dict.at(cell.cell_type, default: none)
  if f != none {
    f(cell, ctx: ctx)
  }
}

// Resolve template by name
#let _resolve-template(name) = {
  if name not in templates.cell-templates {
    panic("template name not found: " + name)
  }
  return templates.cell-templates.at(name)
}

// Return a normalized value for the given key of the given template dict,
// returning a function or none.
// Unlike _normalize-template, this doesn't create a new template function to
// handle various cell types: it only resolves a single field, possibly by
// digging recursively in dictionaries. When the key is `code`, the dict must
// have `input` and `output` keys with values already resolved to functions or
// none: these values might be used for the code template.
#let _normalize-subtemplate(dict, key) = {
  // Handle case where "code" is requested but not explicitly defined
  if key == "code" and "code" not in dict {
    if dict.input == none and dict.output == none {
      return none
    }
    return _code-template.with(input-func: dict.input, output-func: dict.output)
  }

  let value = dict.at(key, default: none)
  if type(value) == str {
    value = _resolve-template(value)
  }
  if type(value) == function or value == none {
    return value
  }
  if type(value) == dictionary {
    return _normalize-subtemplate(value, key)
  }
  panic("invalid subtemplate type: " + str(type(value)))
}

// Normalize a template name/function/dict/none to a function or none
#let _normalize-template(value) = {
  if value == none {
    return none
  }
  if type(value) == function {
    return value
  }
  if type(value) == str {
    return _normalize-template(_resolve-template(value))
  }
  if type(value) != dictionary {
    panic("invalid template type: " + str(type(value)))
  }
  let dict = value
  // For a dict, we normalize the fields and then make a template function.
  // We must normalize the input and output fields before the code field.
  dict.input = _normalize-subtemplate(dict, "input")
  dict.output = _normalize-subtemplate(dict, "output")
  dict.code = _normalize-subtemplate(dict, "code")
  dict.markdown = _normalize-subtemplate(dict, "markdown")
  dict.raw = _normalize-subtemplate(dict, "raw")
  return _merged-template.with(func-dict: dict)
}

// Render the specified cells according to the settings (see common.typ)
#let render(..args) = {
  let (cell-spec, cfg) = parse-main-args(args)
  let template = _normalize-template(cfg.template)
  if template == none { return none }
  let cfg = parse-main-args(args).cfg
  for cell in cells(..args) {
    template(cell, ctx: get-ctx(cell, cfg: cfg))
  }
}

// Render a single cell
#let Cell = render.with(keep: "unique")
// Render a single cell's input
#let In = Cell.with(cell-type: "code", input: true, output: false)
// Render a single cell's output
#let Out = Cell.with(cell-type: "code", input: false, output: true)
