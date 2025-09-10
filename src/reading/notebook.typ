// A regex that matches every character that is special in a regex
#let _metachar-regex = regex(`[.*+?|(){}^$\[\]\\]`.text)
// A function that replaces a special regex character by its escaped version
#let _escape-metachar(match) = "\\" + match.text

// Parse a header pattern string and return a regex for finding cell header
// lines and extracting key and value.
#let _header-regex-from-string(pat) = {
  // Escape every special character from the pattern string
  let escaped = pat.replace(_metachar-regex, _escape-metachar)

  // Translate the pattern to a regular expression with capture groups
  let translated = escaped
      .replace(regex("\\s+"), "\\s*") // space means any number of spaces
      .replace("%key", "(.*?)", count: 1) // key capture group
      .replace("%value", "(.*?)", count: 1) // value capture group

  // Require the header to start the line, but allow trailing spaces
  return regex("^" + translated + "\\s*$")
}

#let default-cell-header-pattern = "# | %key: %value"

#let _validate-header-pattern(pat) = {
  let type-ok = type(pat) in (type(auto), type(none), str, dictionary)
  let keys-ok = type(pat) != dictionary or pat.keys().all(
    x => x in ("regex", "writer")
  )
  if not (type-ok and keys-ok) {
    panic("cell-header-pattern must be a string, a dict with fields 'regex' " +
      "and/or 'writer', or auto or none")
  }
}

// Get header regex from cell-header-pattern setting
#let cell-header-regex(pat) = {
  _validate-header-pattern(pat)
  if pat == auto {
    pat = default-cell-header-pattern
  }
  if pat == none { return none }
  if type(pat) == dictionary {
    if "regex" not in pat { panic("regex missing from cell-header-pattern") }
    return pat.regex
  }
  // pat is a string
  return _header-regex-from-string(pat) 
}

// Get a header writer function from cell-header-pattern setting
// (a function that takes a key and a value and returns a header line).
#let cell-header-writer(pat) = {
  _validate-header-pattern(pat)
  if pat == auto {
    pat = default-cell-header-pattern
  }
  if pat == none { return none }
  if type(pat) == dictionary {
    if "writer" not in pat { panic("writer missing from cell-header-pattern") }
    return pat.writer
  }
  // pat is a string
  return (key, value) => pat
    .replace("%key", key, count: 1)
    .replace("%value", value, count: 1)
}

// Convert metadata in code header to cell metadata
#let _process-cell-header(cell, cfg: none) = {
  let header-regex = cell-header-regex(cfg.cell-header-pattern)
  if header-regex == none { return cell }
  let source_lines = cell.source.split("\n")
  let n = 0
  for line in source_lines {
    let m = line.match(header-regex)
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
