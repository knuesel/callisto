#import "common.typ": ensure-array

#import "notebook.typ"

#let default-cell-names = ("metadata.label", "id", "metadata.tags")

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

#let name-matches(cell, spec, name) = {
  let value = at-path(cell, name)
  return value == spec or (type(value) == array and spec in value)
}

#let _cell-type-array(cell-type) = {
  if cell-type == "all" {
    cell-type = ("code", "markdown", "raw")
  }
  return ensure-array(cell-type)
}

#let _filter-type(cells, cell-type) = {
  let types = _cell-type-array(cell-type)
  cells.filter(x => x.cell_type in types)
}

// Get cell indices for a single specification.
// If no cell matches, an empty array is returned.
// The cells-of-type array contains cells already filtered to match cell-type.
// The all-cells array contains all cells and can be used for performance for
// cells specified by their index.
#let _cell-indices(
  spec,
  cell-type,
  cells-of-type,
  all-cells,
  count,
  name-path,
) = {
  if type(spec) == dictionary {
    // Literal cell
    return _filter-type((spec,), cell-type).map(c => c.index)
  }
  if type(spec) == function {
    // Filter with given predicate
    return cells-of-type.filter(spec).map(c => c.index)
  }
  if type(spec) == str {
    // Match on any of the specified names
    let names = if name-path == auto {
      default-cell-names
    } else {
      ensure-array(name-path)
    }
    return cells-of-type
      .filter(x => names.any(name-matches.with(x, spec)))
      .map(c => c.index)
  }
  if type(spec) == int {
    if count == "index" {
      let type-ok = all-cells.at(spec).cell_type in _cell-type-array(cell-type)
      return if type-ok { (spec,) } else { () }
    }
    if count == "execution" {
      // Different cells can have the same execution_count, e.g. when
      // evaluating only some cells after a kernel restart.
      return cells-of-type
        .filter(x => x.at("execution_count", default: none) == spec)
        .map(c => c.index)
    }
    panic("invalid cell count mode:" + repr(count))
  }
  panic("invalid cell specification: " + repr(spec))
}

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

#let _cells-from-spec(
  spec,
  nb,
  count,
  name-path,
  cell-type,
  cell-header-pattern,
  keep-cell-header,
) = {
  if type(spec) == dictionary and "id" not in spec and "nbformat" in spec {
    panic("invalid literal cell, did you forget the 'nb:' keyword " +
      "while passing a notebook?")
  }
  if type(spec) == dictionary or (
     type(spec) == array and spec.all(x => type(x) == dictionary)) {
    // No need to read the notebook
    return _filter-type(ensure-array(spec), cell-type)
  }
  let all-cells = notebook.read(
    nb,
    cell-header-pattern,
    keep-cell-header,
  ).cells
  let cells-of-type = _filter-type(all-cells, cell-type)
  if spec == none {
    // No spec means select all cells
    return cells-of-type
  }
  let indices = ()
  for s in ensure-array(spec) {
    indices += _cell-indices(
      s,
      cell-type,
      cells-of-type,
      all-cells,
      count,
      name-path,
    )
  }
  return indices.dedup().sorted().map(i => all-cells.at(i))
}

/// Cell selector: return an array of cells according to the cell specification
/// -> array
#let cells(
  ..args,
  nb: none,
  count: "index",
  name-path: auto,
  cell-type: "all",
  keep: "all",
  cell-header-pattern: auto,
  keep-cell-header: false,
) = {
  if args.named().len() > 0 {
    panic("invalid named arguments: " + repr(args.named()))
  }
  if args.pos().len() > 1 {
    panic("expected 1 positional argument, got " + str(args.pos().len()))
  }
  let spec = args.pos().at(0, default: none)
  let cs = _cells-from-spec(
    spec,
    nb,
    count,
    name-path,
    cell-type,
    cell-header-pattern,
    keep-cell-header,
  )
  return _apply-keep(cs, keep)
}

#let cell(..args, keep: "unique") = cells(..args, keep: keep).first()
