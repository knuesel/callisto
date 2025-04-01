#import "/callisto.typ" as callisto: *

#callisto.render(
  nb: "tests/notebooks/R.ipynb",
  output-args: (format: ("image/svg+xml", "image/png", "text/plain", "text/markdown")),
  // cmarker: (
  //   scope: (image: (path, alt: none) => image(path, alt: alt)),
  // ),
  // keep: range(3),
)
