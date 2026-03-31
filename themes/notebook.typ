#import "/lib/util.typ": handle
#import "/lib/reading/output.typ": outputs
#import "plain.typ"

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
  below: if ctx.output and cell.outputs.len() > 0 { 0pt } else { 2em },
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
#let notebook-error(data, ctx: none, ..args) = {
  let txt = data.traceback.join("\n")
  let rendered = handle(txt, mime: "text-ansi-block", ctx: ctx, ..args)
  error-block(rendered)
}

#let notebook-stream-stderr(data, ctx: none, ..args) = {
  let value = handle(data, mime: "stream-generic", ctx: ctx, ..args)
  error-block(value)
}

#let notebook-result(data, ctx: none, ..args) = block({
  _in-out-num("Out", ctx.cell.execution_count)
  handle(data, mime: "rich-output-generic", ctx: ctx, ..args)
})

#let notebook-code-cell-output(cell, ctx: none) = {
  let outs = outputs(cell, ..ctx.cfg, result: "value")
  if outs.len() == 0 { return }
  block(
    above: if ctx.input { 0pt } else { 2em },
    below: 2em,
    width: 100%,
    inset: 0.5em,
    outs.join(),
  )
}

#let theme = plain.theme + (
  stream-stderr: notebook-stream-stderr,
  error: notebook-error,
  result: notebook-result,
  raw-cell: notebook-raw-cell,
  code-cell-input: notebook-code-cell-input,
  code-cell-output: notebook-code-cell-output,
)
