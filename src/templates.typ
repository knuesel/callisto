#import "reading.typ": source, outputs

// Make a string for a cell execution count, showing a space if missing
#let _count-string(count) = if count == none { return " " } else { str(count) }

// Add the In/Out annotation in the margin of code cell input/output
#let _in-out-num(prefix, count) = context {
  let txt = raw(prefix + "[" + _count-string(count) + "]:")
  place(top+left, dx: -1.2em - measure(txt).width, txt)
}

// Ensure a code/raw cell source has at least one (possibly empty) line
// (without this the raw block looks weird for empty cells)
#let _ensure-one-line(cell) = {
  if cell.source == "" {
    cell.source = "\n"
  }
  return cell
}

#let plain-raw(cell, input-args: none, ..args) = source(cell, ..input-args)

#let plain-markdown(cell, nb: none, output-args: none, ..args) = {
  output-args.handlers.at("text/markdown")(
    cell.source,
    ctx: (nb: nb, cell: cell, ..output-args),
  ) + parbreak()
}

#let plain-input(cell, input-args: none, ..args) = source(cell, ..input-args)

#let plain-output(cell, output-args: none, ..args) = {
  outputs(cell, ..output-args, result: "value").join()
}

#let notebook-raw(cell, input-args: none, ..args) = block(
  spacing: 1.5em,
  width: 100%,
  inset: 0.5em,
  fill: luma(240),
  source(_ensure-one-line(cell), ..input-args),
)

#let notebook-markdown = plain-markdown

#let notebook-input(cell, output: true, input-args: none, ..args) = block(
  above: 2em,
  below: if output and cell.outputs.len() > 0 { 0pt } else { 2em },
  width: 100%,
  inset: 0.5em,
  fill: luma(240),
  {
    _in-out-num("In ", cell.execution_count)
    source(_ensure-one-line(cell), ..input-args)
  },
)

#let normal-block = block.with(width: 100%)
#let error-block = normal-block.with(
  fill: red.lighten(90%),
  outset: 0.5em,
)

// Wrap some outputs in a raw block
#let _notebook-output-value(out) = {
  if out.type == "error" {
    return raw(block: true, lang: "txt", out.traceback.join("\n"))
  }
  if out.type == "stream" or out.format == "text/plain" {
    return raw(block: true, lang: "txt", out.value)
  }
  return out.value
}

#let notebook-output(cell, output-args: none, ..args) = {
  let outs = outputs(cell, ..output-args, result: "dict")
  if outs.len() == 0 { return }
  block(
    above: 0pt,
    below: 2em,
    width: 100%,
    inset: 0.5em,
    {
      for out in outs {
        let value = _notebook-output-value(out)
        if out.type == "execute_result" { 
          block({
            _in-out-num("Out", cell.execution_count)
            value
          })
        } else if out.type == "error" {
          error-block(value)
        } else if out.type == "stream" and out.name == "stderr" {
          error-block(value)
        } else if out.type == "stream" {
          normal-block(value)
        } else {
          value
        }
      }
    },
  )
}

// Templates

#let plain-cell = (
  raw: plain-raw,
  markdown: plain-markdown,
  input: plain-input,
  output: plain-output,
)
#let notebook-cell = (
  raw: notebook-raw,
  markdown: notebook-markdown,
  input: notebook-input,
  output: notebook-output,
)

// Dict of default cell templates
#let cell-templates = (
  plain: plain-cell,
  notebook: notebook-cell,
)
