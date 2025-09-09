#import "reading/notebook.typ"
#import "reading/rich-object.typ"
#import "reading/cell.typ": cells, cell
#import "reading/source.typ": sources, source
#import "reading/output.typ": outputs, output
#import "reading/stream.typ": streams, stream

#let displays(..args)     = outputs(..args, output-type: "display_data")
#let results(..args)      = outputs(..args, output-type: "execute_result")
#let errors(..args)       = outputs(..args, output-type: "error")
#let stream-items(..args) = outputs(..args, output-type: "stream")

#let display(..args)     = output(..args, output-type: "display_data")
#let result(..args)      = output(..args, output-type: "execute_result")
#let error(..args)       = output(..args, output-type: "error")
#let stream-item(..args) = output(..args, output-type: "stream")
