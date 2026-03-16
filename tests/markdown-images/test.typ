#import "/callisto.typ" as callisto: *

#show image: it => {
  place(dx: -5em, text(0.6em)[alt: "#it.alt"])
  it
}

#callisto.render(
  nb: json("images.ipynb"),
  handlers: (path: (x, ..args) => read(x, encoding: none)),
)


Cell 3 showing attachment path instead of content:
#callisto.render(
  3,
  nb: json("images.ipynb"),
  handlers: ("image/png": (ctx: none, ..args) => raw(ctx.item-desc.metadata.path)),
)
