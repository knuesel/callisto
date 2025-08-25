#let default-cell-header-pattern = regex("^# ?\|\s+(.*?):\s+(.*?)\s*$")

// Resolve 'cell-header-pattern' setting
#let _header-pattern(pat) = {
  if pat == auto { return default-cell-header-pattern }
  if pat != none and type(pat) != regex {
    panic("cell-header-pattern must be a regular expression or auto or none")
  }
  return pat
}

// Convert metadata in code header to cell metadata
#let _process-cell-header(cell, cfg: none) = {
  let header-pattern = _header-pattern(cfg.cell-header-pattern)
  if header-pattern == none { return cell }
  let source_lines = cell.source.split("\n")
  let n = 0
  for line in source_lines {
    let m = line.match(header-pattern)
    if m == none {
      break
    }
    n += 1
    let (key, value) = m.captures
    cell.metadata.insert(key, value)
  }
  // Remove header from source if necessary
  if not cfg.keep-cell-header and n > 0 {
    cell.source = source_lines.slice(n).join("\n")
  }
  return cell
}

// Normalize cell dict (ensuring the source is a single string rather than an
// array with one string per line) and convert source header metadata to cell
// metadata, using cell-header-pattern to recognize and parse cell header lines.
#let _process-cell(i, cell, cfg: none) = {
  if "id" not in cell {
    cell.id = str(i)
  }
  cell.index = i
    // Normalize source field to a single string
  if "source" in cell and type(cell.source) == array {
    cell.source = cell.source.join() // will be none if array is empty
  }
  if "source" not in cell or cell.source == none {
    cell.source = ""
  }
  if cell.cell_type == "code" {
    cell = _process-cell-header(cell, cfg: cfg)
  }
  return cell
}

#let read(nb, cfg: none) = {
  if nb == none { return none }
  if type(nb) not in (str, bytes, dictionary) {
    panic("invalid notebook type: " + str(type(nb)))
  }
  let nb-json = if type(nb) in (str, bytes) { json(nb) } else { nb }
  nb-json.cells = nb-json.cells.enumerate().map(
    ((i, c)) => _process-cell(i, c, cfg: cfg)
  )
  return nb-json
}

// Return the language name of the given notebook json
#let lang(nb-json) = {
  if nb-json == none { return none }
  return nb-json.metadata.language_info.name
}
