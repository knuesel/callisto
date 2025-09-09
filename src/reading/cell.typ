#import "../common.typ": ensure-array, parse-main-args

#import "notebook.typ"

#let default-cell-names = ("metadata.label", "id", "metadata.tags")
#let all-cell-types = ("code", "markdown", "raw")

// Get value at given path in recursive dict.
// The path can be a string of the form `key1.key2....`, or an array
// `(key1, key2, ...)`.
#let at-path(dict, path, default: none) = {
  if type(path) == str { return at-path(dict, path.split(".")) }
  let (key, ..rest) = path
  if key not in dict { return default }
  let value = dict.at(key)
  if rest == () { return value }
  return at-path(value, rest)
}

// Tests whether the cell name matches the user cell spec.
// The 'name' value is interpreted as a path of the form 'x.y.z' in the cell
// dict.
#let name-matches(cell, spec, name) = {
  let value = at-path(cell, name)
  return value == spec or (type(value) == array and spec in value)
}

// List of cell types for the given cell type spec
#let _cell-types(cell-type) = {
  if cell-type == "all" { return all-cell-types }
  let types = ensure-array(cell-type)
  for typ in types {
    if typ not in all-cell-types {
      panic("invalid cell type: " + repr(typ))
    }
  }
  return types
}

// Filter the cell list according to the cell type setting
#let _filter-type(cells, cell-type) = {
  let types = _cell-types(cell-type)
  cells.filter(x => x.cell_type in types)
}

// Resolve 'name-path' setting to an array of name paths
#let _name-paths(path) = {
  if path == auto { return default-cell-names }
  return ensure-array(path)
}

// Get cell indices for a single specification.
// If no cell matches, an empty array is returned.
// The cells-of-type array contains cells already filtered to match cell-type.
// The all-cells array contains all cells and can be used for performance for
// cells specified by their index.
#let _cell-indices(spec, cells-of-type, all-cells, cfg: none) = {
  if type(spec) == dictionary {
    // Literal cell
    return _filter-type((spec,), cfg.cell-type).map(c => c.index)
  }
  if type(spec) == function {
    // Filter with given predicate
    return cells-of-type.filter(spec).map(c => c.index)
  }
  if type(spec) == str {
    // Match on any of the specified names
    let names = _name-paths(cfg.name-path)
    return cells-of-type
      .filter(x => names.any(name-matches.with(x, spec)))
      .map(c => c.index)
  }
  if type(spec) == int {
    if cfg.count == "index" {
      let type-ok = all-cells.at(spec).cell_type in _cell-types(cfg.cell-type)
      return if type-ok { (spec,) } else { () }
    }
    if cfg.count == "execution" {
      // Different cells can have the same execution_count, e.g. when
      // evaluating only some cells after a kernel restart.
      return cells-of-type
        .filter(x => x.at("execution_count", default: none) == spec)
        .map(c => c.index)
    }
    panic("invalid cell count mode:" + repr(cfg.count))
  }
  panic("invalid cell specification: " + repr(spec))
}

// Filter the cell list according to the 'keep' setting
#let _apply-keep(cells, keep) = {
  if keep == "all" {
    return cells
  }
  if keep == "unique" {
    if cells.len() != 1 {
      panic("expected 1 cell, found " + str(cells.len()))
    }
    return cells
  }
  if type(keep) == int {
    return (cells.at(keep),)
  }
  if type(keep) == array {
    return keep.map(i => cells.at(i))
  }
  panic("invalid keep value: " + repr(keep))
}

// Return the cells matching the given user spec.
// The spec can a literal cell or array thereof in which case it is simply
// filtered according to the cfg settings. Otherwise, cells will be read from
// the notebook specified in the cfg settings before filtering.
#let _cells-from-spec(spec, cfg: none) = {
  if type(spec) == dictionary and "id" not in spec and "nbformat" in spec {
    panic("invalid literal cell, did you forget the 'nb:' keyword " +
      "while passing a notebook?")
  }
  if type(spec) == dictionary or (
     type(spec) == array and spec.all(x => type(x) == dictionary)) {
    // No need to read the notebook
    return _filter-type(ensure-array(spec), cfg.cell-type)
  }
  let all-cells = notebook.read(cfg.nb, cfg: cfg).cells
  let cells-of-type = _filter-type(all-cells, cfg.cell-type)
  if spec == none {
    // No spec means select all cells
    return cells-of-type
  }
  let indices = ()
  for s in ensure-array(spec) {
    indices += _cell-indices(s, cells-of-type, all-cells, cfg: cfg)
  }
  return indices.dedup().sorted().map(i => all-cells.at(i))
}

// Cell selector: return an array of cells according to the cell specification.
// The function accepts one optional position argument, plus any config
#let cells(..args, keep: "all") = {
  let (cell-spec, cfg) = parse-main-args(args)
  let cs = _cells-from-spec(cell-spec, cfg: cfg)
  return _apply-keep(cs, cfg.keep)
}

// Select a single cell
#let cell(..args, keep: "unique") = cells(..args, keep: keep).first()
