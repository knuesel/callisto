#import "/lib/reading/notebook.typ"
#import "/lib/theming.typ"
#import "/lib/config.typ"
#import "/lib/header-pattern.typ"
#import "preamble.typ"
#import "handling.typ"
#import "outputs.typ"
#import "cells.typ"

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

  let nb-json = notebook.nb-json(cfg: cfg)
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

  ctx.read = config.read-enabled(cfg: cfg)

  let latex-preamble = none
  if ctx.gather-latex-defs {
    let cells = if nb-json == none { (cell,) } else { nb-json.cells }
    latex-preamble = preamble.latex-preamble(cells)
  }

  return ctx + (
    cell: cell,
    item-desc: item-desc,
    cfg: cfg,
    latex-preamble: latex-preamble,
  )
}
