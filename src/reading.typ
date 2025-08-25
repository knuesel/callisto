#import "reading/notebook.typ"
#import "reading/rich-object.typ"
#import "reading/cell.typ": cells, cell
#import "reading/source.typ": sources, source
#import "reading/output.typ": outputs, output
#import "reading/stream.typ": streams, stream

#let displays     = outputs.with(output-type: "display_data")
#let results      = outputs.with(output-type: "execute_result")
#let errors       = outputs.with(output-type: "error")
#let stream-items = outputs.with(output-type: "stream")

#let display     = output.with(output-type: "display_data")
#let result      = output.with(output-type: "execute_result")
#let error       = output.with(output-type: "error")
#let stream-item = output.with(output-type: "stream")
