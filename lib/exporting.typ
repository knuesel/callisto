#import "/lib/header-pattern.typ"
#import "/lib/rendering.typ"
#import "/lib/reading/reading.typ"
#import "configuration.typ"

// Make label for exported raw elements
#let _export-label(name) = label("__callisto-export:" + name)

// Return the export metadata for the given raw element.
// Note that the 'export' setting makes no difference for this function.
#let export(..args) = {
  // The cell-spec is a raw element in this case
  let (cell-spec: elem, cfg) = configuration.parse-main-args(..args)
  if type(elem) != content or elem.func() != raw {
    panic("expecting a raw element, got " +
      repr(if type(elem) == content { elem.func() } else { type(elem) }))
  }

  // First get header dict and rest of source from raw source
  let parsed = header-pattern.parse-text(
    elem.text,
    pattern: cfg.cell-header-pattern,
  )
  // Now make header text from combined config header and source header
  let header-text = header-pattern.make-text(
    cfg.cell-header + parsed.header,
    pattern: cfg.cell-header-pattern,
  )

  // We store the raw fields rather than the raw element itself, to avoid
  // having it show up in `query(raw)`
  let dict = (
    export-name: cfg.export-name,
    kernel: cfg.kernel,
    text: header-text + parsed.code,
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

// Return the metadata required for exporting a Jupyter notebook containing
// as code cells all the raw blocks exported with the configured export-name.
//
// This function requires context, and returns the exported notebook even
// if the export setting is false (so it can be used for example to embed the
// exported notebook as PDF attachment during normal compilation).
// 
// The exported notebook can be obtained from the command line using a command
// such as
//
//   typst query --input callisto-export=true --one --field=value \
//     file.typ '<export-name>' > file.ipynb
//
// This should generate a valid Jupyter notebook named file.ipynb. This
// notebook can be executed with
// 
//   jupyter nbconvert --to notebook --execute --inplace file.ipynb 
#let make-notebook(..args) = {
  let (cell-spec, cfg) = configuration.parse-main-args(..args)

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

// Return the labeled metadata that should be inserted in the document so that
// `typst query` can find the exported notebook.
#let stage-notebook(..args) = {
  let (cfg,) = configuration.parse-main-args(..args)
  if not configuration.export-enabled(cfg: cfg) {
    return none
  }
  return context {
    let md = metadata(make-notebook(..args))
    return [#md#label(cfg.export-name)]
  }
}

// Copy export binding for when it's shadowed by a function parameter
#let _export = export

// Export the given raw element and render it.
// This function defines a non-standard default value for export:
// the export is always done unless explicitly disabled with export=false.
#let execute(..args, export: true) = {
  let all-args = arguments(..args, export: export)
  let (cfg,) = configuration.parse-main-args(..all-args)
  if configuration.export-enabled(cfg: cfg) {
    _export(..all-args)
  }
  rendering.render(..all-args, keep: "unique")
}

// Export the given raw element and return the unique output.
// Return the export metadata if export is true (or auto and the
// callisto-export sys.input is "true") or return the unique execution output
// otherwise.
#let evaluate(..args) = {
  let (cfg,) = configuration.parse-main-args(..args)
  if configuration.export-enabled(cfg: cfg) {
    return _export(..args)
  }
  if configuration.read-enabled(cfg: cfg) == false {
    return none
  }
  let item = reading.single-item(reading.output.outputs, args)
  if cfg.transform == none {
    return item
  }
  return (cfg.transform)(item)
}
