SILE.require("packages/footnotes")
SILE.require("packages/image")
SILE.require("packages/pdf")
SILE.require("packages/raiselower")
SILE.require("packages/rules")
SILE.require("packages/url")
SILE.require("packages/verbatim")

-- Process arguments that might not actually have that much to do with their
-- immediate function but affect the document in other ways, such as setting
-- bookmarks on anything tagged with an ID attribute.
local handlePandocArgs = function (options)
  local wrapper = SILE.settings.wrap()
  if options.id then
    SU.debug("pandoc", "Set ID on tag")
    SILE.call("pdf:bookmark", options, content)
  end
  if options.lang then
    SU.debug("pandoc", "Set lang in tag: "..options.lang)
    local fontfunc = SILE.Commands[SILE.Commands["font:" .. options.lang] and "font:" .. options.lang or "font"]
    local innerWrapper = wrapper
    wrapper = function (content)
      innerWrapper(function ()
        fontfunc({ language = options.lang }, content)
      end)
    end
    options.lang = nil
  end
  if options.classes then
    for _, class in pairs(options.classes:split(",")) do
      SU.debug("pandoc", "Add inner class wrapper: "..class)
      if SILE.Commands["class:"..class] then
        local innerWrapper = wrapper
        wrapper = function (content)
          innerWrapper(function ()
            SILE.call("class:"..class, options, content)
          end)
        end
      end
    end
    options.classes = nil
  end
  return wrapper, options
end

-- Document level stuff


-- Blocks

SILE.registerCommand("BlockQuote", function (_, content)
  SILE.call("quote", {}, content)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("BulletList", function (_, content)
  SILE.settings.temporarily(function ()
    SILE.settings.set("document.rskip","10pt")
    SILE.settings.set("document.lskip","20pt")
    SILE.process(content)
  end)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("CodeBlock", function (options, content)
  local wrapper, args = handlePandocArgs(options)
  wrapper(function ()
    SILE.call("verbatim", args, content)
  end)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("DefinitionList", function (_, content)
  SILE.process(content)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("Div", function (options, content)
  handlePandocArgs(options)(content)
  SILE.typesetter:leaveHmode()
end, "Generic block wrapper")

SILE.registerCommand("Header", function (options, content)
  local analogs = { "part", "chapter", "section", "subsection" }
  local analog = analogs[options.level+2] -- Pandoc's -1 level is \part
  options.level = nil
  local wrapper, args = handlePandocArgs(options)
  wrapper(function ()
    if analog and SILE.Commands[analog] then
      SILE.call(analog, args, content)
    else
      SILE.process(content)
    end
  end)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("HorizontalRule", function (_, _)
  SILE.call("center", {}, function ()
    SILE.call("raise", { height = "0.8ex" }, function ()
      SILE.call("hrule", { height = "0.5pt", width = "50%lw" })
      end)
    end)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("LineBlock", function (_, content)
  SILE.process(content)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("Null", function (_, _)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("OrderedList", function (options, content)
  -- TODO: handle listAttributes
  handlePandocArgs(options)(function ()
    SILE.settings.set("document.rskip","10pt")
    SILE.settings.set("document.lskip","20pt")
    SILE.process(content)
  end)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("Para", function (_, content)
  SILE.process(content)
  SILE.call("par")
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("Plain", function (_, content)
  SILE.process(content)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("RawBlock", function (options, content)
  local format = options.format
  -- TODO: execute as script? pass to different input parser?
  SILE.process(content)
  SILE.typesetter:leaveHmode()
end)

SILE.registerCommand("Table", function (options, content)
  -- TODO: options.caption
  -- TODO: options.align
  -- TODO: options.width
  -- TODO: options.headers
  SILE.process(content)
  SILE.typesetter:leaveHmode()
end)

-- Inlines

SILE.registerCommand("Cite", function (options, content)
  -- TODO: options is citation list?
end, "Creates a Cite inline element")

SILE.registerCommand("Code", function (options, content)
  local wrapper, args = handlePandocArgs(options)
  wrapper(function ()
    SILE.call("code", args, content)
  end)
end, "Creates a Code inline element")

SILE.registerCommand("Emph", function (_, content)
  SILE.call("em", {}, content)
end, "Creates an inline element representing emphasised text.")

SILE.registerCommand("Image", function (options, _)
  local wrapper, args = handlePandocArgs(options)
  wrapper(function ()
    SILE.call("img", args)
  end)
end, "Creates a Image inline element")

SILE.registerCommand("LineBreak", function (_, _)
  SILE.call("break")
end, "Create a LineBreak inline element")

SILE.registerCommand("Link", function (options, content)
  local wrapper, args = handlePandocArgs(options)
  wrapper(function ()
    SILE.call("url", args, content)
  end)
end, "Creates a link inline element, usually a hyperlink.")

SILE.registerCommand("Math", function (options, content)
  -- TODO options is math type
  SILE.process("content")
end, "Creates a Math element, either inline or displayed.")

SILE.registerCommand("Note", function (_, content)
  SILE.call("footnote", {}, content)
end, "Creates a Note inline element")

SILE.registerCommand("Quoted", function (options, content)
  -- TODO: options.type
  SILE.process(content)
end, "Creates a Quoted inline element given the quote type and quoted content.")

SILE.registerCommand("RawInline", function (options, content)
  local format = options.format
  -- TODO: execute as script? pass to different input parser?
  SILE.process(content)
end, "Creates a Quoted inline element given the quote type and quoted content.")

SILE.registerCommand("SmallCaps", function (_, content)
  SILE.call("font", { features = "+smcp" }, content)
end, "Creates text rendered in small caps")

SILE.registerCommand("Span", function (options, content)
  handlePandocArgs(options)(content)
end, "Creates a Span inline element")

SILE.registerCommand("Strikeout", function (_, content)
  -- TODO: cross it out, unicode munging?
  SILE.process(content)
end, "Creates text which is striked out.")

SILE.registerCommand("Strong", function (_, content)
  SILE.call("strong", {}, content)
end, "Creates a Strong element, whose text is usually displayed in a bold font.")

local scriptOffset = "0.7ex"
local scriptSize = "1.5ex"

SILE.registerCommand("Subscript", function (_, content)
  SILE.call("lower", { height = scriptOffset }, function ()
    SILE.call("font", { size = scriptSize }, content)
  end)
end, "Creates a Subscript inline element")

SILE.registerCommand("Superscript", function (_, content)
  SILE.call("raise", { height = scriptOffset }, function ()
    SILE.call("font", { size = scriptSize }, content)
  end)
end, "Creates a Superscript inline element")
-- -\define[command=listitem]{\smallskip{}\glue[width=-1em]• \glue[width=0.3em]\process\smallskip}%

-- Utility wrapper classes

SILE.registerCommand("class:csl-no-emph", function (_, content)
  SILE.call("font", { style = "Roman" }, content)
end,"Inline upright wrapper")

SILE.registerCommand("class:csl-no-strong", function (_, content)
  SILE.call("font", { weight = 400 }, content)
end,"Inline normal weight wrapper")

SILE.registerCommand("class:csl-no-smallcaps", function (_, content)
  SILE.call("font", { features = "-smcp" }, content)
end,"Inline smallcaps disable wrapper")

return { documentation = [[\begin{document}

Cover all the possible commands Pandoc's SILE export might throw at us.

\end{document}]] }
