#import "@preview/autograph:0.1.0": diagram, node, edge
#set page(width: auto, height: auto)
#diagram(
  // bezier: true,
  node(<cell>),
  node(<markdown-cell>),
  node(<code-cell>),
  node(<raw-cell>),
  edge(<cell>, <markdown-cell>),
  edge(<cell>, <code-cell>),
  edge(<cell>, <raw-cell>),
  node(<code-cell-input>),
  node(<code-cell-output>),
  edge(<code-cell>, <code-cell-input>),
  edge(<code-cell>, <code-cell-output>),
  node(<source-code-generic>),
  edge(<code-cell-input>, <source-code-generic>),
  edge(<raw-cell>, <source-code-generic>),
  node(<output>),
  edge(<code-cell-output>, <output>),
  node(<display>),
  node(<result>),

  node(<rich-output-generic>),
  edge(<display>, <rich-output-generic>),
  edge(<result>, <rich-output-generic>),

  node(<stream>),

  node(<text-console-block>),

  node(<error>),
  edge(<error>, <text-console-block>, stroke: (dash: "dashed")),

  edge(<output>, <display>),
  edge(<output>, <result>),
  edge(<output>, <stream>),
  edge(<output>, <error>),
  edge(<stream>, <stream-stdout>),
  edge(<stream>, <stream-stderr>),
  edge(<stream>, <stream-merged>),
  node(<stream-generic>),
  edge(<stream-generic>, <text-console-block>, stroke: (dash: "dashed")),

  node(<stream-stdout>),
  edge(<stream-stdout>, <stream-generic>),

  node(<stream-stderr>),
  edge(<stream-stderr>, <stream-generic>),

  node(<stream-merged>),
  edge(<stream-merged>, <stream-generic>),

  node(<text-ansi-generic>),
  edge(<text-console-block>, <text-ansi-generic>),


  node(<markdown-generic>),
  edge(<markdown-cell>, <markdown-generic>),

  node(<math-markdown>),
  edge(<markdown-generic>, <math-markdown>),
  node(<image-markdown>),
  edge(<markdown-generic>, <image-markdown>),

  node(<math-generic>),
  edge(<math-markdown>, <math-generic>),

  node(<attachment>),
  edge(<image-markdown>, <attachment>),
  edge(<attachment>, label("image/svg+xml")),
  edge(<attachment>, label("image/png")),
  edge(<attachment>, label("image/jpeg")),
  edge(<attachment>, label("image/gif")),

  node(<image-generic>),
  edge(<image-markdown>, <image-generic>),

  node(<path>),
  edge(<image-generic>, <path>),

  node(<image-base64>),
  edge(<image-base64>, <image-generic>),

  node(<image-text>),
  edge(<image-text>, <image-generic>),

  node(label("image/svg+xml")),
  edge(label("image/svg+xml"), <image-base64>), 
  edge(label("image/svg+xml"), <image-text>), 

  node(label("text/markdown")),
  edge(label("text/markdown"), <markdown-generic>),

  node(label("text/latex")),

  node(label("text/plain")),
  edge(label("text/plain"), <text-console-block>, stroke: (dash: "dashed")),

  node(label("image/png")),
  node(label("image/jpeg")),
  node(label("image/gif")),
  edge(label("image/png"), <image-base64>),
  edge(label("image/jpeg"), <image-base64>),
  edge(label("image/gif"), <image-base64>),

  edge(<rich-output-generic>, label("image/svg+xml")),
  edge(<rich-output-generic>, label("image/png")),
  edge(<rich-output-generic>, label("image/jpeg")),
  edge(<rich-output-generic>, label("image/gif")),
  edge(<rich-output-generic>, label("text/markdown")),
  edge(<rich-output-generic>, label("text/latex")),
  edge(<rich-output-generic>, label("text/plain")),

)
