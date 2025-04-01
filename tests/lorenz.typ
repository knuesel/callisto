#import "/callisto.typ" as callisto: *

// #callisto.outputs(
//   nb: "notebooks/Lorenz.ipynb",
// )

#callisto.render(
  nb: "tests/notebooks/Lorenz.ipynb",
  // keep: range(5),
  // cmarker: (
  //   scope: (image: (path, alt: none) => image(path, alt: alt)),
  // ),
  // keep: range(3),
)
 
