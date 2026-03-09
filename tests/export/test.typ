#import "/callisto.typ"

#let (cell, render, source, outputs, Cell, Out, export, stage-notebook) = callisto.config(
  nb: "export.ipynb",
  handlers: (path: (x, ..args) => read(x, encoding: none)),
  // handlers: (path: (x, ..args) => path(x)),
  // disabled: true,
  // export-name: "x",
  // kernel: "julia-1.11",
  // lang: "python",
  kernel: "python3",
)

#stage-notebook()

// #cell(```
// #| label: y
// 2+2
// ```)

// typst eval '#import "@preview/callisto:0.3.0"; #callisto.make-notebook()'
// typst eval '#import "@preview/callisto:0.3.0"; #callisto.make-notebook(lang="python")'
//

#context text.size
#show <g>: it => rect(it) + export(it) + render(it)

// Not implemented yet
// #show <g>: it => export(it) + render(it)

```python
#| label: x
a = 1
b = 2
c = a + b
c
```<g>


```python
#| label: y
2+2
```<g>


```python
[1,2,3]
```<g>


// TODO: should panic!
// #Out("help")

Outputs of cell `y`:
#outputs("y")

Render:
#render(<g>)
End
