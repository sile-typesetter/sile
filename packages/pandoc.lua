SILE.require("packages/raiselower")

-- Process arguments that might not actually have that much to do with their
-- immediate function but affect the document in other ways, such as setting
-- bookmarks on anything tagged with an ID attribute.
local handlePandocArgs = function (options)
  if options.id then
    SU.debug("pandoc", "Set ID on tag")
  end
end

SILE.registerCommand("textem", function (options, content)
  handlePandocArgs(options)
  SILE.call("em", {}, content)
end,"Inline emphasis wrapper")

SILE.registerCommand("textstrong", function (options, content)
  handlePandocArgs(options)
  SILE.call("strong", {}, content)
end,"Inline strong wrapper")

SILE.registerCommand("textsc", function (options, content)
  handlePandocArgs(options)
  SILE.call("font", { features = "+smcp" }, content)
end,"Inline small caps wrapper")

SILE.registerCommand("textup", function (options, content)
  handlePandocArgs(options)
  SILE.call("font", { style = "Roman" }, content)
end,"Inline upright wrapper")

SILE.registerCommand("textnormal", function (options, content)
  handlePandocArgs(options)
  SILE.call("font", { weight = 400 }, content)
end,"Inline upright wrapper")

local scriptOffset = "0.7ex"
local scriptSize = "1.5ex"

SILE.registerCommand("textsuperscript", function (options, content)
  handlePandocArgs(options)
  SILE.call("raise", { height = scriptOffset }, function ()
    SILE.call("font", { size = scriptSize }, content)
  end)
end,"Inline superscript wrapper")

SILE.registerCommand("textsubscript", function (options, content)
  handlePandocArgs(options)
  SILE.call("lower", { height = scriptOffset }, function ()
    SILE.call("font", { size = scriptSize }, content)
  end)
end,"Inline subscript wrapper")

SILE.registerCommand("unimplemented", function (options, content)
  handlePandocArgs(options)
  SU.debug("pandoc", "Un-implemented function")
  SILE.process(content)
end,"Inline small caps wrapper")

SILE.Commands["strike"] = SILE.Commands["unimplemented"]
SILE.Commands["strike"] = SILE.Commands["unimplemented"]


return { documentation = [[\begin{document}

Try to cover all the possible commands Pandoc's SILE export might throw at us.

Provided by in base classes etc.:

\listitem \code{listarea}
\listitem \code{listitem}

Provided specifically for Pandoc:

\listitem \code{span}
\listitem \code{textem}
\listitem \code{textstrong}
\listitem \code{textsc}
\listitem \code{textnosc}
\listitem \code{textnoem}
\listitem \code{textnostrong}
\listitem \code{textsuperscript}
\listitem \code{textsubscript}

\end{document}]] }
