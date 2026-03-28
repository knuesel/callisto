// Issue with nested backgrounds: see  https://github.com/typst/typst/issues/5766

// Default colors: Campbell color scheme
#let default-palette = (
  rgb("0c0c0c"), rgb("c50f1f"), rgb("13a10e"), rgb("c19c00"),
  rgb("0037da"), rgb("881798"), rgb("3a96dd"), rgb("cccccc"),
  rgb("767676"), rgb("e74856"), rgb("16c60c"), rgb("f9f1a5"),
  rgb("3b78ff"), rgb("b4009e"), rgb("61d6d6"), rgb("ffffff")
)

// Codes for foreground and background colors
// (corresponding to palette color at same index)
#let fg-codes = (30, 31, 32, 33, 34, 35, 36, 37, 90, 91, 92, 93, 94, 95, 96, 97)
#let bg-codes = (40, 41, 42, 43, 44, 45, 46, 47, 100, 101, 102, 103, 104, 105, 106, 107)

// Build a dict of code to color
#let color-dict(codes, palette) = codes.map(str).zip(palette).to-dict()

// Use a tiling to represent a missing (unknown) color
#let missing-color-tiling = tiling(size: (3pt, 3pt))[
  #place(line(start: (0%, 0%), end: (100%, 100%)))
  #place(line(start: (0%, 100%), end: (100%, 0%)))
]

// Takes an R/G/B code from 8-bit color spec and returns the corresponding
// value in 0-255.
#let rgb-channel(v) = if v == 0 { 0 } else { 55 + v * 40 }

#let get-8bit-color(palette, idx-str) = {
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

// Parse a string to convert ANSI escape sequences to styled text using
// text.fill for fg, highlight.fill for bg, text.weight for bold, text.style
// for italic, underline and strike.
// The default-fg and default-bg can be set to change the initial/default
// colors.
#let render(string, palette: auto, default-fg: black, default-bg: none) = {
  if palette == auto {
    palette = default-palette
  }

  // Mapping of color codes to colors
  let fg-colors = color-dict(fg-codes, palette)
  let bg-colors = color-dict(bg-codes, palette)

  // Strip OSC sequences (such as terminal hyperlinks)
  string = string.replace(regex("\u{1b}\].*?(?:\u{07}|\u{1b}\\\\)"), "")

  // Split string on escape-bracket
  let chunks = string.split("\u{1b}[")
  
  // Initial state
  let fg = default-fg
  let bg = default-bg
  let weight = "regular"
  let style = "normal"
  let under = false
  let over = false
  let strike = false
  let dimmed = false
  let conceal = false
  let reverse = false
  
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
          let codes = codes-str.split(";")
          // Keep track of how many numerical values have been processed
          // (we sometimes process several together
          let idx = 0
          while idx < codes.len() {
            let code = codes.at(idx)
            
            // "0" or empty string (\x1b[m) = reset
            if code == "0" or code == "" {
              fg = default-fg
              bg = default-bg
              weight = "regular"
              style = "normal"
              under = false
              over = false
              strike = false
              dimmed = false
              conceal = false
              reverse = false
            } 
            // TrueColor modes: 38 for foreground, 48 for background
            else if code == "38" or code == "48" {
              let is-bg = (code == "48")
              if idx + 2 < codes.len() and codes.at(idx+1) == "5" {
                // Code "5" is for 8-bit
                let color = get-8bit-color(palette, codes.at(idx+2))
                if is-bg { bg = color } else { fg = color }
                idx += 3; continue
              } else if idx + 4 < codes.len() and codes.at(idx+1) == "2" {
                // Code "2" is for 24-bit
                let color = rgb(
                  int(codes.at(idx+2)),
                  int(codes.at(idx+3)),
                  int(codes.at(idx+4)),
                )
                if is-bg { bg = color } else { fg = color }
                idx += 5; continue
              }
            } 
            // Styles
            else if code == "1" { weight = "bold" }
            else if code == "2" { dimmed = true }
            else if code == "22" { weight = "regular"; dimmed = false }
            else if code == "3" { style = "italic" }
            else if code == "23" { style = "normal" }
            else if code == "4" { under = true }
            else if code == "24" { under = false }
            else if code == "53" { over = true }
            else if code == "55" { over = false }
            else if code == "9" { strike = true }
            else if code == "29" { strike = false }
            else if code == "8" { conceal = true }
            else if code == "28" { conceal = false }
            else if code == "7" { reverse = true }
            else if code == "27" { reverse = false }
            // Default Resets
            else if code == "39" { fg = default-fg }
            else if code == "49" { bg = default-bg }
            // Basic Palette
            else if code in fg-colors { fg = fg-colors.at(code) }
            else if code in bg-colors { bg = bg-colors.at(code) }
            
            idx += 1
          }
        }
      } else {
        // Malformed sequence, print it as-is
        text-content = "\u{1b}[" + chunk
      }
    }
    
    // Apply state
    if text-content != "" {
      let node = text-content

      if under { node = underline(node) }
      if over { node = overline(node) }
      if strike { node = strike(node) }

      // Apply reverse but without changing "current" fg, bg
      let final-fg = if reverse { bg } else { fg }
      let final-bg = if reverse { fg } else { bg }

      if dimmed and final-fg != none {
        final-fg = final-fg.transparentize(50%)
      }

      if conceal {
        // Transparent text
        final-fg = rgb(0, 0, 0, 0)
      }
      
      // The bg color can be none (from default-bg=none) but that's not a valid
      // text fill.
      if final-fg == none {
        final-fg = missing-color-tiling
      }

      // Apply text style
      node = text(
        fill: final-fg,
        weight: weight,
        style: style,
        node,
      )

      // Apply bg color
      if final-bg != none {
        node = highlight(fill: final-bg, node)
      }

      result.push(node)
    }
  }
  
  // Join styled nodes
  result.join()
}


