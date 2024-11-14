local base = require("packages.base")

local package = pl.class(base)
package._name = "math"

function package:_init ()
   base._init(self)
   local typesetter = require("packages.math.typesetter")
   self.ConvertMathML, self.handleMath = typesetter[1], typesetter[2]
   local texlike = require("packages.math.texlike")
   self.convertTexlike, self.compileToMathML = texlike[1], texlike[2]
   -- Register a new unit that is 1/18th of the current math font size
   SILE.registerUnit("mu", {
      relative = true,
      definition = function (value)
         return value * SILE.settings:get("math.font.size") / 18
      end,
   })
   self:loadPackage("counters")
end

function package.declareSettings (_)
   SILE.settings:declare({
      parameter = "math.font.family",
      type = "string",
      default = "Libertinus Math",
   })
   SILE.settings:declare({
      parameter = "math.font.style",
      type = "string",
      default = "Regular",
   })
   SILE.settings:declare({
      parameter = "math.font.weight",
      type = "integer",
      default = 400,
   })
   SILE.settings:declare({
      parameter = "math.font.filename",
      type = "string",
      default = "",
   })
   SILE.settings:declare({
      parameter = "math.font.size",
      type = "integer",
      default = 10,
   })
   -- Whether to show debug boxes around mboxes
   SILE.settings:declare({
      parameter = "math.debug.boxes",
      type = "boolean",
      default = false,
   })
   SILE.settings:declare({
      parameter = "math.displayskip",
      type = "VGlue",
      default = SILE.types.node.vglue("2ex plus 1pt"),
   })

   -- Penalties for breaking before and after a display math formula
   -- See TeX's \predisplaypenalty and \postdisplaypenalty
   SILE.settings:declare({
      parameter = "math.predisplaypenalty",
      type = "integer",
      default = 10000, -- strict no break by default as in (La)TeX
      help = "Penalty for breaking before a display math formula",
   })
   SILE.settings:declare({
      parameter = "math.postdisplaypenalty",
      type = "integer",
      -- (La)TeX's default is 0 (a normal line break penalty allowing a break
      -- after a display math formula)
      -- See https://github.com/sile-typesetter/sile/issues/2160
      --    And see implementation in handleMath(): we are not yet doing the right
      --    things with respect to paragraphing, so setting a lower value for now
      --    to ease breaking after a display math formula rather than before
      --    when the formula is in the middle of a paragraph.
      --    (In TeX, these penalties would apply in horizontal mode, with a display
      --    math formula being a horizontal full-width box, our implementation
      --    currently use them as vertical penalties).
      default = -50,
      help = "Penalty for breaking after a display math formula",
   })
end

function package:registerCommands ()
   self:registerCommand("mathml", function (options, content)
      local mbox
      xpcall(function ()
         mbox = self:ConvertMathML(content)
      end, function (err)
         print(err)
         print(debug.traceback())
      end)
      self:handleMath(mbox, options)
   end)

   self:registerCommand("math", function (options, content)
      local mbox
      xpcall(function ()
         mbox = self:ConvertMathML(self:compileToMathML({}, self:convertTexlike(content)))
      end, function (err)
         print(err)
         print(debug.traceback())
      end)
      self:handleMath(mbox, options)
   end)

   self:registerCommand("math:numberingstyle", function (options, _)
      SILE.typesetter:typeset("(")
      if options.counter then
         SILE.call("show-counter", { id = options.counter })
      elseif options.number then
         SILE.typesetter:typeset(options.number)
      end
      SILE.typesetter:typeset(")")
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
\define[command=paragraph]{\smallskip\em{\process.}\novbreak\par}
The \autodoc:package{math} package provides typesetting of formulas directly in a SILE document.

\autodoc:note{Mathematical typesetting in SILE is still in its infancy.
As such, it lacks some features and may contain bugs.
Feedback and contributions are always welcome.}

\noindent To typeset mathematics, you will need an OpenType math font installed on your system.%
%\footnote{A list of freely available math fonts can be found at \href[src=https://www.ctan.org/pkg/unicode-math]{https://www.ctan.org/pkg/unicode-math}}
By default, this package uses Libertinus Math, so it will fail if Libertinus Math can’t be found.
Another font may be specified via the setting \autodoc:setting{math.font.family}.
If required, you can set the font style and weight via \autodoc:setting{math.font.style} and \autodoc:setting{math.font.weight}.
The font size can be set via \autodoc:setting{math.font.size}.

\paragraph{MathML}
The first way to typeset math formulas is to enter them in the MathML format.
MathML is a standard for encoding mathematical notation for the Web and for other types of digital documents.
It is supported by a wide range of tools and represents the most promising format for unifying the encoding of mathematical notation, as well as improving its accessibility (e.g., to blind users).

To render an equation encoded in MathML, simply put it in a \code{mathml} command.
For example, the formula \mathml{\mrow{\msup{\mi{a}\mn{2}} \mo{+} \msup{\mi{b}\mn{2}} \mo{=} \msup{\mi{c}\mn{2}}}} was typeset by the following command:

\begin[type=autodoc:codeblock]{raw}
\mathml{
    \mrow{
        \msup{\mi{a}\mn{2}}
        \mo{+}
        \msup{\mi{b}\mn{2}}
        \mo{=}
        \msup{\mi{c}\mn{2}}
    }
}
\end{raw}

\noindent In an XML document, we could use the more classical XML syntax:

\begin[type=autodoc:codeblock]{raw}
<mathml>
    <mrow>
        <msup> <mi>a</mi> <mn>2</mn> </msup>
        <mo>+</mo>
        <msup> <mi>b</mi> <mn>2</mn> </msup>
        <mo>=</mo>
        <msup> <mi>c</mi> <mn>2</mn> </msup>
    </mrow>
</mathml>
\end{raw}

\noindent By default, formulas are integrated into the flow of text.
To typeset them on their own line, use the \autodoc:parameter{mode=display} option:

\mathml[mode=display]{
    \mrow{
        \msup{\mi{a}\mn{2}}
        \mo{+}
        \msup{\mi{b}\mn{2}}
        \mo{=}
        \msup{\mi{c}\mn{2}}
    }
}

\paragraph{TeX-like syntax}
As the previous examples illustrate, MathML is not really intended to be written by humans and quickly becomes very verbose.
That is why this package also provides a \code{math} command, which understands a syntax similar to the math syntax of TeX.
To typeset the above equation, one only has to type \code{\\math\{a^2 + b^2 = c^2\}}.

Here is a slightly more involved equation:

\begin[type=autodoc:codeblock]{raw}
\begin[mode=display]{math}
    \sum_{n=1}^\infty \frac{1}{n^2} = \frac{\pi^2}{6}
\end{math}
\end{raw}

\noindent This renders as:

\begin[mode=display]{math}
    \sum_{n=1}^\infty \frac{1}{n^2} = \frac{\pi^2}{6}
\end{math}

The general philosophy of the TeX-like syntax is to be a simple layer on top of MathML, and not to mimic perfectly the syntax of the LaTeX tool.
Its main difference from the SILE syntax is that \code{\\mycommand\{arg1\}\{arg2\}\{arg3\}} is translated into MathML as \code{<mycommand> arg1 arg2 arg3 </mycommand>} whereas in normal SILE syntax, the XML equivalent would be \code{<mycommand>arg1</mycommand> arg2 arg3}.

\code{\\sum}, \code{\\infty}, and \code{\\pi} are only shorthands for the Unicode characters \math{\sum}, \math{\infty} and \math{\pi}.
If it’s more convenient, you can use these Unicode characters directly.
The symbol shorthands are the same as in the TeX package \href[src=https://www.ctan.org/pkg/unicode-math]{\code{unicode-math}}.

\code{\{formula\}} is a shorthand for \code{\\mrow\{formula\}}.
Since parentheses—among other glyphs—stretch vertically to the size of their englobing \code{mrow}, this is useful to typeset parentheses of different sizes on the same line:

\begin[type=autodoc:codeblock]{raw}
\Gamma (\frac{\zeta}{2}) + x^2(x+1)
\end{raw}

\noindent renders as

\begin[mode=display]{math}
    \Gamma (\frac{\zeta}{2}) + x^2(x+1)
\end{math}

\noindent which is ugly.
To keep parentheses around \math{x+1} small, you should put braces around the expression:

\begin[type=autodoc:codeblock]{raw}
\Gamma (\frac{\zeta}{2}) + x^2{(x+1)}
\end{raw}

\begin[mode=display]{math}
    \Gamma (\frac{\zeta}{2}) + x^2{(x+1)}
\end{math}

\noindent To print a brace in a formula, you need to escape it with a backslash.

\paragraph{Token kinds}
In the \code{math} syntax, every individual letter is an identifier (MathML tag \code{mi}), every number is a… number (tag \code{mn}) and all other characters are operators (tag \code{mo}).
If this does not suit you, you can explicitly use the \code{\\mi}, \code{\\mn}, or \code{\\mo} tags.
For instance, \code{sin(x)} will be rendered as \math{sin(x)}, because SILE considers the letters s, i and n to be individual identifiers, and identifiers made of one character are italicized by default.
To avoid that, you can specify that \math{\mi{sin}} is an identifier by writing \code{\\mi\{sin\}(x)} and get: \math{\mi{sin}(x)}.
If you prefer it in “double struck” style, this is permitted by the \code{mathvariant} attribute: \code{\\mi[mathvariant=double-struck]\{sin\}(x)} renders as \math{\mi[mathvariant=double-struck]{sin}(x)}.

\paragraph{Atom types and spacing}
Each token automatically gets assigned an atom type from the list below:
\begin{itemize}
  \item{\code{ord}: \code{mi} and \code{mn} tokens, as well as unclassified operators}
  \item{\code{big}: big operators like ‘\math{\sum}’ or ‘\math{\prod}’}
  \item{\code{bin}: binary operators like ‘\math{+}’ or ‘\math{\%}’}
  \item{\code{rel}: relation operators like ‘\math{=}’ or ‘\math{<}’}
  \item{\code{open}: opening operators like ‘\math{(}’ or ‘\math{[}’}
  \item{\code{close}: closing operators like ‘\math{)}’ or ‘\math{]}’}
  \item{\code{punct}: punctuation operators like ‘\math{,}’}
  % TODO: Those are defined in the 'math' package but appear to be unused
  %\item{\code{inner}}
  %\item{\code{over}}
  %\item{\code{under}}
  %\item{\code{accent}}
  %\item{\code{radical}}
  %\item{\code{vcenter}}
\end{itemize}
\noindent The spacing between any two successive tokens is set automatically based on their atom types, and hence may not reflect the actual spacing used in the input.
To make an operator behave like it has a certain atom type, you can use the \code{atom} attribute. For example, \code{a \\mo[atom=bin]\{div\} b} renders as \math[mode=display]{a \mo[atom=bin]{div} b.}

Spaces in math mode are defined in “math units” (mu), which are 1/18 of an em of the current \em{math} font (and are independent of the current text font size).
Standard spaces inserted automatically between tokens come in three varieties: thin (3 mu), medium (4 mu) and thick (5 mu).
If needed, you can insert them manually with the \code{\\thinspace} (or \code{\\,}), \code{\\medspace} (or \code{\\>}), and \code{\\thickspace} (or \code{\\;}) commands.
Negative space counterparts are available as \code{\\negthinspace} (or \code{\\!}), \code{\\negmedspace}, and \code{\\negthickspace}.
The \code{\\enspace}, \code{\\quad}, and \code{\\qquad} commands from normal text mode are also available, but the spaces they insert scale relative to the text font size.
Finally, you can add a space of any size using the \code{\\mspace[width=<dimension>]} command.

\paragraph{Macros}
To save you some typing, the math syntax lets you define macros with the following syntax:

\begin[type=autodoc:codeblock]{raw}
\def{macro-name}{macro-body}
\end{raw}

\noindent where in the macro’s body \code{#1}, \code{#2}, etc. will be replaced by the macro’s arguments.
For instance:

\begin[type=autodoc:codeblock]{raw}
\begin[mode=display]{math}
    \def{diff}{\mfrac{\mo{d}#1}{\mo{d}#2}}
    \def{bi}{\mi[mathvariant=bold-italic]{#1}}

    \diff{\bi{p}}{t} = ∑_i \bi{F}_i
\end{math}
\end{raw}

\noindent results in:

\begin[mode=display]{math}
  \def{diff}{\mfrac{\mo{d}#1}{\mo{d}#2}}
  \def{bi}{\mi[mathvariant=bold-italic]{#1}}
  \diff{\bi{p}}{t} = ∑_i \bi{F}_i
\end{math}

When macros are not enough, creating new mathematical elements is quite simple: one only needs to create a new class deriving from \code{mbox} (defined in \code{packages/math/base-elements.lua}) and define the \code{shape} and \code{output} methods.
\code{shape} must define the \code{width}, \code{height} and \code{depth} attributes of the element, while \code{output} must draw the actual output.
An \code{mbox} may have one or more children (for instance, a fraction has two children—its numerator and denominator).
The \code{shape} and \code{output} methods of the children are called automatically.

\paragraph{Matrices, aligned equations, and other tables}
Tabular math can be typeset using the \code{table} command (or equivalently the \code{mtable} MathML tag).
For instance, to typeset a matrix:

\begin[type=autodoc:codeblock]{raw}
\begin[mode=display]{math}
    (
    \table{
        1 & 2 & 7 \\
        0 & 5 & 3 \\
        8 & 2 & 1 \\
    }
    )
\end{math}
\end{raw}

\noindent will yield:

\begin[mode=display]{math}
  (\table{
       1 & 2 & 7 \\
       0 & 5 & 3 \\
       8 & 2 & 1 \\
  })
\end{math}

\noindent Tables may also be used to control the alignment of formulas:

\begin[type=autodoc:codeblock]{raw}
\begin[mode=display]{math}
    \{
    \table[columnalign=right center left]{
        u_0 &=& 1 \\
        u_1 &=& 1 \\
        u_n &=& u_{n−1} + u_{n−2}, \forall n ⩾ 2 \\
    }
\end{math}
\end{raw}

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

\begin[type=autodoc:codeblock]{raw}
\table{
    1 & 2 & 7 \\
    0 & 5 & 3 \\
    8 & 2 & 1 \\
}
\end{raw}

\noindent is strictly equivalent to this one:

\begin[type=autodoc:codeblock]{raw}
\table{
        {1} {2} {7}
    }{
        {0} {5} {3}
    }{
        {8} {2} {1}
    }
}
\end{raw}

\noindent In other words, the notation using \code{&} and \code{\\\\} is only a syntactic sugar for a two-dimensional array constructed with braces.

\paragraph{Numbered equations}
Equations can be numbered in display mode.

When \autodoc:parameter{numbered=true}, equations are numbered using a default “equation” counter:
\math[mode=display, numbered=true]{e^{i\pi} = -1}

A different counter can be set by using the option \autodoc:parameter{counter=<id>}, and this setting will also enable numbering.

It is also possible to impose direct numbering using the \autodoc:parameter{number=<value>} option.

The default numbering format is \autodoc:example{(n)}, but this style may be overridden by defining a custom \autodoc:command{\math:numberingstyle} command.
The \code{counter} or the direct value \code{number} is passed as a parameter to this hook, as well as any other options.

\paragraph{Missing features}
This package still lacks support for some mathematical constructs, but hopefully we’ll get there.
Among unsupported constructs are: decorating symbols with so-called accents, such as arrows or hats, “over” or “under” braces, and line breaking inside a formula.

\font:remove-fallback
\end{document}
]]

return package
