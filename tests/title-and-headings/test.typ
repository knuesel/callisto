#import "/callisto.typ"

// #import "@preview/cmarker:0.1.8"

// #let handler-markdown-generic(data, ctx: none, ..args) = cmarker.render(
//   data,
//   math: callisto.handle.with(mime: "math-markdown-cell", ctx: ctx),
//   scope: (
//     image: callisto.handle.with(mime: "image-markdown-cell", ctx: ctx),
//   ),
//   heading-labels: "jupyter",
//   ..args,
// )

#set heading(numbering: "1.")

// In Jupyter when linking to a Markdown heading that includes quotes one must
// write them literally, but cmarker makes the Typst label using the heading
// returned by pulldown-cmark which by default does smartquoting, so the
// label doesn't match the link target in Typst.
// See https://github.com/SabrinaJewson/cmarker.typ/issues/39
// We can "fix" the Markdown links on the Typst side. Proof of concept:
#show link: it => {
  if "'" in str(it.dest) {
    return link(label(str(it.dest).replace("'", "’" )), it.body)
  }
  return it
}

// We can use the label in Typst though it's annoying
See @Some-heading and #ref(label("Here’s-a-heading-with-a-quote"))

#callisto.render(
  nb: json("notebook.ipynb"),
  h1-level: 0,
  // handlers: ("markdown-generic": handler-markdown-generic),
)
