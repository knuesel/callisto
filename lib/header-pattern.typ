
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



// For now a static value. In the future we might be smarter to automatically
// support languages with other syntax (OCaml, C++, ...)
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
