#import "/src/latex.typ"

#let src = ```
  \newcommand{\ab}{CD}
  \newcommand{\a}[2]{#1+\textrm{\hat{x\dot{y}}}+#2}
  \newcommand  {\a}  [2]  [x]  {#1+#2}
  \newcommand a{xyz} % name=a, value=xyz
  \newcommand axyz % name=a, value=x, yz is content
  \newcommand \ax yz % name=\ax, value=y, z is content
  \newcommand{\az}\ax % name=\az, value=\ax
  \newcommand+| % name=+, value=|
  \newcommand{\xvec}{\mathbf{x}}
  \newcommand{\vdot}[1]{\dot{\mathbf{#1}}}
  \newcommand{\dfdx}[2]{{\dfrac{\partial f_{#1}}{\partial x_{#2}}}}
  \newcommand{\mymatrix}[2]{\left( \begin{array}{#1} #2\end{array} \right)}
  \newcommand{\sqrttwo}{\frac{1}{\sqrt{2}}}
  \newcommand{\hadamard}{ \mymatrix{rr}{ \sqrttwo & \sqrttwo \\ \sqrttwo & -\sqrttwo }}
  \newcommand{\RR}{\mathbb{R}} \newcommand{\NN}{\mathbb{N}}
```.text

#let ref = (
  "\\newcommand{\\ab}{CD}",
  "\\newcommand{\\a}[2]{#1+\\textrm{\\hat{x\\dot{y}}}+#2}",
  "\\newcommand  {\\a}  [2]  [x]  {#1+#2}",
  "\\newcommand a{xyz}",
  "\\newcommand ax",
  "\\newcommand \\ax y",
  "\\newcommand{\\az}\\ax",
  "\\newcommand+|",
  "\\newcommand{\\xvec}{\\mathbf{x}}",
  "\\newcommand{\\vdot}[1]{\\dot{\\mathbf{#1}}}",
  "\\newcommand{\\dfdx}[2]{{\\dfrac{\\partial f_{#1}}{\\partial x_{#2}}}}",
  "\\newcommand{\\mymatrix}[2]{\\left( \\begin{array}{#1} #2\\end{array} \\right)}",
  "\\newcommand{\\sqrttwo}{\\frac{1}{\\sqrt{2}}}",
  "\\newcommand{\\hadamard}{ \\mymatrix{rr}{ \\sqrttwo & \\sqrttwo \\\\ \\sqrttwo & -\\sqrttwo }}",
  "\\newcommand{\\RR}{\\mathbb{R}}",
  "\\newcommand{\\NN}{\\mathbb{N}}",
)

#let defs = latex.definitions(src).map(x => x.text)
#assert.eq(defs, ref)

// #latex.definitions(src)
