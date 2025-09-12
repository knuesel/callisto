#import "../common.typ": handle
#import "../reading.typ": outputs

// Make a string for a cell execution count, showing a space if missing
#let _count-string(count) = if count == none { return " " } else { str(count) }

// Add the In/Out annotation in the margin of code cell input/output
#let _in-out-num(prefix, count) = context {
  let txt = raw(prefix + "[" + _count-string(count) + "]:")
  place(top+left, dx: -1.2em - measure(txt).width, txt)
}

// "notebook" template for raw cell
#let raw(cell, ctx: none) = block(
  spacing: 1.5em,
  width: 100%,
  inset: 0.5em,
  fill: luma(240),
  handle(cell.source, mime: "text/x.source-raw-cell", ctx: ctx),
)

// "notebook" template for Markdown cell
#let markdown(cell, ctx: none) = {
  // Render as inline Markdown to integrate seamlessly in the document
  // without interference from a block container (see
  // https://github.com/knuesel/callisto/issues/13) but add parbreaks
  // to render the content as a distinct unit.
  parbreak()
  handle(cell.source, mime: "text/x.markdown-inline", ctx: ctx)
  parbreak()
}

// "notebook" template for code cell input
#let input(cell, ctx: none) = block(
  above: 2em,
  below: if ctx.cfg.output and cell.outputs.len() > 0 { 0pt } else { 2em },
  width: 100%,
  inset: 0.5em,
  fill: luma(240),
  {
    _in-out-num("In ", cell.execution_count)
    handle(cell.source, mime: "text/x.source-code-cell", ctx: ctx)
  },
)

// Styled block for error items (error outputs or stderr streams)
#let error-block = block.with(
  width: 100%,
  fill: red.lighten(90%),
  outset: 0.5em,
)

// Customized default handler for errors, rendering the traceback
#let error-handler(data, ctx: none, traceback: none, ..args) = {
  raw(traceback.join("\n"), block: true, lang: "txt")
}

// "notebook" template for code cell output
#let output(cell, ctx: none) = {
  // Change some default handlers
  ctx.cfg._default-handlers = ("text/x.error": error-handler)
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

#let cell-template =(
  raw: raw,
  markdown: markdown,
  input: input,
  output: output,
)

#let doc-template(x) = x
