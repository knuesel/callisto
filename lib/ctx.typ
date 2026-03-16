#import "@preview/cmarker:0.1.8"

#import "common.typ"
#import "header-pattern.typ"
#import "latex.typ"
#import "theming.typ"

// TODO: rewrite, now ctx is simply a resolved cfg + extra contextual fields:
// - cell
// - item-desc
// The 'ctx' dict is passed to all handler calls and holds
// contextual data including at least the following fields:
//
// - cell: the dict of the cell being processed
//
// - cfg: a dict with all the settings supported by callisto.config, using
//   default values for settings not set by the user.
// 
// - item-desc: a dict with information on the cell item (output item or attachment)
//   being processed, or 'none' otherwise. When not 'none', the dict contains
//   at least the following fields:
//
//    - index: the item index in the cell output list (none for attachments),
//    - type: the output type, or "attachment" for attachments.
//
//   For rich items, this dict contains also
//    - rich-format: the format selected for this rich item
//    - metadata: the format-specific metadata if present, or full metadata
//      dict associated with this item otherwise.
// 
// - nb: a processed version of the notebook, with metadata in cell source
//   headers converted to metadata in the cell dict.
// 
// - handlers: the final list of handlers (including both default handlers
//   and user handlers).
// 
// - lang: the language set by the user (equal to 'cfg.lang') or, if that value
//   is 'auto', the language inferred from the notebook if available and 'none'
//   'none' otherwise.

// A handler function that composes the functions specified in the given list.
// If a list value is 'none' instead of a function, the next function is called
// with 'none' as argument.
#let _composed-handler(list, data, ..args) = list.fold(
  data,
  (value, f) => if f == none { none } else { f(value, ..args) },
)

// Given a default handler and the user value, return a resolved handler, which
// is always a function or none.
#let _resolve-one-handler(default-handler, mime, value) = {
  if value == auto {
    return default-handler
  }
  if type(value) == array {
    // Replace auto with default
    let list = value.map(x => if x == auto { default-handler } else { x })
    return _composed-handler.with(list)
  }
  if type(value) == function or value == none {
    return value
  }
  panic("invalid handler type \"" + repr(type(value)) + "\" for handler "
    + repr(value))
}

// Given the default handler dict and user handler dict, return a dict of
// resolved user handlers, where each value is a handler function or none.
// Each user handler can be given as none or auto or a function or an array of
// values representing functions to compose, where the auto value represent the
// default handler.
#let _resolve-user-handlers(default, user) = {
  if user == auto { return (:) }
  if type(user) != dictionary {
    panic("handlers must be auto or a dictionary mapping formats to functions")
  }
  for (k, v) in user.pairs() {
    if k not in default {
      panic("unknown handler " + repr(k) +
        " (custom handlers must be registered with default-handlers)")
    }
    ((k): _resolve-one-handler(default.at(k), k, v))
  }
}

// Return the language name of the given notebook json
#let _lang(nb-json) = {
  if nb-json == none { return none }
  if "language_info" not in nb-json.metadata {
    // This can happen when reading an unexecuted notebook exported by Callisto
    // with lang unset
    return none
  }
  return nb-json.metadata.language_info.name
}

// Wrap the math item arguments in a labelled metadata
#let _math-metadata(..args) = [#metadata(args)<__callisto-math-item>]

// Return true if the content item is an extracted math item
#let _is-math-item(it) = it.at("label", default: none) == <__callisto-math-item>

// Extract an array of math items from the given Markdown string.
// Each item is returned as an 'arguments' value holding the arguments that
// cmarker passes to the 'math' callback for rendering the math item.
// This includes at least
// - a positional argument for the string holding the LaTeX math
// - a 'block' argument set to true for block equations
#let _extract-math(markdown) = {
  let rendered = cmarker.render(
    markdown,
    math: _math-metadata,
    scope: (image: (..args) => none),
    heading-labels: "jupyter",
  )
  // For sequence, gather all math items among the children
  if rendered.func() == [].func() {
    return rendered.children.filter(_is-math-item).map(x => x.value)
  }
  // Otherwise we have at most one item
  if _is-math-item(rendered) {
    return (rendered.value,)
  }
  return ()
}

// Get the LaTeX definitions found in the math items in the given cell.
// Each item is returned as a regex match in which the 'text' field
// holds the command definition.
#let _cell-latex-defs(c) = {
  _extract-math(c.source)
    .map(args => latex.definitions(args.at(0)))
    .join()
}

// Do minimal processing on unprocessed notebook JSON to ensure each cell
// source is a single string.
#let _normalize-cell-source(cell) = {
  if "source" in cell and type(cell.source) == array {
    cell.source = cell.source.join() // will be none if array is empty
  }
  if "source" not in cell or cell.source == none {
    cell.source = ""
  }
  return cell
}

// Gather all LaTeX \newcommand definitions from the previous and current cells
// in the notebook (if provided) or just in the current cell (if provided and
// the notebook is not) and return the corresponding LaTeX preamble as string.
// This is done to support commands defined in one Markdown LaTeX equation and
// used in a later one (as supported by MathJax and often used in Jupyter
// notebook although it's not valid in real LaTeX). There are two caveats:
// 1. Only '\newcommand' gets this special treatment. MathJax also supports
//    definitions through '\def', '\newenvironment', '\renewcommand', etc. but
//    these don't get any special treatment here.
// 2. MathJax allows using '\newcommand' instead of '\renewcommand' to
//    redefine an existing command, while LaTeX and MiTeX do not. There's no
//    good way for us to support this
//    in the general case (e.g. when a single equation defines a command
//    several times with different values) so we only allow duplicate
//    definitions when they are redundant (redefining a command to the same
//    value) and raise an error otherwise. This covers the most common case
//    of duplicate definitions, where an equation or cell is duplicated by
//    copy-paste.
#let _latex-preamble(nb-json, cell) = {
  if cell == none or cell.cell_type != "markdown" {
    return none
  }

  // Cells from which to extract definitions for preamble
  let cells = ()
  if nb-json != none {
    // Get all previous cells
    cells = nb-json.cells
      .slice(0, cell.index)
      .filter(c => c.cell_type == "markdown")
      .map(_normalize-cell-source)
  }
  cells.push(cell)

  // Get array of matches for command definitions
  let defs = cells.map(_cell-latex-defs).join()
  if defs == none {
    return none
  }

  // Convert array to preamble string
  return latex.make-preamble(defs)
}

// Build a ctx dict for the given cell and settings dict.
#let get-ctx(
  cell,
  cfg: none,
  item-desc: none,
) = {
  let nb-json = common.nb-json(cfg: cfg)

  let lang = cfg.lang
  if lang == auto {
    lang = _lang(nb-json)
  }

  let latex-preamble = cfg.latex-preamble
  if latex-preamble == auto {
    latex-preamble = _latex-preamble(nb-json, cell)
  }
  
  return cfg + (
    // Fields specific to ctx
    cell: cell,
    item-desc: item-desc,
    cfg: cfg,
    // Resolved values for cfg fields
    lang: lang,
    handlers: common.all-handlers(cfg: cfg),
    latex-preamble: latex-preamble,
  )
}
