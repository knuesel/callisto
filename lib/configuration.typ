// All settings for the main functions, with default values
#let settings = (
  // Notebook
  nb: none,
  cell-header-pattern: auto,
  keep-cell-header: false,
  // Cell selection
  count: "index",
  name-path: auto,
  cell-type: "all",
  keep: "all",
  // Source
  lang: auto,
  raw-lang: none,
  // Outputs
  output-type: "all",
  format: auto,
  ignore-wrong-format: false,
  stream: "all",
  result: "value",
  handlers: auto,
  // Rendering
  input: auto,
  output: auto,
  h1-level: 1,
  gather-latex-defs: true,
  ansi: (:),
  apply-theme: false, // default for all but render functions
  theme: "notebook",
  // Export
  export-name: "notebook",
  cell-header: none,
  kernel: none,
  transform: none,
  // Undocumented for now
  read: auto,
  export: auto,
  default-handlers: (:), // to be filled in callisto.typ
  named-themes: (:), // to be filled in callisto.typ
)

// Parse the arguments of the main functions
#let parse-main-args(..args) = {
  if args.pos().len() > 1 {
    panic("expected 0 or 1 positional argument for the cell specification, " +
      "got " + repr(args.pos()))
  }
  if args.pos().len() == 1 and args.at(0) == none {
    panic("invalid cell specification: 'none'")
  }
  let cell-spec = args.at(0, default: none)
  let user-cfg = args.named()
  for k in user-cfg.keys() {
    if k not in settings {
      panic("unexpected keyword argument '" + k + "'")
    }
  }
  return (
    cell-spec: cell-spec,
    cfg: settings + user-cfg,
  )
}

// Return true if export was enabled on the command-line
// (--input callisto-export=true), false otherwise.
#let _cli-export() = {
  let export = sys.inputs.at("callisto-export", default: "false")
  if export == "true" {
    return true
  }
  if export == "false" {
    return false
  }
  panic("unsupported value for callisto-export input: " + export)
}

// Return false if notebook functions should be disabled in this configuration,
// that is if the user set read=false or if read=auto and export was
// enabled on the command-line (--input callisto-export=true).
#let read-enabled(cfg: none) = {
  if cfg.read != auto {
    return cfg.read
  }
  return _cli-export() == false
}

// Return true if export is enabled in this configuration,
// that is if the user set export=true or if export=auto and export was
// enabled on the command-line (--input callisto-export=true).
#let export-enabled(cfg: none) = {
  if cfg.export != auto {
    return cfg.export
  }
  return _cli-export()
}
