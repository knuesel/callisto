#import "reading.typ": *
#import "templates.typ"

// A code template function that uses input and output template functions
#let _code-template(
  input-func,
  output-func,
  input: true,
  output: true,
   ..args,
) = {
  if input and input-func != none {
    input-func(input: true, output: false, ..args)
  }
  if output and output-func != none {
    output-func(input: false, output: true, ..args)
  }
}

// A template function that delegates to a dict field for each cell type
#let _merged-template(dict,  cell, ..args) = {
  let f = dict.at(cell.cell_type)
  f(cell, ..args)
}

#let _null-template(..args) = none

// Normalize a template name/function/dict/none to a function
#let _normalize-template(value) = {
  if type(value) == function {
    return value
  }
  if value == none {
    return _null-template
  }
  if type(value) == str {
    if value not in templates.cell-templates {
      panic("template name not found: " + value)
    }
    let resolved = templates.cell-templates.at(value)
    return _normalize-template(resolved)
  }
  if type(value) != dictionary {
    panic("invalid template type: " + str(type(value)))
  }
  let dict = value
  // For a dict, we normalize the fields and then make a template function.
  // We must normalize the input and output fields before the code field.
  dict.input = _normalize-template(dict.at("input", default: none))
  dict.output = _normalize-template(dict.at("output", default: none))
  if "code" in dict or (dict.input == none and dict.output == none) {
    // We can normalize the existing subtemplate, or fall back on none
    dict.code = _normalize-template(dict.at("code", default: none))
  } else {
    // No code subtemplate defined, but input/output is defined
    dict.code = _code-template.with(dict.input, dict.output)
  }
  dict.markdown = _normalize-template(dict.at("markdown", default: none))
  dict.raw = _normalize-template(dict.at("raw", default: none))

  return _merged-template.with(dict)
}

#let render(
  // Cell args
  ..cell-spec,
  nb: none,
  count: "index",
  name-path: auto,
  cell-type: "all",
  keep: "all",
  // Other args
  lang: auto,
  raw-lang: none,
  result: "value", // unused but accepted to have more uniform API
  stream: "all",
  format: auto,
  handlers: auto,
  ignore-wrong-format: false,
  template: "notebook",
  output-type: "all",
  input: true,
  output: true,
) = {
  template = _normalize-template(template)
  if nb != none {
    nb = read-notebook(nb)
  }
  // Get lang from notebook if auto, so that the value can be passed to
  // templates (which don't receive the notebook itself)
  if lang == auto {
    lang = notebook-lang(nb)
  }

  // Arguments for rendering cell inputs
  let input-args = (
    lang: lang,
    raw-lang: raw-lang,
  )
  // Arguments for rendering cell outputs
  let output-args = (
    stream: stream,
    format: format,
    handlers: handlers,
    ignore-wrong-format: ignore-wrong-format,
    output-type: output-type,
  )

  for cell in cells(
    ..cell-spec,
    nb: nb,
    count: count,
    name-path: name-path,
    cell-type: cell-type,
    keep: keep,
  ) {
    template(
      cell,
      template: template,
      handlers: handlers,
      input: input,
      output: output,
      input-args: input-args,
      output-args: output-args,
    )
  }
}

#let Cell = render.with(keep: "unique")
#let In = Cell.with(output: false)
#let Out = Cell.with(input: false)
