#import "/lib/common.typ": handle
#import "/lib/reading/output.typ": outputs

// Make a string for a cell execution count, showing a space if missing
#let _count-string(count) = if count == none { return " " } else { str(count) }

// Add the In/Out annotation in the margin of code cell input/output
#let _in-out-num(prefix, count) = context {
  let txt = raw(prefix + "[" + _count-string(count) + "]:")
  place(top+left, dx: -1.2em - measure(txt).width, txt)
}

#let notebook-raw-cell(cell, ctx: none) = block(
  spacing: 1.5em,
  width: 100%,
  inset: 0.5em,
  fill: luma(240),
  handle(cell.source, mime: "source-code-generic", ctx: ctx),
)

#let notebook-code-cell-input(cell, ctx: none) = block(
  above: 2em,
  below: if ctx.cfg.output and cell.outputs.len() > 0 { 0pt } else { 2em },
  width: 100%,
  inset: 0.5em,
  fill: luma(240),
  {
    _in-out-num("In ", cell.execution_count)
    handle(cell.source, mime: "source-code-generic", ctx: ctx, lang: ctx.lang)
  },
)

// Styled block for error items (error outputs or stderr streams)
#let error-block = block.with(
  width: 100%,
  fill: red.lighten(90%),
  outset: 0.5em,
)

// Customized default handler for errors, rendering the traceback
#let notebook-error(data, ctx: none, traceback: none, ..args) = {
  raw(traceback.join("\n"), block: true, lang: "txt")
}

#let notebook-code-cell-output(cell, ctx: none) = {
  let outs = outputs(cell, ..ctx.cfg, result: "dict")
  if outs.len() == 0 { return }
  block(
    above: if ctx.cfg.input { 0pt } else { 2em },
    below: 2em,
    width: 100%,
    inset: 0.5em,
    {
      for out in outs {
        let is-stderr = out.type == "stream" and out.name == "stderr"
        if out.type == "execute_result" { 
          block({
            _in-out-num("Out", cell.execution_count)
            out.value
          })
        } else if is-stderr or out.type == "error" {
          error-block(out.value)
        } else {
          out.value
        }
      }
    },
  )
}

#let theme = (
  error: notebook-error,
  raw-cell: notebook-raw-cell,
  code-cell-input: notebook-code-cell-input,
  code-cell-output: notebook-code-cell-output,
)
