#import "/callisto.typ" as callisto: *

#callisto.render(
  nb: "tests/notebooks/Cpp.ipynb",
  cmarker: (
    scope: (image: (path, alt: none) => image(path, alt: alt)),
  ),
)
