#import "../common.typ": handle

// Generic preprocessing that doesn't require context (nothing to do for error)
#let preprocess(item, ctx: none) = item

// Process an error item
#let process(item, ctx: none) = handle(
  item.evalue,
  mime: "text/x.error",
  ctx: ctx,
  name: item.ename,
  traceback: item.traceback,
)
