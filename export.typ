#let nb-metadata = (
 metadata: (
  kernelspec: (
   display_name: "Julia 1.10.2",
   language: "julia",
   name: "julia-1.10"
  ),
  language_info: (
   file_extension: ".jl",
   mimetype: "application/julia",
   name: "julia",
   version: "1.10.2"
  )
 ),
 nbformat: 4,
 nbformat_minor: 5
)

#let make-code-cell((i, raw-el)) = {
  (
    cell_type: "code",
    id: "nbio" + str(i),
    metadata: (:),
    source: raw-el.text,
  )
}

#let make-nb(codes) = {
  (cells: codes.enumerate().map(make-code-cell), ..nb-metadata)
}

#let write() = context [#metadata(make-nb(query(<exec>))) <md>]
