local base = require("packages.base")

local package = pl.class(base)
package._name = "font-fallback"

local lastShaperType

function package:registerCommands ()

  self:registerCommand("font:clear-fallbacks", function ()
    if SILE.shaper._name == "fallback" and lastShaperType then
      SU.debug("font-fallback", "Clearing fallbacks, switching from fallback enabled back to previous shaper")
      SILE.shapers:clearFallbacks()
      SILE.typesetter:leaveHmode(true)
      SILE.shapers[lastShaperType]:cast(SILE.shaper)
      lastShaperType = nil
    end
  end)

  self:registerCommand("font:add-fallback", function (options, _)
    if SILE.shaper._name ~= "fallback" then
      SU.debug("font-fallback", "Switching to fallback enabaled shaper")
      SILE.typesetter:leaveHmode(true)
      lastShaperType = SILE.shaper._name
      SILE.shapers.fallback:cast(SILE.shaper)
    end
    SILE.shaper:addFallback(options)
  end)

  self:registerCommand("font:remove-fallback", function ()
    SILE.shaper:removeFallback()
    if #SILE.shaper:dumpFallbacks() == 0 and SILE.shaper._name == "fallback" and lastShaperType then
      SU.debug("font-fallback", "Fallback list empty, switching from fallback enabled back to previous shaper")
      SILE.typesetter:leaveHmode(true)
      SILE.shapers[lastShaperType]:cast(SILE.shaper)
      lastShaperType = nil
    end
  end, "Pop last added fallback from fallback stack")

end

package.documentation = [[
\begin{document}
What happens when SILE is asked to typeset a character which is not in the current font?
For instance, we are currently using the Gentium font, which covers a wide range of European scripts; however, it doesn’t contain any Japanese characters.
  So what if I ask SILE to typeset \code{abc \font[family=Noto Sans CJK JP]{あ}}?

Many applications will find another font on the system containing the appropriate character and use that font instead.
But which font should be chosen?
SILE is designed for typesetting situations where the document or class author wants complete control over the typographic appearance of the output, so it’s not appropriate for it to make a guess—besides, you asked for Gentium.
So where the glyph is not defined, SILE will give you the current font’s “glyph not defined” symbol (a glyph called \code{.notdef}) instead.

But there are times when this is just too strict.
If you’re typesetting a document in English and Japanese, you should be able to choose your English font and choose your Japanese font, and if the glyph isn’t available in one, SILE should try the other.
  The \autodoc:package{font-fallback} package gives you a way to specify a list of font specifications, and it will try each one in turn if glyphs cannot be found.

It provides two commands, \autodoc:command{\font:add-fallback} and \autodoc:command{\font:clear-fallbacks}.
The parameters to \autodoc:command{\font:add-fallback} are the same as the parameters to \autodoc:command{\font}.
So this code:

\begin[type=autodoc:codeblock]{raw}
\font:add-fallback[family=Symbola]
\font:add-fallback[family=Noto Sans CJK JP]
\end{raw}

will add two fonts to try if characters are not found in the current font.
Now we can say:

\font:add-fallback[family=Symbola]
\font:add-fallback[family=Noto Sans CJK JP]

\begin{verbatim}
あば x 😼 Hello world. あ
\end{verbatim}

and SILE will produce:

\autodoc:example{あば x 😼 Hello world. あ}

\font:remove-fallback
\font:remove-fallback

\autodoc:command{\font:clear-fallbacks} removes all font fallbacks from the list of fonts to try.

\autodoc:command{\font:remove-fallback} removes the last added fallback from the list of fonts to try.
\end{document}
]]

return package
