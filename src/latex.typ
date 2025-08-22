// Code to extract MathJax LaTeX definitions from a string.
// We try to match the MathJax parsing behavior rather than true
// LaTeX behavior.
// A \newcommand name can be given as
// - \newcommand x{value} (space required and only single character name)
// - \newcommand {xxx}{value}   (space optional)
// - \newcommand \xxx{value}    (space optional)
// - \newcommand {\xxx}{value}  (space optional)
// The value can be also be given without braces and then if without
// backslash must be a single char.
// When the name/value is a single character, it need not be a word character
// but a name cannot be given as '{' or '}' and a value cannot be given
// as '['.
#let _open = "\\{"
#let _close = "\\}"
#let _no-open-close = "\\\\\\{|\\\\\\}|[^{}]"
#let _brace-arg-nest0 = _open + "(?:" + _no-open-close + ")*" + _close
#let _brace-arg-nest1 = _open + "(?:" + _brace-arg-nest0 + "|" + _no-open-close + ")*" + _close
#let _brace-arg-nest2 = _open + "(?:" + _brace-arg-nest1 + "|" + _no-open-close + ")*" + _close
#let _brace-arg-nest3 = _open + "(?:" + _brace-arg-nest2 + "|" + _no-open-close + ")*" + _close
#let _brace-arg-nest4 = _open + "(?:" + _brace-arg-nest3 + "|" + _no-open-close + ")*" + _close
#let _brace-arg-nest5 = _open + "(?:" + _brace-arg-nest4 + "|" + _no-open-close + ")*" + _close
#let _brace-arg = _brace-arg-nest5
#let _name = "(?<name>\s*" + _brace-arg-nest0 + "|\s*\\\\\w+\b|\s+[^\s{}]|[^\s\w])"
#let _n-params = "\\[(?<nparams>[0-9])\\]"
#let _default-value = "\\[(?<default>(?:" + _brace-arg-nest4 + "|[^]])*)\\]"
#let _expression = "(?<expression>\s*" + _brace-arg + "|\s*\\\\\w+\b|\s*[^\s\[])"
#let command-definition = regex(
  "\\\\newcommand" + _name +
  "(?:\s*" + _n-params + "(?:\s*" + _default-value + ")?)?" + _expression
)

// Convert a command name text to the `\name` form (always starting
// with a backslash, no surrounding spaces and braces).
#let _normalize-command(txt) = {
  let name = txt.trim()
  if name.first() == "{" and name.last() == "}" {
    name = name.slice(1, -1).trim()
  }
  if name.first() != "\\" {
    name = "\\" + name
  }
  return name
}

// Normalize a command expression, removing surrounding spaces and braces.
#let _normalize-expr(txt) = {
  let expr = txt.trim()
  if txt.first() == "{" and txt.last() == "}" {
    // Contrary to _normalize-command we don't trim the result here:
    // surrounding spaces in the expression itself must be preserved.
    txt = txt.slice(1, -1)
  }
  return txt
}

// Convert a command definition regex match to a dictionary with named
// fields for the captures and with normalized command name and
// expression.
#let _normalize-match(m) = (
  start: m.start,
  end: m.end,
  text: m.text,
  command: _normalize-command(m.captures.at(0)),
  n-params: m.captures.at(1),
  default-arg: m.captures.at(2),
  expression: _normalize-expr(m.captures.at(3)),
)

// Return a LaTeX definition string of the form
//   \newcommand{\name}[...][...]{value}
// with the [...] parts are included only if necessary. For example
//   \newcommand + |
// is normalized to
//   \newcommand{\+}{|}
#let normalized-def-string(def) = {
  let normalized = "\\newcommand{" + def.command + "}"
  if def.n-params != none {
    normalized += "[" + def.n-params + "]"
  }
  if def.default-arg != none {
    normalized += "[" + def.default-arg + "]"
  }
  normalized += "{" + def.expression + "}"
  return normalized
}

// Return an array of LaTeX command definitions found in the given LaTeX
// string. Each definition is returned as a dict with the following fields
// identifying the matched text and its location in the string:
// - text: the command definition (substring of 'txt')
// - start: the start offset of 'text' in 'txt'
// - end: the end offset of 'text' in 'txt'
// and the following extra fields:
// - command: the normalized command name, of th form '\name'
// - n-params: the number of parameters ('none' if there is no parameter)
// - default-arg: default value for first parameter ('none' if unspecified)
// - expression: the normalized expression
#let definitions(txt) = {
  txt.matches(command-definition)
    .map(_normalize-match)
}
