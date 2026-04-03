#import "/lib/reading/notebook.typ"
#import "/lib/theming.typ"
#import "/lib/configuration.typ"
#import "/lib/header-pattern.typ"
#import "preamble.typ"
#import "handling.typ"
#import "outputs.typ"
#import "cells.typ"

// The 'ctx' dict is passed to all handler calls and holds resolved settings
// (replacing most 'auto' values with resolved values) as well as contextual
// data including at least the following fields:
//
// - cfg: a dict with all the settings supported by callisto.config, using
//   default values for settings not set by the user (this holds the
//   non-resolved settings values).
// 
// - cell: the dict of the cell being processed.
//
// - item-desc: a dict with information on the cell item (output item or
//   attachment) being processed, or 'none' otherwise. When not 'none', the
//   dict contains at least the following fields:
//
//    - index: the item index in the cell output list (none for attachments),
//    - type: the output type, or "attachment" for attachments.
//
//   For rich items, this dict contains also
//    - rich-format: the format selected for this rich item
//    - metadata: the format-specific metadata if present, or full metadata
//      dict associated with this item otherwise.
// 
// - latex-preamble: a string with all the LaTeX command definitions (of the
//   `\newcommmand` form) found in the notebook, or none if gather-latex-defs
//   is false.

// Return the language name of the given notebook json
#let _nb-lang(nb-json) = {
  if nb-json == none { return none }
  if "language_info" not in nb-json.metadata {
    // This can happen when reading an unexecuted notebook exported by Callisto
    // with lang unset
    return none
  }
  return nb-json.metadata.language_info.name
}

// Build a ctx dict for the given cell and settings dict.
#let get-ctx(
  cell,
  cfg: none,
  item-desc: none,
) = {

  let nb-json = notebook.get-json(cfg: cfg)
  let ctx = cfg

  ctx.cell-header-pattern = header-pattern.resolve(
    cfg.cell-header-pattern)
  
  if ctx.lang == auto {
    ctx.lang = _nb-lang(nb-json)
  }

  ctx.name-path = cells.resolve-name-path(cfg.name-path)

  if ctx.format == auto {
    ctx.format = outputs.default-formats
  }
  ctx.format = outputs.normalize-formats(ctx.format)

  ctx.handlers = handling.all-handlers(cfg: cfg)

  if ctx.input == auto and cell != none and cell.cell_type == "code" {
    ctx.input = cells.resolve-input(cell, cfg: cfg)
  }

  if ctx.output == auto and cell != none and cell.cell_type == "code" {
    ctx.output = cells.resolve-output(cell, cfg: cfg)
  }

  ctx.ansi = (process: auto) + ctx.ansi

  ctx.read = configuration.read-enabled(cfg: cfg)
  ctx.export = configuration.export-enabled(cfg: cfg)

  let latex-preamble = none
  if ctx.gather-latex-defs {
    let cells = if nb-json == none { (cell,) } else { nb-json.cells }
    latex-preamble = preamble.latex-preamble(cells)
  }

  return ctx + (
    cfg: cfg,
    cell: cell,
    item-desc: item-desc,
    latex-preamble: latex-preamble,
  )
}
