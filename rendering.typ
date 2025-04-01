#import "input.typ": *
#import "templates.typ"

#let _template-from-name(name) = {
  if name not in templates.dict {
    panic("template name not found: " + name)
  }
  return templates.dict.at(name)
}

#let _subtemplate(dict, name) = {
  let f = dict.at(name, default: none)
  if f == none {
    return (..args) => none
  }
  if type(f) == str {
    return from-name(f).at(name)
  }
  if type(f) != function {
    panic("unsupported template type for " + name + ": " + type(f))
  }
  return f
}

// Render a cell by using the sub-templates specified in the
// `templates` dictionary, with fields: raw, markdown, input, output.
#let cell-template(
  cell,
  templates: (:),
  input: true,
  output: true,
   ..args,
) = {
  if cell.cell_type != "code" or "code" in templates {
    let f = _subtemplate(templates, cell.cell_type)
    return f(cell, ..args, input: input, output: output)
  }
  // We have a code cell and no code template
  // -> render input and output separately
  if input {
    let f = _subtemplate(templates, "input")
    f(cell, ..args)
  }
  if output {
    let f = _subtemplate(templates, "output")
    f(cell, ..args)
  }
}

#let render(
  ..cell-args, // includes type to select by cell type
  nb: none,
  input: true, // source of a code cell
  output: true,
  input-args: (:), // for input (source of code cell) template
  output-args: (:), // for output template
  cmarker: (:),
  template: "notebook",
) = {
  if type(template) == str {
    template = _template-from-name(template)
  }
  if type(template) == dictionary {
    template = cell-template.with(templates: template)
  }
  if nb != none {
    nb = read-notebook(nb)
  }
  // Get lang from notebook if auto
  let lang = input-args.at("lang", default: auto)
  if lang == auto {
    lang = notebook-lang(nb)
    input-args.lang = lang
  }
  for cell in cells(..cell-args, nb: nb) {
    template(
      cell,
      nb: nb,
      input: input,
      output: output,
      input-args: input-args,
      output-args: output-args,
      cmarker: cmarker,
    )
  }
}

#let Cell = render.with(keep: "unique")
#let In = Cell.with(output: false)
#let Out = Cell.with(input: false)
