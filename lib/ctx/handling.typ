#import "/lib/styling.typ"

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

// Get final handlers from default, style and user handlers.
// This function gets the resolved style as parameter, rather than the
// non-resolved value from cfg.
#let all-handlers(style, cfg: none) = {
  let handlers = cfg.default-handlers
  if cfg.apply-style {
    let (template, ..style-handlers) = styling.resolve(style, cfg.named-styles)
    handlers += style-handlers
  }
  let user-handlers = _resolve-user-handlers(handlers, cfg.handlers)
  return handlers + user-handlers
}
