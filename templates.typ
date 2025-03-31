#import "@preview/cmarker:0.1.3" as cm
#import "@preview/mitex:0.2.5": mitex

#import "input.typ": *

#let _count-string(count) = if count == none { return " " } else { str(count) }

#let _in-out-num(prefix, count) = context {
  let txt = raw(prefix + "[" + _count-string(count) + "]:")
  place(top+left, dx: -1.2em - measure(txt).width, txt)
}

#let plain-raw(cell, ..args) = source(cell)
#let plain-markdown(cell, cmarker: (:), ..args) = {
 cm.render(source(cell).text, math: mitex, ..cmarker)
}
#let plain-input(cell, input-args: (:), ..args) = source(cell, ..input-args)
#let plain-output(cell, output-args: (:), ..args) = {
  outputs(cell, ..output-args, output: "value").join()
}

#let notebook-raw = plain-raw
#let notebook-markdown = plain-markdown
#let notebook-input(cell, input-args: (:), ..args) = {
  let src = source(cell, ..input-args) // TODO: make sure input-args includes lang, defaulting to kernel lang if unspecified`
  block(
    above: 2em,
    width: 100%,
    inset: 0.5em,
    fill: luma(235),
    {
      _in-out-num("In ", cell.execution_count)
      src
    },
  )
}
#let error-block = block.with(
  fill: red.lighten(90%),
  outset: 0.5em,
  width: 100%,
)
#let notebook-output(cell, output-args: (:), ..args) = {
  let outs = outputs(cell, ..output-args, output: "dict")
  if outs.len() == 0 { return }
  block(
    spacing: 0em,
    width: 100%,
    inset: 0.5em,
    {
      for out in outs {
        if out.type == "execute_result" { 
          block({
            _in-out-num("Out", cell.execution_count)
            out.value
          })
        } else if out.type == "error" {
            error-block(out.traceback.join("\n"))
        } else if out.type == "stream" and out.name == "stderr" {
            error-block(out.value)
        } else {
          out.value
        }
      }
    },
  )
}

// Default templates
#let plain = (
  raw: plain-raw,
  markdown: plain-markdown,
  input: plain-input,
  output: plain-output,
)
#let notebook = (
  raw: notebook-raw,
  markdown: notebook-markdown,
  input: notebook-input,
  output: notebook-output,
)
// Dict of default templates
#let dict = (
  plain: plain,
  notebook: notebook,
)

#let doc-template(it) = {
  show raw.where(block: true): set block(
    inset: (left: 1.2em, y: 1em),
    stroke: (left: 3pt+luma(96%)),
  )
  it
}
