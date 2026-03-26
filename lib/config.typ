// All settings for the main functions, with default values
#let settings = (
  // Notebook
  nb: none,
  cell-header-pattern: auto,
  keep-cell-header: false,
  lang: auto,
  raw-lang: none,
  gather-latex-defs: true,
  // Cell selection
  count: "index",
  name-path: auto,
  cell-type: "all",
  keep: "all",
  // Other
  h1-level: 1,
  // Outputs
  result: "value",
  stream: "all",
  format: auto,
  handlers: auto,
  ignore-wrong-format: false,
  item: "unique",
  output-type: "all",
  // Rendering
  input: auto,
  output: auto,
  default-handlers: (:), // to be filled in callisto.typ
  named-themes: (:), // to be filled in callisto.typ
  theme: "notebook",
  apply-theme: false, // default for all but render functions
  // Export
  read: auto,
  export-name: "notebook",
  cell-header: none,
  kernel: none,
  export: true,
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

// Return false if notebook functions should be disabled in this configuration,
// that is if the user set read=false or if read=auto and export was
// enabled on the command-line (--input callisto-export=true).
#let read-enabled(cfg: none) = {
  if cfg.read != auto {
    return cfg.read
  }
  let cli-export = sys.inputs.at("callisto-export", default: "false")
  if cli-export == "false" {
    return true
  }
  if cli-export == "true" {
    return false
  }
  panic("unsupported value for callisto-export input: " + cli-export)
}
