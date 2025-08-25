#import "common.typ": handle
#import "reading.typ": source, outputs

// Make a string for a cell execution count, showing a space if missing
#let _count-string(count) = if count == none { return " " } else { str(count) }

// Add the In/Out annotation in the margin of code cell input/output
#let _in-out-num(prefix, count) = context {
  let txt = raw(prefix + "[" + _count-string(count) + "]:")
  place(top+left, dx: -1.2em - measure(txt).width, txt)
}

#let plain-raw(cell, ctx: none) = {
  handle(cell.source, "text/x.source-raw-cell", ctx: ctx)
}

#let plain-markdown(cell, ctx: none) = {
  handle(cell.source, "text/markdown", ctx: ctx) + parbreak()
}

#let plain-input(cell, ctx: none) = {
  handle(cell.source, "text/x.source-code-cell", ctx: ctx)
}

#let plain-output(cell, ctx: none) = {
  // Get outputs with user config, but override 'result' to get just the values
  outputs(cell, ..ctx.cfg, result: "value").join()
}

#let notebook-raw(cell, ctx: none) = block(
  spacing: 1.5em,
  width: 100%,
  inset: 0.5em,
  fill: luma(240),
  handle(cell.source, "text/x.source-raw-cell", ctx: ctx),
)

#let notebook-markdown = plain-markdown

#let notebook-input(cell, ctx: none) = block(
  above: 2em,
  below: if ctx.cfg.output and cell.outputs.len() > 0 { 0pt } else { 2em },
  width: 100%,
  inset: 0.5em,
  fill: luma(240),
  {
    _in-out-num("In ", cell.execution_count)
    handle(cell.source, "text/x.source-code-cell", ctx: ctx)
  },
)

#let normal-block = block.with(width: 100%)
#let error-block = normal-block.with(
  fill: red.lighten(90%),
  outset: 0.5em,
)

#let notebook-output(cell, ctx: none) = {
  let outs = outputs(cell, ..ctx.cfg, result: "dict")
  if outs.len() == 0 { return }
  block(
    above: 0pt,
    below: 2em,
    width: 100%,
    inset: 0.5em,
    {
      for out in outs {
        if out.type == "execute_result" { 
          block({
            _in-out-num("Out", cell.execution_count)
            out.value
          })
        } else if out.type == "error" or (
          out.type == "stream" and out.name == "stderr"
        ) {
          error-block(out.value)
        } else {
          out.value
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
