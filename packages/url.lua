SILE.require("packages/verbatim")
local pdf
pcall(function() pdf = require("justenoughlibtexpdf") end)
if pdf then SILE.require("packages/pdf") end

local inputfilter = SILE.require("packages/inputfilter").exports

-- URL escape sequence, URL fragment:
local preferBreakBefore = "%#"
-- URL path elements, URL query arguments, acceptable extras:
local preferBreakAfter = ":/.;?&=!_-"
-- URL scheme:
local alwaysBreakAfter = ":" -- Must have only one character here!

local escapeRegExpMinimal = function (str)
  -- Minimalist = just what's needed for the above strings
  return string.gsub(str, '([%.%?%-%%])', '%%%1')
end

local breakPattern = "["..escapeRegExpMinimal(preferBreakBefore..preferBreakAfter..alwaysBreakAfter).."]"

local urlFilter = function (node, content, options)
  if type(node) == "table" then return node end

  local result = {}
  for token in SU.gtoke(node, breakPattern) do
    if token.string then
      result[#result+1] = token.string
    else
      if string.find(preferBreakBefore, escapeRegExpMinimal(token.separator)) then
        -- Accepts breaking before, and at the extreme worst after.
        result[#result+1] = inputfilter.createCommand(
          content.pos, content.col, content.line,
          "penalty", { penalty = options.primaryPenalty }, nil
        )
        result[#result+1] = token.separator
        result[#result+1] = inputfilter.createCommand(
          content.pos, content.col, content.line,
          "penalty", { penalty = options.worsePenalty }, nil
        )
      elseif token.separator == alwaysBreakAfter then
        -- Accept breaking after (only).
        result[#result+1] = token.separator
        result[#result+1] = inputfilter.createCommand(
          content.pos, content.col, content.line,
          "penalty", { penalty = options.primaryPenalty }, nil
        )
      else
        -- Accept breaking after, but tolerate breaking before.
        result[#result+1] = inputfilter.createCommand(
          content.pos, content.col, content.line,
          "penalty", { penalty = options.secondaryPenalty }, nil
        )
        result[#result+1] = token.separator
        result[#result+1] = inputfilter.createCommand(
          content.pos, content.col, content.line,
          "penalty", { penalty = options.primaryPenalty }, nil
        )
      end
    end
  end
  return result
end

SILE.settings.declare({
  parameter = "url.linebreak.primaryPenalty",
  type = "integer",
  default = 100,
  help = "Penalty for breaking lines in URLs at preferred breakpoints"
})

SILE.settings.declare({
  parameter = "url.linebreak.secondaryPenalty",
  type = "integer",
  default = 200,
  help = "Penalty for breaking lines in URLs at tolerable breakpoints (should be higher than url.linebreak.primaryPenalty)"
})

SILE.registerCommand("href", function (options, content)
  if not pdf then return SILE.process(content) end
  if options.src then
    SILE.call("pdf:link", { dest = options.src, external = true,
      borderwidth = options.borderwidth,
      borderstyle = options.borderstyle,
      bordercolor = options.bordercolor,
      borderoffset = options.borderoffset },
      content)
  else
    options.src = content[1]
    SILE.call("pdf:link", { dest = options.src, external = true,
      borderwidth = options.borderwidth,
      borderstyle = options.borderstyle,
      bordercolor = options.bordercolor,
      borderoffset = options.borderoffset },
      function (_, _)
        SILE.call("url", { language = options.language }, content)
      end)
  end
end, "Inserts a PDF hyperlink.")

SILE.registerCommand("url", function (options, content)
  SILE.settings.temporarily(function ()
    local primaryPenalty = SILE.settings.get("url.linebreak.primaryPenalty")
    local secondaryPenalty = SILE.settings.get("url.linebreak.secondaryPenalty")
    local worsePenalty = primaryPenalty + secondaryPenalty

    if options.language then
      SILE.languageSupport.loadLanguage(options.language)
      if options.language == "fr" then
        -- Trick the engine by declaring a "fake"" language that doesn't apply
        -- the typographic rules for punctuations
        SILE.hyphenator.languages["_fr_noSpacingRules"] = SILE.hyphenator.languages.fr
        -- Not needed (the engine already defaults to SILE.nodeMakers.unicode if
        -- the language is not found):
        -- SILE.nodeMakers._fr_noSpacingRules = SILE.nodeMakers.unicode
        SILE.settings.set("document.language", "_fr_noSpacingRules")
      else
        SILE.settings.set("document.language", options.language)
      end
    else
      SILE.settings.set("document.language", 'und')
    end

    local result = inputfilter.transformContent(content, urlFilter, {
      primaryPenalty = primaryPenalty,
      secondaryPenalty = secondaryPenalty,
      worsePenalty = worsePenalty
    })
    SILE.call("code", {}, result)
  end)
end, "Inserts penalties in an URL so it can be broken over multiple lines at appropriate places.")

SILE.registerCommand("code", function(options, content)
  SILE.call("verbatim:font", options, content)
end)

return {
  documentation = [[\begin{document}
This package enhances the typesetting of URLs in two ways.
First, the \code{\\url} command will automatically insert breakpoints into unwieldy
URLs like \url{https://github.com/sile-typesetter/sile-typesetter.github.io/tree/master/examples}
so that they can be broken up over multiple lines.

It also provides the
\code{\\href[src=...]\{\}} command which inserts PDF hyperlinks,
\href[src=http://www.sile-typesetter.org/]{like this}.

The \code{\\href} command accepts the same \code{borderwidth}, \code{bordercolor},
\code{borderstyle} and \code{borderoffset} styling options as the \code{\\pdf:link} command
from the \code{pdf} package, for instance
\href[src=http://www.sile-typesetter.org/, borderwidth=0.4pt, bordercolor=blue, borderstyle=underline]{like this}.
||||||| 190683a8
This package enhances the typesetting of URLs in two ways.
First, the \code{\\url} command will automatically insert breakpoints into unwieldy
URLs like \url{https://github.com/sile-typesetter/sile-typesetter.github.io/tree/master/examples}
so that they can be broken up over multiple lines.

It also provides the
\code{\\href[src=...]\{\}} command which inserts PDF hyperlinks,
\href[src=http://www.sile-typesetter.org/]{like this}.

The \code{\\href} command accepts the same \code{borderwidth}, \code{bordercolor},
\code{borderstyle} and \code{borderoffset} styling options as the \code{\\pdf:link} command
from the \code{pdf} package, for instance
\href[src=http://www.sile-typesetter.org/, borderwidth=0.4pt, bordercolor=blue, borderstyle=underline]{like this}.
\end{document}]]
}
