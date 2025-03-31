#import "callisto.typ" as callisto: *

#callisto.render(
  nb: "notebooks/Cpp.ipynb",
  cmarker: (
    scope: (image: (path, alt: none) => image(path, alt: alt)),
  ),
)
