#import "/callisto.typ"

#let (render, output) = callisto.config(nb: json("ansi-table.ipynb"))

// #show raw.where(lang: "txt"): repr

// #render()

// ANSI escape sequence handler for Typst
// The ESC character (U+001B) must be inserted explicitly

#let ESC = "\u{1b}"

#let ansi-colors = (
  "30": black,
  "31": red,
  "32": green,
  "33": yellow,
  "34": blue,
  "35": purple,
  "36": eastern,
  "37": white,
  "90": gray,
  "91": rgb("#ff6666"),
  "92": rgb("#66ff66"),
  "93": rgb("#ffff66"),
  "94": rgb("#6666ff"),
  "95": rgb("#ff66ff"),
  "96": rgb("#66ffff"),
  "97": white,
)

#let ansi-bg-colors = (
  "40": black,
  "41": red,
  "42": green,
  "43": yellow,
  "44": blue,
  "45": purple,
  "46": eastern,
  "47": white,
)

#let render-ansi(source) = {
  // Build the regex pattern using the actual ESC character
  let esc-pattern = ESC + "\[" + "[0-9;]*m"
  // Match either an escape sequence or a run of non-ESC characters
  let pattern = regex("(" + esc-pattern + ")|([^" + ESC + "]+)")
  let parts = source.matches(pattern)

  let fg = none
  let bg = none
  let bold = false
  let italic = false
  let underline = false
  let strikethrough = false

  let result = ()

  for part in parts {
    let t = part.text
    if t.starts-with(ESC) {
      // Parse the escape code: strip ESC[ prefix and m suffix
      let inner = t.slice(2, -1)
      let codes = if inner == "" { ("0",) } else { inner.split(";") }
      for code in codes {
        code = code.trim()
        if code == "0" or code == "" {
          fg = none; bg = none; bold = false
          italic = false; underline = false; strikethrough = false
        } else if code == "1" { bold = true }
        else if code == "22" { bold = false }
        else if code == "3" { italic = true }
        else if code == "23" { italic = false }
        else if code == "4" { underline = true }
        else if code == "24" { underline = false }
        else if code == "9" { strikethrough = true }
        else if code == "29" { strikethrough = false }
        else if code in ansi-colors { fg = ansi-colors.at(code) }
        else if code == "39" { fg = none }
        else if code in ansi-bg-colors { bg = ansi-bg-colors.at(code) }
        else if code == "49" { bg = none }
      }
    } else {
      // Plain text — apply current state
      let content = t
      if fg != none { content = text(fill: fg, content) }
      if bold { content = strong(content) }
      if italic { content = emph(content) }
      if underline { content = std.underline(content) }
      if strikethrough { content = strike(content) }
      if bg != none {
        content = highlight(fill: bg, content)
      }
      result.push(content)
    }
  }

  result.join()
}

// --- Show rule version (strips ANSI from body content) ---
// Build regex with actual ESC character
// #show regex(ESC + "\[" + "[0-9;]*m"): none
// #show regex(ESC + "\[" + "[0-9;]*[A-HJKSTfn]"): none

// --- Demo ---

// Test strings built with the real ESC character
#let test1 = ESC + "[1;31mError:" + ESC + "[0m file not found"
#let test2 = ESC + "[32m✓ passed" + ESC + "[0m  " + ESC + "[1;33m⚠ warning" + ESC + "[0m  " + ESC + "[91m✗ failed" + ESC + "[0m"
#let test3 = ESC + "[1mBold" + ESC + "[0m " + ESC + "[3mItalic" + ESC + "[0m " + ESC + "[4mUnderline" + ESC + "[0m " + ESC + "[9mStrike" + ESC + "[0m"
#let test4 = ESC + "[34;1mBlue Bold" + ESC + "[0m then " + ESC + "[42;37m white on green " + ESC + "[0m"

#render-ansi(test1)
#linebreak()
#render-ansi(test2)
#linebreak()
#render-ansi(test3)
#linebreak()
#render-ansi(test4)

#show raw: it => {

}

#raw(output())

// Resets
// [39m resets foreground color
// [49m resets background color
// [39;49m resets both
// [0m resets all attributes (not only color)


// Issue with nested backgrounds: see  https://github.com/typst/typst/issues/5766
