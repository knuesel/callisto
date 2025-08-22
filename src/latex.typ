// Code to extract LaTeX definitions from a string
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
#let open = "\\{"
#let close = "\\}"
#let no-open-close = "\\\\\\{|\\\\\\}|[^{}]"
#let brace-arg-nest0 = open + "(?:" + no-open-close + ")*" + close
#let brace-arg-nest1 = open + "(?:" + brace-arg-nest0 + "|" + no-open-close + ")*" + close
#let brace-arg-nest2 = open + "(?:" + brace-arg-nest1 + "|" + no-open-close + ")*" + close
#let brace-arg-nest3 = open + "(?:" + brace-arg-nest2 + "|" + no-open-close + ")*" + close
#let brace-arg-nest4 = open + "(?:" + brace-arg-nest3 + "|" + no-open-close + ")*" + close
#let brace-arg-nest5 = open + "(?:" + brace-arg-nest4 + "|" + no-open-close + ")*" + close
#let brace-arg = brace-arg-nest5
#let name = "(?<name>\s*" + brace-arg-nest0 + "|\s*\\\\\w+\b|\s+[^\s{}]|[^\s\w])"
#let n-params = "\\[(?<nparams>[0-9])\\]"
#let default-value = "\\[(?<default>(?:" + brace-arg-nest4 + "|[^]])*)\\]"
#let value = "(?<value>\s*" + brace-arg + "|\s*\\\\\w+\b|\s*[^\s\[])"
#let newcmd = regex(
  "\\\\(?<kind>(?:re)?newcommand)" + name +
  "(?:\s*" + n-params + "(?:\s*" + default-value + ")?)?" + value
)

#let definitions(txt) = txt.matches(newcmd)
