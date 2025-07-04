#import "@preview/cmarker:0.1.3"
#import "@preview/mitex:0.2.5": mitex

#import "/src/callisto.typ" as callisto: *

#callisto.render(
  nb: json("Cpp.ipynb"),
  handlers: (
    "image/x.path": (path, alt: none) => image(path, alt: alt),
  ),
)
