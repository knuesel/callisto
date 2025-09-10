// Make a JSON cell for the given source code, deriving an ID from the given
// cell index.
#let _make-cell(i, src) = {
  (
    id: str(i),
    cell_type: "code",
    metadata: (:),
    source: src,
    outputs: (),
    execution_count: none,
  )
}

// Return a notebook metadata dictionary built from the given language info
// and kernel spec. If language-info is auto, a bare-bones version is inferred
// from raw-lang.
#let _metadata(lang-info, kernel-spec, raw-lang) = {
  let md = (:)
  if kernel-spec != none {
    md.kernelspec = kernel-spec
  }  
  if lang-info == auto {
    lang-info = (name: raw-lang)
  }
  md.language_info = lang-info
  return md
}

#let _target-value(item) = {
  if type(item) == content {
    if item.func() == raw { return item }
    if item.func() == metadata { return item.value }
  }
  panic("unsupported export target type: " + str(type(item) + ": " + repr(item)))
}
#let _target-lang(item) = _target-value(item).lang
#let _target-text(item) = _target-value(item).text

// Returns the metadata (in an opaque context) required for exporting a
// Jupyter notebook containing the target raw blocks as code cells.
// The export can be obtained using a command such as
//
//   typst query --pretty --one --field=value file.typ '<callisto-nb:python>' > file.ipynb
//
// This should generate a valid Jupyter notebook named file.ipynb. This
// notebook can be executed with
// 
//   jupyter nbconvert --to notebook --execute --inplace test.ipynb 
// 
// Parameters:
//
// - name: the name to use as label for the exported data. If auto, a name
//   of the form 'callisto-<raw-lang>' will be used.
// 
// - target: a selector for the pieces of source code to export. The supported
//   items are
//   - raw values (raw.text is exported)
//   - metadata containing a dict with text and lang fields (text is exported)
// 
// - metadata: a dict with the notebook metadata. If auto, the metadata will
//   be generated from the lang-info and kernel-spec.
// 
// - lang-info: the notebook language_info dictionary. If auto, a bare-bones
//   version will be generated from kernel-spec.name or raw-lang.
//
//   This dictionary must include a 'name' field. Usually also includes fields
//   'file_extension', 'mimetype' and 'version'.
// 
// - kernel-spec: the notebook kernelspec dictionary, or none.
//
//   This dictionary must include the fields 'name', 'language' and
//   'display_name'. The 'name' field must be a valid kernel name on the
//   system where the notebook will be executed. A kernel has the name 'xxx'
//   when its specification is found in a file 'kernels/xxx/kernel.json'.
// 
// - raw-lang: the programming language of the target raw blocks. If auto,
//   the 'lang' field of the first target found will be used.
// 
// - nbformat: the Jupyter Notebook format version, as a string (default: "4.5")
#let _notebook-export(
  name: auto,
  target: auto,
  metadata: auto,
  lang-info: auto,
  kernel-spec: none,
  raw-lang: auto,
  nbformat: "4.5",
) = {
  if target == auto and raw-lang == auto {
    panic("either 'target' or 'raw-lang' must be specified")
  }
  if target == auto {
    target = raw.where(block: true, lang: raw-lang)
  }
  let targets = query(target)
  if raw-lang == auto {
    if targets.len() == 0 {
      panic("cannot infer raw-lang when no targets are found")
    }
    raw-lang = _target-lang(targets.first())
  }
  if name == auto {
    name = "callisto-nb:" + raw-lang
  }
  if metadata == auto {
    metadata = _metadata(lang-info, kernel-spec, raw-lang)
  }
  let sources = targets.map(_target-text)
  let cells = sources.enumerate().map(x => _make-cell(..x))
  let (major, minor) = nbformat.split(".").map(int)
  let nb = (
    cells: cells,
    metadata: metadata,
    nbformat: major,
    nbformat_minor: minor,
  )
  let lbl = label(name)
  [#std.metadata(nb)#lbl]
}

#let notebook-export(..args) = context _notebook-export(..args)

#let tag-raw-blocks(doc, lang: none, label: auto) = {
  if lang == none { panic("lang of target raw blocks not specified") }
  if label == auto {
    label = std.label("callisto-raw:" + lang)
  }
  show raw.where(block: true, lang: lang): it => {
    it
    [#metadata((text: it.text, lang: lang))#label]
  }
  doc
}
