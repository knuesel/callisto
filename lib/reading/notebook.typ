#import "/lib/ctx/handling.typ": all-handlers

// Return the notebook as JSON, without any processing
#let nb-json(cfg: none) = {
  if cfg.nb == none {
    return none
  }
  if type(cfg.nb) not in (str, bytes, dictionary) {
    panic("invalid notebook type: " + str(type(cfg.nb)))
  }
  if type(cfg.nb) == bytes {
    return json(cfg.nb)
  }
  if type(cfg.nb) == str {
    let handlers = all-handlers(cfg: cfg)
    return json(handlers.at("path")(cfg.nb, ctx: none))
  }
  return cfg.nb
}

// Ensure each cell source is a single string.
#let normalize-cell-source(cell) = {
  if "source" in cell and type(cell.source) == array {
    cell.source = cell.source.join() // will be none if array is empty
  }
  if "source" not in cell or cell.source == none {
    cell.source = ""
  }
  return cell
}
