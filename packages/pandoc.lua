SILE.require("packages/url")
SILE.require("packages/pdf")
SILE.require("packages/image")
SILE.require("packages/footnotes")
SILE.require("packages/raiselower")

-- Process arguments that might not actually have that much to do with their
-- immediate function but affect the document in other ways, such as setting
-- bookmarks on anything tagged with an ID attribute.
local handlePandocArgs = function (options)
  local wrapper = SILE.settings.wrap()
  if options.id then
    SU.debug("pandoc", "Set ID on tag")
  end
  if options.lang then
    SU.debug("pandoc", "Set lang tag: "..options.lang)
    local fontfunc = SILE.Commands[SILE.Commands["font:" .. options.lang] and "font:" .. options.lang or "font"]
    local innerWrapper = wrapper
    wrapper = function (content) innerWrapper(function () fontfunc({ language = options.lang }, content) end) end
  end
  if options.classes then
    for _,class in pairs(options.classes:split(",")) do
      SU.debug("pandoc", "Add div class: "..class)
      if SILE.Commands["class:"..class] then
        local innerWrapper = wrapper
        wrapper = function (content) innerWrapper(function () SILE.Commands["class:"..class](options, content) end) end
      end
    end
  end
  return wrapper
end

SILE.registerCommand("label", function(options, content)
  SILE.call("pdf:bookmark", options, content)
end)

SILE.registerCommand("tt", function(options, content)
  SILE.call("verbatim:font", options, content)
end)

SILE.registerCommand("HorizontalRule", function (options, _)
  SILE.call("raise", { height = options.raise or "0.8ex" }, function ()
    SILE.call("hrule", {
        height = options.height or "0.5pt",
        width = options.width or "100%lw"
      })
  end)
end)

SILE.registerCommand("Span", function (options, content)
  handlePandocArgs(options)(content)
end,"Generic inline wrapper")

SILE.registerCommand("Div", function (options, content)
  handlePandocArgs(options)(content)
  SILE.call("par")
end,"Generic inline wrapper")

SILE.registerCommand("Emph", function (_, content)
  SILE.call("em", {}, content)
end,"Inline emphasis wrapper")

SILE.registerCommand("Strong", function (_, content)
  SILE.call("strong", {}, content)
end,"Inline strong wrapper")

SILE.registerCommand("SmallCaps", function (_, content)
  SILE.call("font", { features = "+smcp" }, content)
end,"Inline small caps wrapper")

SILE.registerCommand("csl-no-emph", function (_, content)
  SILE.call("font", { style = "Roman" }, content)
end,"Inline upright wrapper")

SILE.registerCommand("csl-no-strong", function (_, content)
  SILE.call("font", { weight = 400 }, content)
end,"Inline normal weight wrapper")

SILE.registerCommand("csl-no-smallcaps", function (_, content)
  SILE.call("font", { features = "-smcp" }, content)
end,"Inline smallcaps disable wrapper")

local scriptOffset = "0.7ex"
local scriptSize = "1.5ex"

SILE.registerCommand("Superscript", function (_, content)
  SILE.call("raise", { height = scriptOffset }, function ()
    SILE.call("font", { size = scriptSize }, content)
  end)
end,"Inline superscript wrapper")

SILE.registerCommand("Subscript", function (_, content)
  SILE.call("lower", { height = scriptOffset }, function ()
    SILE.call("font", { size = scriptSize }, content)
  end)
end,"Inline subscript wrapper")

SILE.registerCommand("unimplemented", function (_, content)
  SU.debug("pandoc", "Un-implemented function")
  SILE.process(content)
end,"Unimplemented Pandoc function wrapper")

SILE.Commands["strikeout"] = SILE.Commands["unimplemented"]

return { documentation = [[\begin{document}

Try to cover all the possible commands Pandoc's SILE export might throw at us.

Provided by in base classes etc.:

\listitem \code{listarea}
\listitem \code{listitem}

Modified from default:


Provided specifically for Pandoc:

\listitem \code{Span}
\listitem \code{Div}
\listitem \code{Emph}
\listitem \code{Strong}
\listitem \code{SmallCaps}
\listitem \code{Strikeout}
\listitem \code{csl-no-emph}
\listitem \code{csl-no-strong}
\listitem \code{csl-no-smallcaps}
\listitem \code{Superscript}
\listitem \code{Subscript}

\end{document}]] }
