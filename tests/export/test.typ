#import "/callisto.typ"

#let (render, source, outputs, Cell, export, make-notebook) = callisto.config(
  nb: "export.ipynb",
  handlers: (path: (x, ..args) => read(x, encoding: none)),
  // handlers: (path: (x, ..args) => path(x)),
  // disabled: true,
  // export-name: "x",
  kernel: "julia-1.11",
)

#context[#metadata(make-notebook())<notebook>]

// #metadata(make-notebook(kernel: "julia-1.11", export-name: "export.ipynb"))<notebook>

#show <g>: export

#show raw.where(block: true): set block(fill: luma(240), inset: 3pt)

// #show raw.where(block: true): it => {
//   if it.text.contains(regex("^#\| ")) {
//     return raw(block: true, lang: it.lang, it.text.replace(regex("^#\| .*\n"), ""))
//   }
//   return it
// }

```python
#| label: x
a = 1
b = 2
c = a + b
c
```<g>


```python
#| label: y
2+2 |> inv
```<g>

dd

#rect[
  This is cell "x":
  #Cell("x")
]

#outputs("y")

#context (query(<g>).len())


