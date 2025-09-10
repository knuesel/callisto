// #show raw.where(lang: "python-x"): it => raw(lang: "python", it.text)
#import "/src/exporting.typ": notebook-export, tag-raw-blocks

#show: tag-raw-blocks.with(lang: "python", label: <xxx>)

// #show raw.where(lang: "python-x"): it => {
//   it
//   let lbl = label("_callisto-raw:" + it.lang)
//   [#metadata(it.text)#lbl]
// }


// #show raw.where(block: true, lang: "python"): it => {
//   if it.at("label", default: none) != none { return it }
//   [#raw(block: true, lang: "x", it.text)<xxx>]
// }


#notebook-export(target: <xxx>, raw-lang: "python")

```python
a = 1
b = 2
c = a + b
```

// #context [#metadata(query(<execute>)) <md>]


```python
(a, b, c)
```


```python
x = 1
y = 2
x * y
```
