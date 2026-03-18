#import "/callisto.typ"

#let (render, In, Out) = callisto.config(nb: json("cell-header.ipynb"))

#render()

Neat output:
#Out("with-neat")

Neat input:
#In("with-neat")
