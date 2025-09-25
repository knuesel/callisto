#import "common.typ": parse-main-args
#import "reading/notebook.typ"
#import "theming.typ"

// The 'ctx' dict is passed to all handler calls and holds
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

// Get final handlers from default, theme and user handlers.
#let _all-handlers(cfg: none) = {
  let handlers = cfg.default-handlers
  if cfg.apply-theme {
    let (template, ..theme-handlers) = theming.resolve(cfg.theme, cfg.named-themes)
    handlers += theme-handlers
  }
  let user-handlers = _resolve-user-handlers(handlers, cfg.handlers)
  return handlers + user-handlers
}

// Build a ctx dict for the given cell and settings dict.
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
    handlers: _all-handlers(cfg: cfg),
    lang: if cfg.lang == auto { notebook.lang(nb) } else { cfg.lang }
  )
}
