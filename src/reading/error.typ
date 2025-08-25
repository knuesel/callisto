#import "../common.typ": handle

// Process an error item
#let process-output(item, ctx: none) = (
  type: "error",
  value: handle(
    item.evalue,
    "text/x.error",
    name: item.ename,
    traceback: item.traceback,
    ctx: ctx,
  ),
  raw-value: item.evalue,
  name: item.ename,
  traceback: item.traceback,
)
