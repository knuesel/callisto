// Issue with nested backgrounds: see  https://github.com/typst/typst/issues/5766

// Default colors: Campbell color scheme
#let default-palette = (
  rgb("0c0c0c"), rgb("c50f1f"), rgb("13a10e"), rgb("c19c00"),
  rgb("0037da"), rgb("881798"), rgb("3a96dd"), rgb("cccccc"),
  rgb("767676"), rgb("e74856"), rgb("16c60c"), rgb("f9f1a5"),
  rgb("3b78ff"), rgb("b4009e"), rgb("61d6d6"), rgb("ffffff")
)

// Takes an R/G/B code from 8-bit color spec and returns the corresponding
// value in 0-255.
#let rgb-channel(v) = if v == 0 { 0 } else { 55 + v * 40 }

#let color-8bit(palette, idx-str) = {
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
    return rgb(rgb-channel(r), rgb-channel(g), rgb-channel(b))
  } else {
    // Grayscale ramp
    let v = (idx - 232) * 10 + 8
    return luma(v)
  }
}

#let chunk-style(codes-str, state: none, default: none, palette: none) = {
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
        let color = color-8bit(palette, codes.at(idx+2))
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
#let final-colors(state, bold: none, bold-is-bright: none, palette: none) = {
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

// TODO: update docstring
// Parse a string to convert ANSI escape sequences to styled text using
// text.fill for fg, highlight.fill for bg, text.weight for bold, text.style
// for italic, underline and strike.
// The default-fg and default-bg can be set to change the initial/default
// colors.
#let render(
  string,
  palette: auto,
  default-fg: black,
  default-bg: none,
  bold-is-bright: false,
  fg:        (it, fg: none, ..args) => text(it, fill: fg),
  bg:        (it, bg: none, ..args) => highlight(it, fill: bg),
  bold:      (it, ..args) => text(it, weight: "bold"),
  italic:    (it, ..args) => text(it, style: "italic"),
  overline:  (it, ..args) => overline(it),
  underline: (it, ..args) => underline(it),
  strike:    (it, ..args) => strike(it),
  dim:       (it, fg: none, ..args) => text(it, fill: fg.transparentize(50%)),
  conceal:   (it, ..args) => hide(it),
  // Alternative implementation that doesn't really remove secrets
  // conceal:   (it, ..args) => text(it, fill: rgb(0, 0, 0, 0)),
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
    fg: default-fg,
    bg: default-bg,
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
          state = chunk-style(
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
    
    // Apply state
    if text-content != "" {
      let node = text-content

      // Apply reverse without changing state.fg, state.bg
      let final = final-colors(
        state,
        bold: state.bold,
        bold-is-bright: bold-is-bright,
        palette: palette,
      )

      // Apply conceal at the innermost level, so the effect won't be
      // accidentally undone by other transformations (which could leak secrets)
      if state.conceal { node = conceal(node, ..final) }

      if state.under { node = underline(node, ..final) }
      if state.over { node = overline(node, ..final) }
      if state.strike { node = strike(node, ..final) }
      if state.italic { node = italic(node, ..final) }
      if state.dimmed { node = dim(node, ..final) }
      if state.bold { node = bold(node, ..final) }
      if final.bg != none { node = highlight(node, fill: final.bg) }

      // Apply fg color
      node = text(node, fill: final.fg)

      result.push(node)
    }
  }
  
  // Join styled nodes
  result.join()
}
