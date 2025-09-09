#import "@preview/cmarker:0.1.6"
#import "@preview/mitex:0.2.5": mitex

#import "/src/callisto.typ" as callisto: *

#show image: it => {
  place(dx: -5em, text(0.6em)[alt: "#it.alt"])
  it
}

#callisto.render(
  nb: json("images.ipynb"),
  handlers: (
    "image/x.generic": (data, ctx: none, ..args) => image(data, ..args),
  ),
)


Cell 3:
#callisto.render(
  3,
  nb: json("images.ipynb"),
  handlers: ("image/png": (ctx: none, ..args) => ctx.item.metadata.path),
)
