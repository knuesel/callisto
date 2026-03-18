#let style = (
  "text/plain": (data, ..args) => raw(data, block: true, lang: "txt"),
  stream-generic: (data, ..args) => raw(data, block: true, lang: "txt"),
  error: (data, ..args) => raw(data.evalue, block: true, lang: "txt"),
)
