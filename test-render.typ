#import "callisto.typ" as callisto: *

#[
  #let (Cell, In, Out) = callisto.config(nb: "examples/cairomakie.ipynb", count: "execution")

  #Cell(2)
  == Input
  #In(2, template: "plain")
  == Output
  #Out(2, output-args: (type: "error"), template: "plain")
]

= CairoMakie
#render(
  nb: "examples/cairomakie.ipynb",
  type: ("markdown", "code"),
  // output-args: (type: "execute_result"),
)

= Python
#render(nb: "examples/python.ipynb")

== Plain template

#show: callisto.templates.doc-template

#render(nb: "examples/python.ipynb", template: callisto.templates.plain)

