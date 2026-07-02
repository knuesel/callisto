#import "/callisto.typ"

#show heading: set block(below: 1em)
#show heading.where(level: 1): set text(14pt)
#show heading.where(level: 2): set text(12pt)
#set heading(numbering: "1.")

#let (
  Cell,
  In,
  Out,
  display,
  execute,
  evaluate,
  stage-notebook,
) = callisto.config(
  nb: path("export.ipynb"),
  kernel: "python3",
)

#stage-notebook()

#show raw.where(lang: "py-x"): it => {
  set text(1em/0.8)
  execute(it)
}

```py-x
a = 1
```<a>

#Out(<a>)

#context display(query(<a>).first())

// Render an executed cell that doesn't exist
#Cell(
  ```py-x
  b = 2
  ```
)

```py-x
a = 1
```<b>

1+1: #evaluate(`1+1`)

1+1: #evaluate(`1+1`, placeholder: [(computation)])

1+1: #evaluate(`1+1`, placeholder: text.with(red))
