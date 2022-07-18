local book = require("classes.book")
local markdown = pl.class(book)
markdown._name = "markdown"

local createCommand = require("packages.inputfilter").exports.createCommand

local function getFileExtension (fname)
  -- extract file name and then extension
  return fname:match("[^/]+$"):match("[^.]+$")
end
local sections = {"chapter", "section", "subsection" }

local function lunamarkAST2SILE (options)
  local generic = require("lunamark.writer.generic")
  local AST = generic.new(options or {})

  function AST.merge (result)
    local function walk(t)
      local out = {}
      for i = 1, #t do
        local typ = type(t[i])
        if typ == "string" and #t[i] > 0 then
          if type(out[#out]) == "string" then
            out[#out] = out[#out] .. t[i]
          else
            out[#out+1] = t[i]
          end
        elseif typ == "table" then
          local node = walk(t[i])
          for key, value in pairs(t[i]) do
            if type(key)=="string" then
               node[key] = value
            end
          end
          out[#out+1] = node
        elseif typ == "function" then
          out[#out+1] = t[i]() -- walk(t[i]()) ?
        end
      end
      return out
    end
    return walk(result)
  end

  AST.genericCommand = function (name, opts)
    return function (s)
      return createCommand (0, 0, 0, name, opts or {}, s)
    end
  end

  AST.note = AST.genericCommand("footnote")
  AST.strong = AST.genericCommand("strong")
  AST.paragraph = AST.genericCommand("paragraph")
  AST.code = AST.genericCommand("code")
  AST.emphasis = AST.genericCommand("em")
  AST.strikethrough = AST.genericCommand("strikethrough")
  AST.subscript = AST.genericCommand("textsubscript")
  AST.superscript = AST.genericCommand("textsuperscript")
  AST.blockquote = AST.genericCommand("blockquote")
  AST.verbatim = AST.genericCommand("verbatim")
  AST.header = function (s, level)
    if level <= #sections then
      return createCommand(0, 0, 0, sections[level], {}, s)
    end
    return createCommand(0, 0, 0, "paragraph", {}, s)
  end
  AST.listitem = AST.genericCommand("item")
  AST.bulletlist = function (items)
    local node = {command = "itemize"}
    for i = 1, #items do node[i] = AST.listitem(items[i]) end
    return node
  end
  AST.tasklist = function (items)
    local node = {command = "itemize"}
    for i = 1, #items do
      local bullet = (items[i][1] == "[X]") and "☑" or "☐"
      node[i] = createCommand(0, 0, 0, "item", { bullet = bullet }, items[i][2])
     end
    return node
  end
  AST.orderedlist = function (items, _, startnum, numstyle, numdelim) -- items, tight, ...
    local listStyle = {
      Decimal = "arabic",
      UpperRoman = "Roman",
      LowerRoman = "roman",
      UpperAlpha = "Alpha",
      LowerAlpha = "alpha",
    }
    local listDelim = {
      OneParen = ")",
      Period = ".",
    }
    local display = numstyle and listStyle[numstyle]
    local after = numdelim and listDelim[numdelim]
    local node = {command = "enumerate", options = { start = startnum, display = display, after = after }}
    for i= 1, #items do node[i] = AST.listitem(items[i]) end
    return node
  end
  AST.link = function (_, uri, _) -- label, uri, title
    if uri:sub(1,1) == "#" then
      -- local hask link
      local dest = uri:sub(2)
      return createCommand(0, 0, 0, "pdf:link", { dest = "ref:"..dest }, { dest }) -- FIXME later
                                                                                   -- We need cross-refs (e.g. labelrefs)
    end
    -- TODO
    -- If the URL is not external but a local file, what are we supposed to do?
    return createCommand(0, 0, 0, "href", { src = uri }, { uri })
  end
  AST.image = function (_, src, _, attr) -- label, src, title, attr
    local opts = attr or {}-- passthru (classes and key-value pairs)
    opts.src = src
    if getFileExtension(src) == "svg" then
      return createCommand(0, 0, 0, "svg", opts)
    end
    return createCommand(0, 0, 0, "img", opts)
  end
  AST.hrule = AST.genericCommand("fullrule")
  AST.span = function (content, attr)
    local out = content
    if attr["lang"] then
       out = createCommand(0, 0, 0, "language", { main = attr["lang"] }, out)
    end
    if attr.class and string.match(' ' .. attr.class .. ' ',' smallcaps ') then
      out = createCommand(0, 0, 0, "font", { features = "+smcp" }, out)
    end
    if attr.class and string.match(' ' .. attr.class .. ' ',' underline ') then
      out = createCommand(0, 0, 0, "underline", {}, out)
    end
    if attr["custom-style"] then
      out = createCommand(0, 0, 0, "markdown:custom-style:hook", { name = attr["custom-style"], scope="inline" }, out)
    end
    return out
  end
  AST.div = function (content, attr)
    local out = content
    if attr["lang"] then
      out = createCommand(0, 0, 0, "language", { main = attr["lang"] }, out)
    end
    if attr["custom-style"] then
      out = createCommand(0, 0, 0, "markdown:custom-style:hook", { name = attr["custom-style"], scope="block" }, out)
    end
    return out
  end

  AST.fenced_code = function(s, _, _) -- s, infostring, attr
    return createCommand(0, 0, 0, "verbatim", {}, s)
  end
  AST.rawinline = function (content, format, _) -- content, format, attr
    if format == "sile" then
      return createCommand(0, 0, 0, "markdown:internal:rawcontent", {}, content)
    elseif format == "sile-lua" then
      return createCommand(0, 0, 0, "script", {}, content)
    end
    return "" -- ignore unknown
  end
  AST.rawblock = function (content, format, attr)
    return AST.rawinline(content, format, attr)
  end
  AST.table = function (rows, _) -- rows, caption
    -- FIXME THIS WILL ALSO NEED A BACKPORT PORT (from wikito/lunamark
    -- (I prepared it, but we have to check the license terms...)
    --   caption is a text Str
    --   rows[1] has the headers
    --   rows[2] has the alignments (wow...)
    --   other rows follow
    for i, row in ipairs(rows) do
      -- print("  Row ", i)
      for j, column in ipairs(row) do
        -- print("   Col", j, column)
      end
    end
    return "FIXME LATER WITH PTABLE SUPPORT"
  end

  return AST
end

SILE.inputs.markdown = {
  order = 2,
  appropriate = function (fn, _)
    return fn:match("md$") or fn:match("markdown$")
  end,
  process = function (data)
    local lunamark = require("lunamark")
    local reader = lunamark.reader.markdown
    local writer = lunamarkAST2SILE()
    local parse = reader.new(writer, {
      smart = true,
      notes = true,
      fenced_code_blocks = true,
      pandoc_extensions = true,
      startnum = true,
      fancy_lists = true,
      task_list = true,
      hash_enumerators = true,
      table_captions = true,
      pipe_table = true,
    })
    local t = parse(data)
    t = { [1] = t, id = "document", options = { class = "markdown" }} -- Is this needed?
    SILE.process(t)
  end
}

function markdown:_init (options)
  book._init(self, options)
  self:loadPackage("url")
  self:loadPackage("image")
  self:loadPackage("svg")
  self:loadPackage("rules")
  self:loadPackage("lists")
  -- self:loadPackage("textsubsuper") -- FIXME later, for now provide fallbacks below...
  return self
end

function markdown:registerCommands ()

  book.registerCommands(self)

  SILE.registerCommand("blockquote", function (_, content)
    -- Quick and dirty blockquote
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
  end)

  SILE.registerCommand("paragraph", function (_, content)
    SILE.process(content)
    SILE.call("par")
  end)

  SILE.registerCommand("markdown:internal:rawcontent", function (_, content)
    SILE.doTexlike(content[1])
  end)

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
    end
  end)

  -- BEGIN Quick and dirty super/subscript rip-off
  -- Extracted from proposed textsubsuper package and trimmed down.
  local function getItalicAngle ()
    local ot = require("core.opentype-parser")
    local fontoptions = SILE.font.loadDefaults({})
    local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
    local font = ot.parseFont(face)
    return font.post.italicAngle
  end

  local function getWeightClass ()
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
    SILE.call("kern", { width = xOffset:absolute() + SILE.measurement("0.1pt") })
    SILE.call("raise", { height = yOffset }, function ()
      -- Some font have +onum enabled by default...
      -- Some don't even have it (e.g. Brill), but support +lnum for enforcing lining
      -- figures. We try to ensure we are not using oldstyle numbers...
      SILE.call("font", {
        size = ySize,
        weight = weight == 400 and (weight + 200) or weight,
        features = "+lnum -onum",
      }, content)
    end)
    SILE.call("kern", { width = -xOffset / 2 })
  end, "Typeset a fake (raised, scaled) superscript content.")

  SILE.registerCommand("textsubscript", function (_, content)
    SILE.require("packages/raiselower")
    local italicAngle = getItalicAngle()
    local weight = getWeightClass()

    local ratio = 0.66
    local ySize = ratio * SILE.settings:get("font.size")
    local yOffset = SILE.measurement("0.25ex")
    local xOffset = -math.sin(italicAngle * math.pi / 180) * yOffset:absolute()
    SILE.call("kern", { width = -xOffset })
    SILE.call("lower", { height = yOffset }, function ()
      SILE.call("font", {
        size = ySize,
        weight = weight == 400 and (weight + 200) or weight,
        features = "+lnum +onum",
      }, content)
    end)
    SILE.call("kern", { width = xOffset })
  end, "Typeset a fake (lowered, scaled) subscript content.")
  -- END Quick and dirty super/subscript rip-off
end

return markdown
