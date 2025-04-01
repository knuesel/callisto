#import "/callisto.typ" as callisto: *

#[
  #let (Cell, In, Out) = callisto.config(
    nb: "/tests/notebooks/julia.ipynb",
    count: "execution",
  )

  #Cell(2)
  == Input
  #In(2, template: "plain")
  == Output
  #Out(2, output-type: "error", template: "plain")
]

= Julia
#render(
  nb: "tests/notebooks/julia.ipynb",
  cell-type: ("markdown", "code"),
  // output-args: (output-type: "execute_result"),
)

= Python
#render(nb: "tests/notebooks/python.ipynb")

== Plain template

#show: callisto.templates.doc-template

#render(nb: "tests/notebooks/python.ipynb", template: callisto.templates.plain)

