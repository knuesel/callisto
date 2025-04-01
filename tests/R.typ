#import "/callisto.typ" as callisto: *

#callisto.render(
  nb: "tests/notebooks/R.ipynb",
  format: ("image/svg+xml", "image/png", "text/plain", "text/markdown"),
)
