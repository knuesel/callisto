#import "/lib/header-pattern.typ": make-header-text
#import "/lib/rendering.typ": render
#import "/lib/reading/reading.typ"
#import "config.typ"

// Make label for exported raw elements
#let _export-label(name) = label("__callisto-export:" + name)

#let export(..args) = {
  // The cell-spec is actually a raw element in this case
  let (cell-spec: elem, cfg) = config.parse-main-args(..args)
  if type(elem) != content or elem.func() != raw {
    panic("expecting a raw element, got " +
      repr(if type(elem) == content { elem.func() } else { type(elem) }))
  }

  let header = make-header-text(
    cfg.cell-header,
    pattern: cfg.cell-header-pattern,
  )

  // We store the raw fields rather than the raw element itself, to avoid
  // having it show up in query(raw)
  let dict = (
    export-name: cfg.export-name,
    kernel: cfg.kernel,
    text: header + elem.text,
    lang: elem.at("lang", default: none),
    block: elem.at("block", default: true),
    label: elem.at("label", default: none),
  )
  return [#metadata(dict)#_export-label(cfg.export-name)]
}

// Make cell metadata for given raw element dict
#let _cell-metadata(elem) = (
  callisto: (
    export: (
      lang: elem.lang,
      block: elem.block,
      typst-label: if elem.label == none { none } else { str(elem.label) },
    ),
  ),
)

// Make a JSON cell for the given raw element dict, deriving an ID from the
// given cell index.
#let _make-cell(i, elem) = {
  (
    id: "id" + str(i),
    cell_type: "code",
    metadata: _cell-metadata(elem),
    source: elem.text,
    outputs: (),
    execution_count: none,
  )
}

// Make notebook metadata
#let _notebook-metadata(kernel, lang) = {
  // A kernelspec must contain a display name, but it's
  // not used to find the kernel so we can pick one ourselves
  let kernel-spec = (name: kernel, display_name: kernel)
  let md =  (kernelspec: kernel-spec)
  // The language info is normally written by the kernel upon execution, but it
  // can be helpful to set it in case the notebook is read without execution
  if lang not in (auto, none) {
    md.language_info = (name: lang)
  }
  return md
}

// Make a notebook dictionary from the given raw elements (or dicts with the
// same fields as raw), language_info and kernelspec. The lang parameter is used
// to infer lang-info if unspecified.
// If lang is auto, the lang of the first element is used.
#let notebook-from-raw-elements(elems, kernel, lang) = {
  let cells = elems.enumerate().map(x => _make-cell(..x))
  let md
  let nb = (
    cells: cells,
    metadata: _notebook-metadata(kernel, lang),
    nbformat: 4,
    nbformat_minor: 5,
  )
  return nb
}

// TODO: update this docstring
// Returns the metadata (in an opaque context) required for exporting a
// Jupyter notebook containing the target raw blocks as code cells.
// The export can be obtained using a command such as
//
//   typst query --input callisto-export=true --pretty --one --field=value \
//     file.typ '<export-name>' > file.ipynb
//
// This should generate a valid Jupyter notebook named file.ipynb. This
// notebook can be executed with
// 
//   jupyter nbconvert --to notebook --execute --inplace file.ipynb 
// 
// Parameters:
//
// - name: the name of the export, used to find the blocks to export and to
//   label the metadata when embedding the exported notebook.
// 
// - lang: the programming language of the notebook being exported. If auto,
//   the 'lang' field will be inferred from the target: if the target is a
//   string, it will be used as lang. If it is a selector, the lang of the
//   first matching raw block will be used.
// 
// - kernel-spec: the notebook kernel spec dictionary, or none.
//
//   This dictionary must include the fields 'name', 'language' and
//   'display_name'. The 'name' field must be a valid kernel name on the
//   system where the notebook will be executed. A kernel has the name 'xxx'
//   when its specification is found in a file 'kernels/xxx/kernel.json'.
//
//   The notebook can be exported without a kernelspec dict. In that case
//   Jupyter will try to find a kernel that matches the language in
//   language_info.
// 
// - lang-info: the notebook language_info dictionary. If auto, a bare-bones
//   version will be generated from kernel-spec.language or lang.
//
//   This dictionary must include a 'name' field. Usually also includes fields
//   'file_extension', 'mimetype' and 'version'.
// 
// - nbformat: the Jupyter Notebook format version, as a string (default: "4.5")
#let make-notebook(..args) = {
  let (cell-spec, cfg) = config.parse-main-args(..args)

  // Check that no cell specification was given
  if cell-spec != none {
    panic("unexpected argument: " + repr(cell-spec))
  }

  // Get all raw elements to export
  let elems = query(_export-label(cfg.export-name)).map(x => x.value)

  // Default kernel is taken from metadata of fist exported raw element.
  // This way a simple
  // `typst eval '#import "@preview/callisto:0.3.0"; #callisto.make-notebook()"`
  // can work.
  let kernel = cfg.kernel
  if kernel == none and elems.len() > 0 {
    kernel = elems.first().kernel
  }

  if kernel == none {
    panic("the Jupyter kernel must be specified")
  }

  return notebook-from-raw-elements(elems, kernel, cfg.lang)
}

// Return the labelled metadata that should be inserted in the document so that
// `typst query` can find the exported notebook.
#let stage-notebook(..args) = context {
  let (cfg,) = config.parse-main-args(..args)
  let md = metadata(make-notebook(..args))
  return [#md#label(cfg.export-name)]
}

// Export the given raw element and render it.
// The export is always done unless explicitly disabled with export=false.
#let execute(..args) = export(..args) + render(..args, keep: "unique")

// Copy export binding for when it's shadowed by a function parameter
#let _export = export

// Return the export metadata if export is true (or auto and the
// callisto-export sys.input is "true") or return the single execution output
// otherwise.
// This function defines a non-standard default value for export.
#let evaluate(..args, export: auto) = {
  if export == auto {
    export = sys.inputs.at("callisto-export", default: "false") == "true"
  }
  let all-args = arguments(..args, export: export)
  let (cell-spec: elem, cfg) = config.parse-main-args(..all-args)
  if export {
    return _export(..all-args)
  }
  let item = reading.single-item(reading.output.outputs, all-args)
  if cfg.transform == none {
    return item
  }
  return (cfg.transform)(item)
}
