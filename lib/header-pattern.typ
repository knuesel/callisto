// For now a static value. In the future we might be smarter to automatically
// support languages with other syntax (OCaml, C++, ...)
#let _default-pattern = "# | %key: %value"

// A regex that matches every character that is special in a regex
#let _metachar-regex = regex(`[.*+?|(){}^$\[\]\\]`.text)
// A function that replaces a special regex character by its escaped version
#let _escape-metachar(match) = "\\" + match.text

// Parse a header pattern string and return a regex for finding a cell header
// line and extracting key and value.
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

// Get header regex from cell-header-pattern setting (a regex that matches a
// header line).
#let _regex(pat) = {
  if type(pat) == dictionary {
    return pat.regex
  }
  // pat is a string
  return _header-regex-from-string(pat) 
}

// Get a header writer function from cell-header-pattern setting
// (a function that takes a key and a value and returns a header line without
// trailing newline).
#let _writer(pat) = {
  if type(pat) == dictionary {
    return pat.writer
  }
  // pat is a string
  return (key, value) => pat
    .replace("%key", key, count: 1)
    .replace("%value", value, count: 1)
}

#let resolve(pat) = {
  // Validate pattern
  let type-ok = type(pat) in (type(auto), str, dictionary)
  let keys-ok = type(pat) != dictionary or pat.keys().sorted() == (
    "regex",
    "writer",
  )
  if not (type-ok and keys-ok) {
    panic("cell header pattern must be a string, a dict with fields 'regex' " +
      "and 'writer', or auto")
  }

  if pat == auto {
    pat = _default-pattern
  }

  return (
    regex: _regex(pat),
    writer: _writer(pat),
  )
}

// Build a cell header string for the given dict, based on the given pattern
#let make-header-text(header-dict, pattern: none) = {
  if header-dict == none {
    return none
  }
  if type(header-dict) != dictionary {
    panic("cell header must be a dict or none")
  }
  // Build header
  let header = none
  let header-writer = resolve(pattern).writer
  for (k, v) in header-dict {
    if type(v) != str {
      panic("cell header has key " + k + " of type " + type(v) +
        " but only strings are supported")
    }
    header += header-writer(k, v) + "\n"
  }
  return header
}

// Parse the given cell source text to find the header and convert it to a
// dictionary. The returned value is a dict with `text` field holding the full
// header as a string, and `dict` holding the dictionary.
#let parse-header-text(cell-source, pattern: none) = {
  let header = (text: none, dict: (:))
  let header-regex = resolve(pattern).regex
  if header-regex == none {
    return header
  }
  for line in cell-source.split("\n") {
    let m = line.match(header-regex)
    if m == none {
      break
    }
    header.text += line + "\n"

    let (key, value) = m.captures
    header.dict.insert(key, value)
  }
  return header
}
