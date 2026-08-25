#import "/callisto.typ"

#callisto.render(
  0,
  format: "text/html",
  nb: path("/tests/R/R.ipynb"),
)

#callisto.render(
  "plot1",
  format: "text/html",
  nb: path("/tests/julia/julia.ipynb"),
)

// Check that the output can be rendered without error
#let x = callisto.render(nb: path("spam-df.ipynb"), format: "text/html")
#assert.eq(type(x), content)
