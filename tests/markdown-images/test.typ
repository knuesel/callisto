#import "@preview/cmarker:0.1.3"
#import "@preview/mitex:0.2.5": mitex

#import "/src/callisto.typ" as callisto: *

#callisto.render(
  nb: json("Cpp.ipynb"),
  handlers: (
    "text/markdown": (data, ..args) => cmarker.render(data,
        math: mitex-with-preamble.with(mitex-preamble: args.at("mitex-preamble", default: "")),
        scope: (image: (path, alt: none) => {
          if path.starts-with("attachment:") {
            markdown-cell-image(path, alt: alt, ..args)
          } else {
            image(path, alt: alt)
          }
          // Alternative:
          //let img = markdown-cell-image(path, alt: alt, ..args)
          //if type(img) == str { image(img, alt: alt) } else { img }
        }),
    ),
  ),
)
