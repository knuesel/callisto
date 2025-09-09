#import "common.typ": parse-main-args
#import "reading/notebook.typ"
#import "handlers.typ"

// The 'ctx' dict is passed to all handler and template calls and holds
// contextual data including at least the following fields:
//
// - cell: the dict of the cell being processed
//
// - cfg: a dict with all the settings supported by callisto.config, using
//   default values for settings not set by the user.
// 
// - item: a dict with information on the cell item (output item or attachment)
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
#let _handlers(user-handlers) = {
  if user-handlers != auto and type(user-handlers) != dictionary {
    panic("handlers must be auto or a dictionary mapping formats to functions")
  }
  if user-handlers == auto {
    user-handlers = (:)
  }
  return handlers.mime-handlers + user-handlers
}

// Build a ctx dict for the given cell and settings dict
#let get-ctx(
  cell,
  cfg: none,
  item: none,
) = {
  let nb = notebook.read(cfg.nb, cfg: cfg)
  return (
    cell: cell,
    cfg: cfg,
    item: item,
    nb: nb,
    handlers: _handlers(cfg.handlers),
    lang: if cfg.lang == auto { notebook.lang(nb) } else { cfg.lang }
  )
}
