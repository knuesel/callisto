#import "/lib/util.typ": handle

#let theme = (
  // Render text outputs as raw blocks
  "text/plain": handle.with(mime: "text-ansi-block"),
  stream-generic: handle.with(mime: "text-ansi-block"),
  error: (data, ..args) => handle(data.evalue, ..args, mime: "text-ansi-block"),
)
