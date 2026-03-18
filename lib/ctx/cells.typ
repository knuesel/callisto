#import "/lib/util.typ"

// Default places to look in cell dict for cell "name"
#let default-names = ("metadata.callisto.header.label", "id", "metadata.tags")

// Resolve 'name-path' setting to an array of name paths
#let resolve-name-path(path) = {
  if path == auto {
    return default-names
  }
  return util.ensure-array(path)
}

// For now a static value. In the future we might be smarter to automatically
// support languages with other syntax (OCaml, C++, ...)
#let default-header-pattern = "# | %key: %value"

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
// (a function that takes a key and a value and returns a header line).
#let _writer(pat) = {
  if type(pat) == dictionary {
    return pat.writer
  }
  // pat is a string
  return (key, value) => pat
    .replace("%key", key, count: 1)
    .replace("%value", value, count: 1)
}

#let resolve-header-pattern(pat) = {
  // Validate pattern
  let type-ok = type(pat) in (type(auto), str, dictionary)
  let keys-ok = type(pat) != dictionary or pat.keys().sorted() == (
    "regex",
    "writer",
  )
  if not (type-ok and keys-ok) {
    panic("cell-header-pattern must be a string, a dict with fields 'regex' " +
      "and 'writer', or auto")
  }

  if pat == auto {
    pat = default-header-pattern
  }

  return (
    regex: _regex(pat),
    writer: _writer(pat),
  )
}
