local base = require("packages.base")

local package = pl.class(base)
package._name = "math"

function package:_init ()

  base._init(self)

  self.class:loadPackage("math.typesetter")
  self.class:loadPackage("math.texlike")

end

function package.declareSettings (_)

  SILE.settings:declare({
      parameter = "math.font.family",
      type = "string",
      default = "Libertinus Math"
    })
  SILE.settings:declare({
      parameter = "math.font.filename",
      type = "string",
      default = ""
    })
  SILE.settings:declare({
      parameter = "math.font.size",
      type = "integer",
      default = 10
    })
  -- Whether to show debug boxes around mboxes
  SILE.settings:declare({
      parameter = "math.debug.boxes",
      type = "boolean",
      default = false
    })
  SILE.settings:declare({
      parameter = "math.displayskip",
      type = "VGlue",
      default = SILE.nodefactory.vglue("2ex plus 1pt")
    })

end

function package:registerCommands ()

  local class = self.class

  class:registerCommand("mathml", function (options, content)
    local mode = (options and options.mode) and options.mode or 'text'
    local mbox
    xpcall(function()
      mbox = class:ConvertMathML(content, mbox)
    end, function(err) print(err); print(debug.traceback()) end)
    class:handleMath(mbox, mode)
  end)

  class:registerCommand("math", function (options, content)
    local mode = (options and options.mode) and options.mode or "text"
    local mbox
    xpcall(function()
      mbox = class:ConvertMathML(class:compileToMathML({}, class:convertTexlike(content)))
    end, function(err) print(err); print(debug.traceback()) end)
    class:handleMath(mbox, mode)
  end)

end

package.documentation = [[
\begin{document}
\use[module=packages.math]

\set[parameter=math.font.family, value=Libertinus Math]
\set[parameter=math.font.size, value=11]

% Default verbatim font (Hack) is missing a few math symbols
\use[module=packages.font-fallback]
\font:add-fallback[family=Symbola]

This package provides typesetting of formulas directly in a SILE document.

\note{Mathematical typesetting in SILE is still in its infancy.
As such, it lacks some features and may contain bugs.
Feedback and contributions are always welcome.}

\noindent To typeset mathematics, you will need an OpenType math font installed on your system\footnote{A list of freely available math fonts can be found at \href[src=https://www.ctan.org/pkg/unicode-math]{https://www.ctan.org/pkg/unicode-math}}.
By default, this package uses Libertinus Math, so it will fail if Libertinus Math can’t be found.
Another font may be specified via the setting \autodoc:setting{math.font.family}.

The first way to typeset math formulas is to enter them in the MathML format.
MathML is a standard for encoding mathematical notation for the Web and for other types of digital documents.
It is supported by a wide range of tools and represents the most promising format for unifying the encoding of mathematical notation, as well as improving its accessibility (e.g. to blind users).

To render an equation encoded in MathML, one simply has to put it in a \code{mathml} command.
For example, the formula \mathml{\mrow{\msup{\mi{a}\mn{2}} \mo{+} \msup{\mi{b}\mn{2}} \mo{=} \msup{\mi{c}\mn{2}}}} was typeset by the following command:

\begin{verbatim}
\line
\\mathml\{
    \\mrow\{
        \\msup\{\\mi\{a\}\\mn\{2\}\}
        \\mo\{+\}
        \\msup\{\\mi\{b\}\\mn\{2\}\}
        \\mo\{=\}
        \\msup\{\\mi\{c\}\\mn\{2\}\}
    \}
\}
\line
\end{verbatim}

\noindent In an XML document, we would have used the more classical XML syntax:

\begin{verbatim}
\line
<mathml>
    <mrow>
        <msup> <mi>a</mi> <mn>2</mn> </msup>
        <mo>+</mo>
        <msup> <mi>b</mi> <mn>2</mn> </msup>
        <mo>=</mo>
        <msup> <mi>c</mi> <mn>2</mn> </msup>
    </mrow>
</mathml>
\line
\end{verbatim}

\noindent By default, formulas are integrated into the flow of text.
To typeset them on their own line, one may use the \autodoc:parameter{mode=display} option:

\mathml[mode=display]{
    \mrow{
        \msup{\mi{a}\mn{2}}
        \mo{+}
        \msup{\mi{b}\mn{2}}
        \mo{=}
        \msup{\mi{c}\mn{2}}
    }
}

As this example code illustrates, MathML is not really intended to be written by humans and quickly becomes very verbose.
That is why this package also provides a \code{math} command, which understands a syntax similar to the math syntax of TeX.
To typeset the above equation, one only has to type \code{\\math\{a^2 + b^2 = c^2\}}.

Here is a slightly more involved equation:

\begin{verbatim}
\line
\\begin[mode=display]\{math\}
    \\sum_\{n=1\}^\\infty \\frac\{1\}\{n^2\} = \\frac\{\\pi^2\}\{6\}
\\end\{math\}
\line
\end{verbatim}

\noindent This renders as:

\begin[mode=display]{math}
    \sum_{n=1}^\infty \frac{1}{n^2} = \frac{\pi^2}{6}
\end{math}

The general philosophy of the TeX-like syntax is to be a simple layer on top of MathML, and not to mimic perfectly the syntax of the LaTeX tool.
Its main difference from the SILE syntax is that \code{\\mycommand\{arg1\}\{arg2\}\{arg3\}} is translated into MathML as \code{<mycommand> arg1 arg2 arg3 </mycommand>} whereas in normal SILE syntax, the XML equivalent would be \code{<mycommand>arg1</mycommand> arg2 arg3}.

\code{\\sum}, \code{\\infty} and \code{\\pi} are only shorthands for the Unicode characters \math{\sum}, \math{\infty} and \math{\pi}.
If it’s more convenient, you can use these Unicode characters directly.
The symbol shorthands are the same as in the TeX package \href[src=https://www.ctan.org/pkg/unicode-math]{\code{unicode-math}}.

\code{\{formula\}} is a shorthand for \code{\\mrow\{formula\}}.
Since parentheses — among other glyphs — stretch vertically to the size of their englobing \code{mrow}, this is useful to typeset parentheses of different sizes on the same line:

\begin{verbatim}
\line
\\Gamma (\\frac\{\\zeta\}\{2\}) + x^2(x+1)
\line
\end{verbatim}

\noindent renders as

\begin[mode=display]{math}
    \Gamma (\frac{\zeta}{2}) + x^2(x+1)
\end{math}

\noindent which is ugly.
To keep parentheses around \math{x+1} small, you should put braces around the expression:

\begin{verbatim}
\line
\\Gamma (\\frac\{\\zeta\}\{2\}) + x^2\{(x+1)\}
\line
\end{verbatim}

\begin[mode=display]{math}
    \Gamma (\frac{\zeta}{2}) + x^2{(x+1)}
\end{math}

\noindent To print a brace in a formula, you need to escape it with a backslash.

In the \code{math} syntax, every individual letter is an identifier (MathML tag \code{mi}), every number is a… number (tag \code{mn}) and all other characters are operators (tag \code{mo}).
If it does not suit you, you can explicitly use the \code{\\mi}, \code{\\mn} or \code{\\mo} tags.
For instance, \code{sin(x)} will be rendered as \math{sin(x)}, because SILE considers the letters s, i and n to be individual identifiers, and identifiers made of one character are italicized by default.
To avoid that, you can specify that \math{\mi{sin}} is an identifier by writing \code{\\mi\{sin\}(x)} and get: \math{\mi{sin}(x)}.
If you prefer it in “double struck” style, this is permitted by the \code{mathvariant} attribute: \code{\\mi[mathvariant=double-struck]\{sin\}(x)} renders as \math{\mi[mathvariant=double-struck]{sin}(x)}.

To save you some typing, the math syntax lets you define macros with the following syntax:

\begin{verbatim}
\line
\\def\{macro-name\}\{macro-body\}
\line
\end{verbatim}

\noindent where in the macro’s body \code{#1}, \code{#2}, etc. will be replaced by the macro’s arguments.
For instance:

\begin{verbatim}
\line
\\begin[mode=display]\{math\}
    \\def\{diff\}\{\\mfrac\{\\mo\{d\}#1\}\{\\mo\{d\}#2\}\}
    \\def\{bi\}\{\\mi[mathvariant=bold-italic]\{#1\}\}

    \\diff\{\\bi\{p\}\}\{t\} = ∑_i \\bi\{F\}_i
\\end\{math\}
\line
\end{verbatim}

\noindent results in:

\begin[mode=display]{math}
  \def{diff}{\mfrac{\mo{d}#1}{\mo{d}#2}}
  \def{bi}{\mi[mathvariant=bold-italic]{#1}}
  \diff{\bi{p}}{t} = ∑_i \bi{F}_i
\end{math}

Finally, tabular math can be typeset using the \code{table} command (or equivalently the \code{mtable} MathML tag).
For instance, to typeset a matrix:

\begin{verbatim}
\line
\\begin[mode=display]\{math\}
    (
    \\table\{
        1 & 2 & 7 \\\\
        0 & 5 & 3 \\\\
        8 & 2 & 1 \\\\
    \}
    )
\\end\{math\}
\line
\end{verbatim}

\noindent will yield:

\begin[mode=display]{math}
  (\table{
       1 & 2 & 7 \\
       0 & 5 & 3 \\
       8 & 2 & 1 \\
  })
\end{math}

\noindent Tables may also be used to control the alignment of formulas:

\begin{verbatim}
\line
\\begin[mode=display]\{math\}
    \\\{
    \\table[columnalign=right center left]\{
        u_0 &=& 1 \\\\
        u_1 &=& 1 \\\\
        u_n &=& u_\{n−1\} + u_{n−2}, \\forall n ⩾ 2 \\\\
    \}
\\end\{math\}
\line
\end{verbatim}

\begin[mode=display]{math}
    \{
    \table[columnalign=right center left]{
        u_0 &=& 1 \\
        u_1 &=& 1 \\
        u_n &=& u_{n−1} + u_{n−2}, \forall n ⩾ 2 \\
    }
\end{math}

\noindent Tables currently do not support all attributes required by the MathML standard, but they do allow to control spacing using the \code{rowspacing} and \code{columnspacing} options.

Finally, here is a little secret. This notation:

\begin{verbatim}
\line
\\table\{
    1 & 2 & 7 \\\\
    0 & 5 & 3 \\\\
    8 & 2 & 1 \\\\
\}
\line
\end{verbatim}

\noindent is strictly equivalent to this one:

\begin{verbatim}
\line
\\table\{
        \{1\} \{2\} \{7\}
    \}\{
        \{0\} \{5\} \{3\}
    \}\{
        \{8\} \{2\} \{1\}
    \}
\}
\line
\end{verbatim}

\noindent In other words, the notation using \code{&} and \code{\\\\} is only a syntactic sugar for a two-dimensional array constructed with braces.

When macros are not enough, creating new mathematical elements is quite simple: one only needs to create a new class deriving from \code{mbox} (defined in \code{packages/math/base-elements.lua}) and define the \code{shape} and \code{output} methods.
\code{shape} must define the \code{width}, \code{height} and \code{depth} attributes of the element, while \code{output} must draw the actual output.
An \code{mbox} may have one or more children (for instance, a fraction has two children — its numerator and denominator).
The \code{shape} and \code{output} methods of the children are called automatically.

This package still lacks support for some mathematical constructs, but hopefully we’ll get there.
Among unsupported constructs are: decorating symbols with so-called accents, such as arrows or hats, “over” or “under” braces, and line breaking inside a formula.

\font:remove-fallback
\end{document}
]]

return package
