--
-- Common commands for Markdown support SILE, when there is no
-- direct mapping to an existing command or package.
--
-- Split in a standalone package so that it can be reused and
-- generalized somewhat independently from the undelying parsing code.
--
local utils = require("packages.markdown.utils")

-- A small utility class that allows wrapping commands applied to a
-- content, avoiding a callback hell with conditionals where it is
-- used and providing a sequence-oriented presentation.
local CommandCascade = pl.class({
  wrapper = nil,
  call = function (self, command, options)
    local inner = self.wrapper
    if inner then
      self.wrapper = function (content)
        SILE.call(command, options, function ()
          inner(content)
        end)
      end
    else
      self.wrapper = function (content)
        SILE.call(command, options, content)
      end
    end
  end,
  process = function (self, content)
    if not self.wrapper then
      SILE.process(content)
    else
      self.wrapper(content)
    end
  end,
})

local UsualSectioning = { "chapter", "section", "subsection", "subsubsection" }
local function getSectioningCommand (level)
  if level <= #UsualSectioning then
    -- Check we actually have those commands (e.g. some classes might not
    -- have subsubsections.)
    if SILE.Commands[UsualSectioning[level]] then
      return UsualSectioning[level]
    end
    SU.warn("Unknown command \\"..UsualSectioning[level].." (fallback to a default generic header)")
    -- Default to something anyway.
    return "markdown:fallback:header"
  end
  -- Also default to something anyway, but different message
  SU.warn("No support found for heading level "..level.." (fallback to a default generic header)")
  return "markdown:fallback:header"
end

local extractFromTree = function (tree, command)
  for i = 1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return table.remove(tree, i)
    end
  end
end

local function hasClass(options, classname)
  -- N.B. want a true boolean here
  if options.class and string.match(' ' .. options.class .. ' ',' '..classname..' ') then
    return true
  end
  return false
end

local function init (class, _)
  -- Only load low-level packages (= utilities)
  -- The claas should be responsible for loading the appropriate higher-level
  -- constructs, see fallback commands further below for more details.
  class:loadPackage("color")
  class:loadPackage("image")
  class:loadPackage("lists")
  class:loadPackage("ptable")
  class:loadPackage("rules")
  class:loadPackage("svg")
  -- class:loadPackage("textsubsuper") -- FIXME later, for now provide fallbacks below...
  class:loadPackage("url")
end

local function registerCommands (class)

  -- Commands (normally) intended to be used by this package only.

  SILE.registerCommand("markdown:internal:paragraph", function (_, content)
    SILE.process(content)
    -- See comment on the lunamark writer layout option. With the default layout,
    -- this\par was not necessary... We switched to "compact" layout, to decide
    -- how to handle our own paragraphing.
    SILE.call("par")
  end, "Paragraphing in Markdown (internal)")

  -- Mappings functions and tables

  SILE.registerCommand("markdown:internal:header", function (options, content)
    local level = SU.required(options, "level", "header")
    local command = getSectioningCommand(level)
    local numbering = not hasClass(options, "unnumbered")
    SILE.call(command, { numbering = numbering }, content)
    if options.id then
      -- HACK.
      -- Somewhat messy. If done before the sectioning, it could end on the
      -- previous page. Within its content, it breaks as TOC entries want
      -- a table content, so we can't use a function above...
      -- We are left with doing it after, but that's not perfect either vs.
      -- page breaks and indent/noindent...
      -- In my omibook class, I added a marker option to sections and
      -- reimplemented that part, but here we work with what we have.
      SILE.call("pdf:destination", { name = options.id })
    end
  end, "Header in Markdown (internal")

  SILE.registerCommand("markdown:internal:term", function (_, content)
    SILE.typesetter:leaveHmode()
    SILE.call("font", { weight = 600 }, content)
  end, "Definition list term in Markdown (internal)")

  SILE.registerCommand("markdown:internal:definition", function (_, content)
    SILE.typesetter:leaveHmode()
    SILE.settings:temporarily(function ()
      local indent = SILE.measurement("2em"):absolute()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.lskip", SILE.nodefactory.glue(lskip.width + indent))
      SILE.process(content)
      SILE.typesetter:leaveHmode()
    end)
    SILE.call("smallskip")
  end, "Definition list block in Markdown (internal")

  SILE.registerCommand("markdown:internal:div", function (options, content)
    local cascade = CommandCascade()
    if options.lang then
      cascade:call("language", { main = utils.normalizeLang(options.lang) })
    end
    if options["custom-style"] then
      -- The style (or the hook) is reponsible for paragraphing
      cascade:call("markdown:custom-style:hook", { name = options["custom-style"], scope="block" })
    else
      cascade:call("markdown:internal:paragraph")
    end
    cascade:process(content)
  end, "Div in Markdown (internal")

  SILE.registerCommand("markdown:internal:span", function (options, content)
    local cascade = CommandCascade()
    if options.lang then
      cascade:call("language", { main = utils.normalizeLang(options.lang) })
    end
    if hasClass(options, "smallcaps") then
      cascade:call("font", { features = "+smcp" })
    end
    if hasClass(options, "underline") then
      cascade:call("underline")
    end
    if options["custom-style"] then
      -- The style (or the hook) is reponsible for paragraphing
      cascade:call("markdown:custom-style:hook", { name = options["custom-style"], scope="inline" })
    end
    cascade:process(content)
  end, "Span in Markdown (internal")

  SILE.registerCommand("markdown:internal:image", function (options, _)
    local uri = SU.required(options, "src", "image")
    if utils.getFileExtension(uri) == "svg" then
      SILE.call("svg", options)
    else
      SILE.call("img", options)
    end
  end, "Image in Markdown (internal")

  SILE.registerCommand("markdown:internal:link", function (options, content)
    local uri = SU.required(options, "src", "link")
    if uri:sub(1,1) == "#" then
      -- local hask link
      local dest = uri:sub(2)
      SILE.call("pdf:link", { dest = dest }, content)
    else
      return SILE.call("href", { src = uri }, content)
    end
  end, "Link in Markdown (internal")

  SILE.registerCommand("markdown:internal:footnote", function (_, content)
    if not SILE.Commands["footnote"] then
      -- The reasons for NOT loading a package for this high-level structure
      -- is that the class or other packages may provide their own implementation
      -- (e.g. formatted differently, changed to endnotes, etc.).
      -- So we only do it as a fallback if mising, to degrade gracefully.
      SU.warn("Trying to enforce fallback for unavailable \\footnote command")
      class:loadPackage("footnotes")
    end
    SILE.call("footnote", {}, content)
  end, "Footnote in Markdown (internal")

  SILE.registerCommand("markdown:internal:rawinline", function (options, content)
    local format = SU.required(options, "format", "rawcontent")
    if format == "sile" then
      SILE.doTexlike(content[1])
    elseif format == "sile-lua" then
      SILE.call("script", {}, content)
    end
  end, "Raw native inline content in Markdown (internal")

  SILE.registerCommand("markdown:internal:rawblock", function (options, content)
    local format = SU.required(options, "format", "rawcontent")
    if format == "sile" or format == "sile-lua" then
      SILE.call("markdown:internal:paragraph", {}, function ()
        SILE.call("markdown:internal:rawinline", options, content)
      end)
    end
  end, "Raw native block in Markdown (internal")

  SILE.registerCommand("markdown:internal:blockquote", function (_, content)
    -- Would be nice NOT having to do this, but SILE's plain class only has a "quote"
    -- environment that doesn't really nest, and hard-codes all its values, skips, etc.
    -- So we might have a better version provided by a user-class or package.
    -- Otherwise, use our own fallback (with hard-coded choices too, but a least
    -- it does some proper nesting)
    if not SILE.Commands["blockquote"] then
      SILE.call("markdown:fallback:blockquote", {}, content)
    else
      SILE.call("blockquote", {}, content)
    end
  end, "Block quote in Markdown (internal")

  -- Fallback commands

  SILE.registerCommand("markdown:fallback:blockquote", function (_, content)
    SILE.call("smallskip")
    SILE.typesetter:leaveHmode()
    SILE.settings:temporarily(function ()
      local indent = SILE.measurement("2em"):absolute()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      local rskip = SILE.settings:get("document.rskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.lskip", SILE.nodefactory.glue(lskip.width + indent))
      SILE.settings:set("document.rskip", SILE.nodefactory.glue(rskip.width + indent))
      SILE.settings:set("font.size", SILE.settings:get("font.size") * 0.95)
      SILE.process(content)
      SILE.typesetter:leaveHmode()
    end)
    SILE.call("smallskip")
  end, "A fallback blockquote environment if 'blockquote' does not exist")

  SILE.registerCommand("markdown:fallback:header", function (_, content)
    SILE.typesetter:leaveHmode(1)
    SILE.call("goodbreak")
    SILE.call("smallskip")
    SILE.call("noindent")
    SILE.call("font", { weight = 700 }, content)
    SILE.call("novbreak")
    SILE.call("par")
    SILE.call("novbreak")
  end, "A fallback default header if none exists for the requested sectioning label")

  SILE.registerCommand("markdown:fallback:captioned-table", function (_, content)
    if type(content) ~= "table" then
      SU.error("Expected a table content in table environment")
    end
    local caption = extractFromTree(content, "caption")

    SILE.process(content)
    if caption then
      SILE.call("font", {
        size = SILE.settings:get("font.size") * 0.95
      }, function ()
        SILE.call("center", {}, caption)
      end)
    end
    SILE.call("smallskip")
  end, "A fallback command for Markdown to insert a captioned table")

  -- Customizable hooks

  SILE.registerCommand("markdown:custom-style:hook", function (options, content)
    -- Default implementation for the custom-style hook:
    -- If there is a corresponding command, we invoke it, otherwise, we just
    -- ignore the style and process the content. It allows us, e.g. to already
    -- use some interesting features, such as "custom-style=raggedleft".
    -- Package or class designers MAY override this hook to support any other
    -- styling mechanism they may have or want.
    -- The available options are the custom-style "name" and a "scope" which
    -- can be "inline" (for inline character-level styling) or "block" (for
    -- block paragraph-level styling).
    local name = SU.required(options, "name", "markdown custom style hook")
    if SILE.Commands[name] then
      SILE.call(name, {}, content)
    else
      SILE.process(content)
      if options.scope == "block" then
        SILE.call("par")
      end
    end
  end, "Default hook for custom style support in Markdown")

  -- Temporary stuff (expectedly....)

  -- BEGIN Quick and dirty super/subscript rip-off
  -- Extracted from proposed textsubsuper package and trimmed down.
  local function getItalicAngle()
    local ot = require("core.opentype-parser")
    local fontoptions = SILE.font.loadDefaults({})
    local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
    local font = ot.parseFont(face)
    return font.post.italicAngle
  end

  local function getWeightClass()
    return SILE.settings:get("font.weight")
  end

  SILE.registerCommand("textsuperscript", function (_, content)
    SILE.require("packages/raiselower")
    local italicAngle = getItalicAngle()
    local weight = getWeightClass()

    local ratio = 0.66
    local ySize = ratio * SILE.settings:get("font.size")
    local yOffset = SILE.measurement("0.70ex")
    local xOffset = -math.sin(italicAngle * math.pi / 180) * yOffset
    SILE.call("kern", {
      width = xOffset:absolute() + SILE.measurement("0.1pt")
    })
    SILE.call("raise", {
      height = yOffset
    }, function ()
      -- Some font have +onum enabled by default...
      -- Some don't even have it (e.g. Brill), but support +lnum for enforcing lining
      -- figures. We try to ensure we are not using oldstyle numbers...
      SILE.call("font", {
        size = ySize,
        weight = weight == 400 and (weight + 200) or weight,
        features = "+lnum -onum"
      }, content)
    end)
    SILE.call("kern", {
      width = -xOffset / 2
    })
  end, "Typeset a fake (raised, scaled) superscript content.")

  SILE.registerCommand("textsubscript", function (_, content)
    SILE.require("packages/raiselower")
    local italicAngle = getItalicAngle()
    local weight = getWeightClass()

    local ratio = 0.66
    local ySize = ratio * SILE.settings:get("font.size")
    local yOffset = SILE.measurement("0.25ex")
    local xOffset = -math.sin(italicAngle * math.pi / 180) * yOffset:absolute()
    SILE.call("kern", {
      width = -xOffset
    })
    SILE.call("lower", {
      height = yOffset
    }, function ()
      SILE.call("font", {
        size = ySize,
        weight = weight == 400 and (weight + 200) or weight,
        features = "+lnum +onum"
      }, content)
    end)
    SILE.call("kern", {
      width = xOffset
    })
  end, "Typeset a fake (lowered, scaled) subscript content.")
  -- END Quick and dirty super/subscript rip-off
end

return {
  init = init,
  registerCommands = registerCommands,
  documentation = [[\begin{document}
A base package for Markdown processing, providing hooks and fallback commands.

It is not intended to be used alone.
\end{document}]]
}
