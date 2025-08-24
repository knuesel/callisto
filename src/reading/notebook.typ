#let default-cell-header-pattern = regex("^# ?\|\s+(.*?):\s+(.*?)\s*$")

// Convert metadata in code header to cell metadata
#let _process-cell-header(cell, cell-header-pattern, keep-cell-header) = {
  if cell-header-pattern == none {
    return cell
  }
  if cell-header-pattern == auto {
    cell-header-pattern = default-cell-header-pattern
  }
  if type(cell-header-pattern) != regex {
    panic("cell-header-pattern must be a regular expression or auto or none")
  }
  let source_lines = cell.source.split("\n")
  let n = 0
  for line in source_lines {
    let m = line.match(cell-header-pattern)
    if m == none {
      break
    }
    n += 1
    let (key, value) = m.captures
    cell.metadata.insert(key, value)
  }
  // Remove header from source if necessary
  if not keep-cell-header and n > 0 {
    cell.source = source_lines.slice(n).join("\n")
  }
  return cell
}

// Normalize cell dict (ensuring the source is a single string rather than an
// array with one string per line) and convert source header metadata to cell
// metadata, using cell-header-pattern to recognize and parse cell header lines.
#let _process-cell(i, cell, cell-header-pattern, keep-cell-header) = {
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
    cell = _process-cell-header(cell, cell-header-pattern, keep-cell-header)
  }
  return cell
}

#let read(nb, cell-header-pattern, keep-cell-header) = {
  if type(nb) not in (str, bytes, dictionary) {
    panic("invalid notebook type: " + str(type(nb)))
  }
  let nb-json = if type(nb) in (str, bytes) { json(nb) } else { nb }
  nb-json.cells = nb-json.cells.enumerate().map(
    ((i, c)) => _process-cell(i, c, cell-header-pattern, keep-cell-header)
  )
  return nb-json
}

// Return the language name of the given notebook json
#let lang(nb-json) = nb-json.metadata.language_info.name


