local base = require("packages.base")

local package = pl.class(base)
package._name = "unichar"

local chars = {
  ["victory-hand"] = "U+270C",  -- ✌
  ["writing-hand"] = "U+270D", -- ✍
  ["check-mark"] = "U+2713 ", -- ✓
  ["greek-cross"] = "U+2719", -- ✙
  ["maltese-cross"] = "U+2720", --  ✠
  ["syriac-cross"] = "U+2670", -- ♰
  ["star-of-david"] = "U+2721", -- ✡
  ["snowflake"] = "U+2744", -- ❄
  ["bullseye"] = "U+25CE", -- ◎
  ["skull"] = "U+2620", -- ☠
  ["chi-rho"] = "U+2627", -- ☧
  ["dharmachakra"] = "U+2638", -- ☸
  ["hammer-and-sickle"] = "U+262D", -- ☭
  ["recycling-symbol"] = "U+267B", -- ♻
  ["gear"] = "U+2699", -- ⚙ 
  ["balance"] = "U+2696", -- ⚖
  ["anchor"] = "U+2693", -- ⚓
  ["female-sign"] = "U+2640", -- ♀
  ["male-sign"] = "U+2642", -- ♂
  ["unisex-sign"] = "U+26A5", -- ⚥
  ["atom"] = "U+269B" -- ⚛
}

function package:registerCommands ()

  self:registerCommand("unichar", function(_, content)
    local cp = content[1]
    if type(cp) ~= "string" then SU.error(tostring(cp) .. "Bad argument to \\unicode") end
    local hlist = SILE.typesetter.state.nodes
    local char = SU.utf8charfromcodepoint(cp)
    if #hlist > 1 and hlist[#hlist].is_unshaped
                  and pl.tablex.deepcompare(hlist[#hlist].options, SILE.font.loadDefaults({})) then
      -- Stack character with a preceeding unshaped node if its font is the
      -- same as the current one, so that combining characters (e.g. diacritics)
      -- and kerning works with \unichar'ed code points too.
      hlist[#hlist].text = hlist[#hlist].text .. char
    else
      SILE.typesetter:typeset(char)
    end
  end)

  for k, v in pairs(chars) do
    self:registerCommand(k, function(_, _)
      SILE.call("font", {family = "Noto Emoji"}, function()
        SILE.call("unichar", {}, {v})
      end)
    end)
  end
end

package.documentation = [[
\begin{document}
\use[module=packages.unichar]
SILE is Unicode compatible, and expects its input files to be in the UTF-8 encoding.
(The actual range of Unicode characters supported will depend on the supported ranges of the fonts that SILE is using to typeset.)
Some Unicode characters are hard to locate on a standard keyboard, and so are difficult to enter into SILE documents.

The \autodoc:package{unichar} package helps with this problem by providing the \autodoc:command{\unichar} command to enter Unicode codepoints.

\begin[type=autodoc:codeblock]{raw}
\unichar{U+263A}
\end{raw}

This produces: \font[family=Symbola]{\unichar{U+263A}}

If the argument to \autodoc:command{\unichar} begins with \code{U+}, \code{u+}, \code{0x}, or \code{0X}, then it is assumed to be a hexadecimal value.
Otherwise it is assumed to be a decimal codepoint.
\end{document}
]]

return package
