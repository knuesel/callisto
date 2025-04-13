// #show raw.where(lang: "python-x"): it => raw(lang: "python", it.text)
#import "/src/exporting.typ": *

#show raw.where(lang: "python-x"): it => {
  it
  let lbl = label("_callisto-raw:" + it.lang)
  [#metadata(it.text)#lbl]
}

#export-metadata("python-x")

```python-x
a = 1
b = 2
c = a + b
```

// #context [#metadata(query(<execute>)) <md>]


```python-x
(a, b, c)
```


```python-x
x = 1
y = 2
x * y
```
