// Issue with nested backgrounds: see  https://github.com/typst/typst/issues/5766

// Default colors: Tango color scheme
#let default-palette = (
  rgb("#2e3436"), rgb("#cc0000"), rgb("#4e9a06"), rgb("#c4a000"),
  rgb("#3465a4"), rgb("#75507b"), rgb("#06989a"), rgb("#d3d7cf"),
  rgb("#555753"), rgb("#ef2929"), rgb("#8ae234"), rgb("#fce94f"),
  rgb("#729fcf"), rgb("#ad7fa8"), rgb("#34e2e2"), rgb("#eeeeec"),
)

// Takes an R/G/B code from 8-bit color spec and returns the corresponding
// value in 0-255.
#let _rgb-channel(v) = if v == 0 { 0 } else { 55 + v * 40 }

#let _color-8bit(palette, idx-str) = {
  let idx = int(idx-str)
  if idx < 16 {
    // Standard palette
    return palette.at(idx)
  } else if idx < 232 {
    // 6x6x6 RGB cube
    let n = idx - 16
    let r = int(n / 36)
    let g = int(calc.rem(n, 36) / 6)
    let b = calc.rem(n, 6)
    return rgb(_rgb-channel(r), _rgb-channel(g), _rgb-channel(b))
  } else {
    // Grayscale ramp
    let v = (idx - 232) * 10 + 8
    return luma(v)
  }
}

#let _chunk-style(codes-str, state: none, default: none, palette: none) = {
  let codes = codes-str.split(";")
  // Keep track of how many numerical values have been processed
  // (we sometimes process several together
  let idx = 0
  while idx < codes.len() {
    let code = codes.at(idx)

    // "0" or empty string (\x1b[m) = reset
    if code == "0" or code == "" {
      state = default
    }
    // TrueColor modes: 38 for foreground, 48 for background
    else if code == "38" or code == "48" {
      let is-bg = (code == "48")
      if idx + 2 < codes.len() and codes.at(idx+1) == "5" {
        // Code "5" is for 8-bit
        let color = _color-8bit(palette, codes.at(idx+2))
        if is-bg { state.bg = color } else { state.fg = color }
        idx += 3; continue
      } else if idx + 4 < codes.len() and codes.at(idx+1) == "2" {
        // Code "2" is for 24-bit
        let color = rgb(
          int(codes.at(idx+2)),
          int(codes.at(idx+3)),
          int(codes.at(idx+4)),
        )
        if is-bg { state.bg = color } else { state.fg = color }
        idx += 5; continue
      }
    } 
    // Styles
    else if code == "1" { state.bold = true }
    else if code == "2" { state.dimmed = true }
    else if code == "22" { state.bold = false; state.dimmed = false }
    else if code == "3" { state.italic = true }
    else if code == "23" { state.italic = false }
    else if code == "4" { state.under = true }
    else if code == "24" { state.under = false }
    else if code == "53" { state.over = true }
    else if code == "55" { state.over = false }
    else if code == "9" { state.strike = true }
    else if code == "29" { state.strike = false }
    else if code == "8" { state.conceal = true }
    else if code == "28" { state.conceal = false }
    else if code == "7" { state.reverse = true }
    else if code == "27" { state.reverse = false }
    // Default Resets
    else if code == "39" { state.fg = default.fg }
    else if code == "49" { state.bg = default.bg }
    else {
      // Basic Palette: we store the palette index to allow for easy
      // bold-is-bright implementation.
      // fg codes: 30 31 32 33 34 35 36 37, 90 91 92 93 94 95 96 97
      // bg codes: 40 41 42 43 44 45 46 47, 100 101 102 103 104 105 106 107
      let num = int(code)
      if num >= 30 and num <= 37 { state.fg = num - 30 }
      else if num >= 90 and num <= 97 { state.fg = num - 90 + 8 }
      else if num >= 40 and num <= 47 { state.bg = num - 40 }
      else if num >= 100 and num <= 107 { state.bg = num - 100 + 8 }
    }

    idx += 1
  }

  return state
}

// Return fg and bg colors taking the reverse state into account
#let _final-colors(state, bold: none, bold-is-bright: none, palette: none) = {
  let (fg, bg, reverse) = state
  if reverse {
    // bg can be none but that's not a valid fg. In that case we assume white
    // background, so white text when reversed.
    (fg, bg) = (
      if bg == none { white } else { bg },
      fg,
    )
  }
  // Handle colors given as palette index
  if type(fg) == int {
    if bold and bold-is-bright and fg < 8 {
      fg = fg + 8
    }
    fg = palette.at(fg)
  }
  if type(bg) == int {
    bg = palette.at(bg)
  }
  return (fg: fg, bg: bg)
}

// Convert a string with ANSI escape sequences into styled text.
// - palette: an array of 16 colors to use for the standard ANSI colors.
//   Default is auto for the Campbell palette.
// - fg: initial color for text (default: black). Cannot be none.
// - bg: initial background color (default: none). Can be none; in this
//   case, when colors are reversed, the text will be rendered in white.
// - bold-is-bright: if true, bold text in standard normal color (one of the
//   first 8 colors in the palette) will also be rendered "bright" by using
//   the corresponding bright color from the palette. Default false.
// - apply-fg, apply-bg, bold, italic, overline, underline, strike, dim,
//   conceal: functions to apply the corresponding style, each taking content
//   as first positional argument, as well as `fg` and `bg` keyword
//   arguments for the current colors.
//
//   The default function for "dim" makes the text 50% transparent.
// 
//   The default "conceal" is to use "hide" to prevent secrets from leaking
//   into compiled documents. To instead make the text "invisible" but still
//   present and selectable, use
//     conceal: (it, ..args) => text(it, fill: rgb(0, 0, 0, 0))
#let render(
  string,
  palette: auto,
  fg: black,
  bg: none,
  bold-is-bright: false,
  apply-fg:  (it, fg: none, ..args) => text(it, fill: fg),
  apply-bg:  (it, bg: none, ..args) => highlight(it, fill: bg),
  bold:      (it, ..args) => text(it, weight: "bold"),
  italic:    (it, ..args) => text(it, style: "italic"),
  overline:  (it, ..args) => overline(it),
  underline: (it, ..args) => underline(it),
  strike:    (it, ..args) => strike(it),
  dim:       (it, fg: none, ..args) => text(it, fill: fg.transparentize(50%)),
  conceal:   (it, ..args) => hide(it),
) = {
  if palette == auto {
    palette = default-palette
  }

  // Strip OSC sequences (such as terminal hyperlinks)
  string = string.replace(regex("\u{1b}\].*?(?:\u{07}|\u{1b}\\\\)"), "")

  // Split string on escape-bracket
  let chunks = string.split("\u{1b}[")
  
  // Default state
  let default-state = (
    fg: fg,
    bg: bg,
    bold: false,
    italic: false,
    under: false,
    over: false,
    strike: false,
    dimmed: false,
    conceal: false,
    reverse: false,
  )

  // Initial state
  let state = default-state
  
  // Array of styled chunks
  let result = ()
  
  // Regex for escape sequence. The first groups capture the numeric parameters
  // and the last one the command character (e.g. 'm' or 'J'). 
  let seq-regex = regex("^([0-9;]*)([a-zA-Z])")
  
  for (i, chunk) in chunks.enumerate() {
    // Chunk content without escape sequence
    let text-content = ""
    
    if i == 0 {
      // Chunk 0 comes before any escape sequence
      text-content = chunk
    } else {
      let m = chunk.match(seq-regex)
      if m != none {
        let codes-str = m.captures.at(0)
        let cmd = m.captures.at(1)
        
        // Everything after the command character is text
        text-content = chunk.slice(m.text.len()) 
        
        // Ignore all commands except 'm' which is for styling
        if cmd == "m" {
          state = _chunk-style(
            codes-str,
            state: state,
            default: default-state,
            palette: palette,
          )
        }
      } else {
        // Malformed sequence: print it as-is
        text-content = "\u{1b}[" + chunk
      }
    }
    
    if text-content == "" {
      continue
    }

    // Apply state
    let node = text-content

    // Apply reverse without changing state.fg, state.bg
    let final = _final-colors(
      state,
      bold: state.bold,
      bold-is-bright: bold-is-bright,
      palette: palette,
    )

    // Apply conceal at the innermost level, so the effect won't be
    // accidentally undone by other transformations (which could leak secrets)
    if state.conceal { node = conceal(node, ..final) }

    if state.under  { node = underline(node, ..final) }
    if state.over   { node = overline(node, ..final) }
    if state.strike { node = strike(node, ..final) }
    if state.italic { node = italic(node, ..final) }
    if state.dimmed { node = dim(node, ..final) }
    if state.bold   { node = bold(node, ..final) }

    if final.bg != none { node = apply-bg(node, ..final) }

    node = apply-fg(node, ..final)

    result.push(node)
  }
  
  // Join styled nodes
  result.join()
}
