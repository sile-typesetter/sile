local base = require("packages.base")

local package = pl.class(base)
package._name = "specimen"

function package:registerCommands ()

  local metrics = require("fontmetrics")

  self:registerCommand("repertoire", function(_, _)
    local ot = require("core.opentype-parser")
    local fontoptions = SILE.font.loadDefaults({})
    local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
    local font = ot.parseFont(face)
    local maxg = font.maxp.numGlyphs
    for i = 1 , maxg - 1 do
      local wd = metrics.glyphwidth(i, face.data, face.index)
      SILE.typesetter:pushHbox({
        height= SILE.length(1.2 * fontoptions.size),
        width= SILE.length(wd * fontoptions.size),
        depth= 0,
        value= { options = fontoptions, glyphString =  { i } },
      })
      SILE.typesetter:pushGlue(((1-wd) * fontoptions.size).."pt plus 1pt minus 1pt")
    end
  end)

  self:registerCommand("pangrams", function (_, _)
    local pg = {
      "Sphinx of black quartz, judge my vow!",
      "The five boxing wizards jump quickly.",
      "Five quacking zephyrs jolt my wax bed.",
      "Pack my box with five dozen liquor jugs.",
      "Grumpy wizards make toxic brew for the evil queen and jack.",
      "Voix ambiguë d’un cœur qui au zéphyr préfère les jattes de kiwi.",
    }
    for i = 1, #pg do
      SILE.typesetter:typeset(pg[i] .. " ")
    end
    SILE.call("bigskip")
  end)

  self:registerCommand("set-to-width", function(options, content)
    local width = SU.required(options, "width", "set to width", "length"):absolute()
    local fontOptions = SILE.font.loadDefaults({})
    for line in SU.gtoke(content[1],"\n+") do
      if line.string then
        local tokens = SILE.shaper:shapeToken(line.string,fontOptions)
        local w = 0
        for j= 1,#tokens do w = w + tokens[j].width end
        local ratio = width.length / w
        SILE.call("font", {size = fontOptions.size * ratio}, function()
          SILE.process({line.string})
          SILE.call("par")
        end)
      end
    end
  end)

end

package.documentation = [[
\begin{document}
\use[module=packages.specimen]
SILE has found itself becoming well used by type designers, who often want to create specimen documents to show off their new fonts.
This package provides a few commands to help create test documents.
(The \code{fontproof} class, available from the package manager, contains many more tools for creating specimens.)
The \autodoc:command{\repertoire} command prints out every glyph in the font, in a simple table.
The \autodoc:command{\pangrams} command prints out a few pangrams for the Latin script.
Finally, \autodoc:command{\set-to-width[width=<dimension>]{<content>}} will process each line of content, changing the font size so that the output is a constant width.

\begin[type=autodoc:codeblock]{raw}
\begin[width=4cm]{set-to-width}
CAPERCAILLIE
LAMMERGEYER
CASSOWARY
ACCENTOR DOWITCHER DOTTEREL
\end{set-to-width}
\end{raw}

\begin{examplefont}
\begin[width=4cm]{set-to-width}
CAPERCAILLIE
LAMMERGEYER
CASSOWARY
ACCENTOR DOWITCHER DOTTEREL
\end{set-to-width}
\end{examplefont}
\end{document}
]]

return package
