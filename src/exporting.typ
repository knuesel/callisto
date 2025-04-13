#let make-cell(i, src) = {
  (
    id: str(i),
    cell_type: "code",
    metadata: (:),
    source: src,
    outputs: (),
    execution_count: none,
  )
}

#let make-nb(sources, kernel-spec, language-info) = (
  cells: sources.enumerate().map(x => make-cell(..x)),
  metadata: (
    language_info: language-info,
    ..if kernel-spec != none { (kernelspec: kernel-spec) },
  ),
  nbformat: 4,
  nbformat_minor: 5
)

#let make-language-info(lang-info, kernel-spec, raw-lang) = {
  if lang-info != auto {
    return lang-info
  }
  if kernel-spec != none and "language" in kernel-spec {
    return (name: kernel-spec.language)
  }
  return (name: raw-lang.trim("-x", at: end))
}

#let export-metadata(raw-lang, kernel-spec: none, lang-info: auto) = context {
  let sources = query(label("_callisto-raw:" + raw-lang)).map(x => x.value)
  let language-info = make-language-info(lang-info, kernel-spec, raw-lang)
  let data = make-nb(sources, kernel-spec, language-info)
  let lbl = label("callisto:" + raw-lang)
  [#metadata(data)#lbl]
}
