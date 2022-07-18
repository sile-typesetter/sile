local book = require("classes.book")
local markdown = pl.class(book)
markdown._name = "markdown"

-- A few SILE AST  utilities

local function createCommand(command, options, content)
  -- content = a simple content
  -- So that's basically the same logic as the "inputfilter" package'S
  -- createComment, with the col, line, pos dropped as we don't get them
  -- from lunamark's AST.
  local result = { content }
  result.col = 0
  result.line = 0
  result.pos = 0
  result.options = options
  result.command = command
  result.id = "command"
  return result
end

local function createStructuredCommand(command, options, contents)
  -- contents = a table of an already prepared content list.
  local result = contents
  result.col = 0
  result.line = 0
  result.pos = 0
  result.options = options
  result.command = command
  result.id = "command"
  return result
end

-- Some other utility functions

local function getFileExtension (fname)
  -- extract file name and then extension
  return fname:match("[^/]+$"):match("[^.]+$")
end

-- A few mappings functions and tables

local sections = { "chapter", "section", "subsection" }

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

local function tableCellAlign (align)
  if align == 'l' then
    return 'left'
  elseif align == 'r' then
    return 'right'
  elseif align == 'c' then
    return 'center'
  else
    return 'default'
  end
end

-- Lunamark writer for SILE = lunamark's AST to SILE's AST, yay!

local function lunamarkAST2SILE (options)
  local generic = require("lunamark.writer.generic")
  local writer = generic.new(options or {})

  function writer.merge (result)
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

  writer.simpleCommand = function (name)
    return function (s)
      return createCommand (name, {}, s)
    end
  end

  writer.note = writer.simpleCommand("footnote")
  writer.strong = writer.simpleCommand("strong")
  writer.paragraph = writer.simpleCommand("paragraph")
  writer.code = writer.simpleCommand("code")
  writer.emphasis = writer.simpleCommand("em")
  writer.strikethrough = writer.simpleCommand("strikethrough")
  writer.subscript = writer.simpleCommand("textsubscript")
  writer.superscript = writer.simpleCommand("textsuperscript")
  writer.blockquote = writer.simpleCommand("blockquote")
  writer.verbatim = writer.simpleCommand("verbatim")
  writer.listitem = writer.simpleCommand("item")
  writer.hrule = writer.simpleCommand("fullrule")

  writer.header = function (s, level)
    if level <= #sections then
      return createCommand(sections[level], {}, s)
    end
    return createCommand("paragraph", {}, s)
  end

  writer.bulletlist = function (items)
    local contents = {}
    for i = 1, #items do contents[i] = writer.listitem(items[i]) end
    return createStructuredCommand("itemize", {}, contents)
  end

  writer.tasklist = function (items)
    local contents = {}
    for i = 1, #items do
      local bullet = (items[i][1] == "[X]") and "☑" or "☐"
      contents[i] = createCommand("item", { bullet = bullet }, items[i][2])
     end
    return createStructuredCommand("itemize", {}, contents)
  end

  writer.orderedlist = function (items, _, startnum, numstyle, numdelim) -- items, tight, ...
    local display = numstyle and listStyle[numstyle]
    local after = numdelim and listDelim[numdelim]
    local contents = {}
    for i= 1, #items do contents[i] = writer.listitem(items[i]) end
    return createStructuredCommand("enumerate", { start = startnum or 1, display = display, after = after }, contents)
  end

  writer.link = function (_, uri, _) -- label, uri, title
    if uri:sub(1,1) == "#" then
      -- local hask link
      local dest = uri:sub(2)
      return createCommand("pdf:link", { dest = "ref:"..dest }, { dest }) -- FIXME later
                                                                          -- We need cross-refs (e.g. labelrefs)
    end
    return createCommand("href", { src = uri }, { uri })
  end

  writer.image = function (_, src, _, attr) -- label, src, title, attr
    local opts = attr or {}-- passthru (classes and key-value pairs)
    opts.src = src
    if getFileExtension(src) == "svg" then
      return createCommand("svg", opts)
    end
    return createCommand("img", opts)
  end

  writer.span = function (content, attr)
    local out = content
    if attr["lang"] then
       out = createCommand("language", { main = attr["lang"] }, out)
    end
    if attr.class and string.match(' ' .. attr.class .. ' ',' smallcaps ') then
      out = createCommand("font", { features = "+smcp" }, out)
    end
    if attr.class and string.match(' ' .. attr.class .. ' ',' underline ') then
      out = createCommand("underline", {}, out)
    end
    if attr["custom-style"] then
      out = createCommand("markdown:custom-style:hook", { name = attr["custom-style"], scope="inline" }, out)
    end
    return out
  end

  writer.div = function (content, attr)
    local out = content
    if attr["lang"] then
      out = createCommand("language", { main = attr["lang"] }, out)
    end
    if attr["custom-style"] then
      out = createCommand("markdown:custom-style:hook", { name = attr["custom-style"], scope="block" }, out)
    end
    return out
  end

  writer.fenced_code = function(s, _, _) -- s, infostring, attr
    return createCommand("verbatim", {}, s)
  end

  writer.rawinline = function (content, format, _) -- content, format, attr
    if format == "sile" then
      return createCommand("markdown:internal:rawcontent", {}, content)
    elseif format == "sile-lua" then
      return createCommand("script", {}, content)
    end
    return "" -- ignore unknown
  end

  writer.rawblock = function (content, format, attr)
    return writer.rawinline(content, format, attr)
  end

  writer.table = function (rows, caption) -- rows, caption
    -- caption is a text Str
    -- rows[1] has the headers
    -- rows[2] has the alignments (I know, it's weird...)
    -- then other rows follow
    local aligns = rows[2]
    local numberOfCols = #aligns
    local ptableRows = {}

    local headerCols = {}
    for j, column in ipairs(rows[1]) do
      local col = createStructuredCommand("cell", { valign="middle", halign = tableCellAlign(aligns[j]) }, column)
      headerCols[#headerCols+1] = col
    end
    ptableRows[#ptableRows+1] = createStructuredCommand("row", { background = "#eee" }, headerCols)

    for i = 3, #rows do
      local row = rows[i]
      local ptableCols = {}
      for j, column in ipairs(row) do
        local col = createStructuredCommand("cell", { valign = "middle", halign = tableCellAlign(aligns[j]) }, column)
        ptableCols[#ptableCols+1] = col
      end
      ptableRows[#ptableRows+1] = createStructuredCommand("row", {}, ptableCols)
    end

    local cWidth = {}
    for i = 1, numberOfCols do
      cWidth[i] = string.format("%.0f%%lw", 100 / numberOfCols)
    end
    local ptable = createStructuredCommand("ptable", { cols = table.concat(cWidth, " ") }, ptableRows)

    if not caption then
      return ptable
    end

    local captioned = { ptable, createCommand("caption", {}, caption) }
    return createStructuredCommand("table", {}, captioned)
  end

  return writer
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
  self:loadPackage("ptable")
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

  -- BEGIN Quick and dirty rip-off from omibook without the cool styling...
  local extractFromTree = function (tree, command)
    for i=1, #tree do
      if type(tree[i]) == "table" and tree[i].command == command then
        return table.remove(tree, i)
      end
    end
  end

  SILE.registerCommand("table", function (_, content)
    if type(content) ~= "table" then SU.error("Expected a table content in table environment") end
    local caption = extractFromTree(content, "caption")

    SILE.process(content)
    if caption then
      SILE.call("font", { size = SILE.settings:get("font.size") * 0.95}, function ()
        SILE.call("center", {}, caption)
      end)
    end
    SILE.call("smallskip")
  end, "Insert a captioned table.")
  -- END Quick and dirty rip-off from omibook...
end

return markdown
