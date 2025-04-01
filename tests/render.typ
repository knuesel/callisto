#import "/callisto.typ" as callisto: *

#[
  #let (Cell, In, Out) = callisto.config(
    nb: "/tests/notebooks/cairomakie.ipynb",
    count: "execution",
  )

  #Cell(2)
  == Input
  #In(2, template: "plain")
  == Output
  #Out(2, output-args: (type: "error"), template: "plain")
]

= CairoMakie
#render(
  nb: "tests/notebooks/cairomakie.ipynb",
  type: ("markdown", "code"),
  // output-args: (type: "execute_result"),
)

= Python
#render(nb: "tests/notebooks/python.ipynb")

== Plain template

#show: callisto.templates.doc-template

#render(nb: "tests/notebooks/python.ipynb", template: callisto.templates.plain)

