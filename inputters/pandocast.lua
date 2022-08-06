--
-- Pandoc JSON AST native inputter for SILE
-- Focussed on Markdown needs (esp. table support)
--
-- AST conversion relies on the Pandoc types specification:
-- https://hackage.haskell.org/package/pandoc-types
--
-- Reusing the commands made for the "markdown" inputter/package.
--
local Pandoc = {
   API_VERSION = { 1, 22, 0 } -- Supported API version (semver)
}

local utils = require("packages.markdown.utils")

local function checkAstSemver(version)
  -- We shouldn't care the patch level.
  -- The Pandoc AST may change upon "minor" updates, though.
  local major, minor = table.unpack(version)
  local expected_major, expected_minor = table.unpack(Pandoc.API_VERSION)
  if not major or major ~= expected_major then
    SU.error("Unsupported Pandoc AST major version " .. major
      .. ", only version " .. expected_major.. " is supported")
  end
  if not minor or minor < expected_minor then
    SU.error("Unsupported Pandoc AST version " .. table.concat(version, ".")
      .. ", needing at least " ..  table.concat(Pandoc.API_VERSION, "."))
  end
  if minor ~= expected_minor then
    -- Warn and pray.
    -- IMPLEMENTATON NOTE: Kept simple for now.
    -- When this occurs, we may check to properly handle version updates
  SU.warn("Pandoc AST version " .. table.concat(version, ".")
    .. ", is more recent than supported " ..  table.concat(Pandoc.API_VERSION, ".")
    .. ", there could be issues.")
  end
end

-- Allows unpacking tables on some Pandoc AST nodes so as to map them to methods
-- with a simpler and friendly interface.
local HasMultipleArgs = {
  Cite = true,
  Code = true,
  CodeBlock = true,
  Div = true,
  Header = true,
  Image = true,
  Link = true,
  Math = true,
  Span = true,
  OrderedList = true,
  Quoted = true,
  RawInline = true,
  RawBlock = true,
  Table = true,
}

-- Parser AST-waling logic.

local function addNodes(out, elements)
  -- Simplify outputs by collating strings
  if type(elements) == "string" and type(out[#out]) == "string" then
    out[#out] = out[#out] .. elements
  else
    -- Simplify out by removing empty elements
    if type(elements) ~= "table" or elements.command or #elements > -1 then
      out [#out+1] = elements
    end
  end
end

local function pandocAstParse(element)
  local out
  if type(element) == 'string' then
    out = element
  end
  if type(element) == 'table' then
    out = {}
    if element.t then
      if Pandoc[element.t] then
        if HasMultipleArgs[element.t] then
          addNodes(out, Pandoc[element.t](table.unpack(element.c)))
        else
          addNodes(out, Pandoc[element.t](element.c))
        end
      else
        SU.warn("Unrecognized Pandoc AST element "..element.t)
      end
    end
    for _, b in ipairs(element) do
      addNodes(out, pandocAstParse(b))
    end
  end
  --  Simplify output by removing useless grouping
  if type(out) == "table" and #out == 1 and not out.command then
    out = out[1]
  end
  return out
end

-- PANDOC AST UTILITIES

-- type Attr = (Text, [Text], [(Text, Text)])
--   That is: identifier, classes, key-value pairs
--   We map it to something easier to manipulate, similar to what a Pandoc
--   Lua custom writer would expose, and which also looks like regular SILE
--   options.
local function pandocAttributes(attributes)
  local id, class, keyvals = table.unpack(attributes)
  local options = {
    id = id and id ~= "" and id or nil,
    class = table.concat(class, " "),
  }
  for _, keyval in ipairs(keyvals) do
    local key = keyval[1]
    local value = keyval[2]
    options[key] = value
  end
  return options
end

local function extractLineBlockLevel (inlines)
  -- The indentation of line blocks is not really a first-class citizen in
  -- the Pandoc AST: Pandoc replaces the indentation spaces with U+00A0
  -- and stacks them in the first "Str" Inline (adding it if necessary)
  -- We remove them, and return the count.
  local f = inlines[1]
  local level = 0
  if f and f.t == "Str" then
    local line = f.c
    line = line:gsub("^[ ]+", function (match) -- Warning, U+00A0 here.
      level = utf8.len(match)
      return ""
    end)
    f.c = line -- replace
  else
    -- Oops, that's not what we expected. Warn and try to proceed anyway.
    SU.warn("Unexpected structure in Pandoc AST LineBlock - please report the issue")
  end
  return level, inlines
end

local function extractTaskListBullet (blocks)
  -- Task lists are not really first-class citizens in the Pandoc AST. Pandoc
  -- replaces the Markdown [ ], [x] or [X] by Unicode ballot boxes, but leaves
  -- them as the first inline in the first block, as:
  --   Plain > Str > "☐" or "☒"
  -- We extract them for appropriate processing.
  local plain = blocks[1] and blocks[1].c -- Plain content
  local str = plain and plain[1] and plain[1].c -- Str content
  if (str == "☐" or str == "☒") then
    table.remove(blocks[1].c, 1)
    return str
  end
  -- return nil
end

-- PANDOC AST BLOCKS

-- Plain [Inline]
-- (not a paragraph)
Pandoc.Plain = function (inlines)
  return pandocAstParse(inlines)
end

-- Para [Inline]
Pandoc.Para = function (inlines)
  local content = pandocAstParse(inlines)
  return utils.createCommand("markdown:internal:paragraph", {}, content)
end

-- LineBlock [[Inline]]
Pandoc.LineBlock = function (lineblocks)
  local out = {}
  for _, inlines in ipairs(lineblocks) do
    local level, currated_inlines = extractLineBlockLevel(inlines)
    -- Let's be typographically sound and use quad kerns rather than spaces for indentation
    local contents =  (level > 0) and {
      utils.createCommand("kern", { width = level.."em" }),
      pandocAstParse(currated_inlines)
    } or pandocAstParse(currated_inlines)
    out[#out+1] = { utils.createCommand("markdown:internal:paragraph", {}, contents) }
  end
  return out
end

-- CodeBlock Attr Text
-- Code block (literal) with attributes
Pandoc.CodeBlock = function (_, text) -- (attributes, text)
  return utils.createCommand("verbatim", {}, text)
end

-- RawBlock Format Text
Pandoc.RawBlock = function (format, text)
  return utils.createCommand("markdown:internal:rawblock", { format = format }, text)
end

-- BlockQuote [Block]
Pandoc.BlockQuote = function (blocks)
  local content = pandocAstParse(blocks)
  return utils.createCommand("markdown:internal:blockquote", {}, content)
end

-- OrderedList ListAttributes [[Block]]
local pandocListNumberStyleTags = {
  -- DefaultStyle
  Example = "arabic",
  Decimal = "arabic",
  UpperRoman = "Roman",
  LowerRoman = "roman",
  UpperAlpha = "Alpha",
  LowerAlpha = "alpha",
}
local pandocListNumberDelimTags = {
  -- DefaultDelim
  OneParen = { after = ")" },
  Period = { after ="." },
  TwoParens = { before = "(", after = ")" }
}
Pandoc.OrderedList = function (listattrs, itemblocks)
  -- ListAttributes = (Int, ListNumberStyle, ListNumberDelim)
  --   Where ListNumberStyle, ListNumberDelim) are tags
  local start, style, delim = table.unpack(listattrs)
  local display = pandocListNumberStyleTags[style.t]
  local delimiters = pandocListNumberDelimTags[delim.t]
  local options = {
    start = start,
    display = display,
  }
  if delimiters then
    options.before = delimiters.before
    options.after= delimiters.after
  end

  local contents = {}
  for i = 1, #itemblocks do
    contents[i] = utils.createCommand("item", {}, pandocAstParse(itemblocks[i]))
  end
  return utils.createStructuredCommand("enumerate", options, contents)
end

-- BulletList [[Block]]
-- Bullet list (list of items, each a list of blocks)
Pandoc.BulletList = function (itemblocks)
  local contents = {}
  for i = 1, #itemblocks do
    local blocks = itemblocks[i]
    local options = { bullet = extractTaskListBullet(blocks) }
    contents[i] = utils.createCommand("item", options, pandocAstParse(blocks))
  end
  return utils.createStructuredCommand("itemize", {}, contents)
end

-- DefinitionList [([Inline], [[Block]])]
Pandoc.DefinitionList = function (items)
  local buffer = {}
  for _, item in ipairs(items) do
    local term = pandocAstParse(item[1])
    local definition = pandocAstParse(item[2])
    buffer[#buffer + 1] = utils.createCommand("markdown:internal:term", {}, term)
    buffer[#buffer + 1] = utils.createStructuredCommand("markdown:internal:definition", {}, definition)
  end
  return utils.createStructuredCommand("markdown:internal:paragraph", {}, buffer)
end

-- Header Int Attr [Inline]
Pandoc.Header = function (level, attributes, inlines)
  local options = pandocAttributes(attributes)
  local content = pandocAstParse(inlines)
  options.level = level
  return utils.createCommand("markdown:internal:header", options, content)
end

-- HorizontalRule
-- Horizontal rule
Pandoc.HorizontalRule = function ()
  return utils.createCommand("fullrule")
end

-- Div Attr [Block]
-- Generic block container with attributes
Pandoc.Div = function (attributes, blocks)
  local options = pandocAttributes(attributes)
  local content = pandocAstParse(blocks)
  return utils.createCommand("markdown:internal:div" , options, content)
end

local pandocAlignmentTags = {
  AlignDefault = "default",
  AlignLeft = "left",
  AlignRight = "right",
  AlignCenter = "center",
}

-- Cell Attr Alignment RowSpan:Int ColSpan:Int [Block]
local function pandocCell (cell, colalign)
  local _, align, rowspan, colspan, blocks = table.unpack(cell)
  if rowspan ~= 1 then
    -- Not doable without pain, ptable has cell splitting but no row spanning.
    -- We'd have to handle this very differently.
    SU.error("Pandoc AST tables with row spanning cells are not supported yet")
  end
  local cellalign = pandocAlignmentTags[align.t]
  local halign = cellalign ~= "default" and cellalign or colalign
  return utils.createCommand("cell", { valign="middle", halign = halign, span = colspan }, pandocAstParse(blocks))
end

-- Row Attr [Cell]
local function pandocRow (row, colaligns, options)
  local cells = row[2]
  local cols = {}
  for i, cell in ipairs(cells) do
    local col = pandocCell(cell, colaligns[i])
    cols[#cols+1] = col
  end
  return utils.createStructuredCommand("row", options or {}, cols)
end

-- Table Attr Caption [ColSpec] TableHead [TableBody] TableFoot
Pandoc.Table = function (_, caption, colspecs, thead, tbodies, tfoot)
  -- CAVEAT: This goes far beyond what Markdown needs (quite logically, Pandoc
  -- supporting  other formats) and can be hard to map to SILE's ptable package.
  local aligns = {}
  for _, colspec in ipairs(colspecs) do
    -- ColSpec Alignment ColWidth
    -- For now ignore the weird colwidth...
    aligns[#aligns+1] = pandocAlignmentTags[colspec[1].t]
  end
  local numberOfCols = #colspecs
  local ptableRows = {}

  -- TableHead Attr [Row]
  local hasHeader = false
  for _, row in ipairs(thead[2]) do
    hasHeader = true
    ptableRows[#ptableRows+1] = pandocRow(row, aligns, { background = "#eee"})
  end

  -- TableBody Attr RowHeadColumns [Row] [Row]
  --   with an "intermediate" head row... (we skip this!)
  --   RowHeadColumns Int
  for _, tbody in ipairs(tbodies) do
    if tbody[2] ~= 0 then SU.error("Pandoc AST tables with several head columns are not sup ported") end
    for _, row in ipairs(tbody[4]) do
      ptableRows[#ptableRows+1] = pandocRow(row, aligns)
    end
  end

  -- TableFoot Attr [Row]
  for _, row in ipairs(tfoot[2]) do
    ptableRows[#ptableRows+1] = pandocRow(row, aligns)
  end

  local cWidth = {}
  for i = 1, numberOfCols do
    cWidth[i] = string.format("%.0f%%lw", 100 / numberOfCols)
  end
  local ptable = utils.createStructuredCommand("ptable", {
    cols = table.concat(cWidth, " "),
    header = hasHeader,
  }, ptableRows)

  -- Caption (Maybe ShortCaption) [Block]
  if not caption or #caption[#caption] == 0 then
    -- No block or empty block = no caption...
    return ptable
  end
  local captioned = {
    ptable,
    utils.createCommand("caption", {}, pandocAstParse(caption[#caption]))
  }
  return utils.createStructuredCommand("markdown:internal:captioned-table", {}, captioned)
end

-- PANDOC AST INLINES

-- Str Text
Pandoc.Str = function (text)
  return text
end

-- Emph [Inline]
Pandoc.Emph =  function (inlines)
  local content = pandocAstParse(inlines)
  return utils.createCommand("em", {}, content)
end
-- Underline [Inline]
Pandoc.Underline = function (inlines)
  local content = pandocAstParse(inlines)
  return utils.createCommand("underline", {}, content)
end

-- Strong [Inline]
Pandoc.Strong = function (inlines)
  local content = pandocAstParse(inlines)
  return utils.createCommand("strong", {}, content)
end

-- Strikeout [Inline]
Pandoc.Strikeout = function (inlines)
  local content = pandocAstParse(inlines)
  return utils.createCommand("strikethrough", {}, content)
end

-- Superscript [Inline]
Pandoc.Superscript = function (inlines)
  local content = pandocAstParse(inlines)
  return utils.createCommand("textsuperscript", {}, content)
end

-- Subscript [Inline]
Pandoc.Subscript = function (inlines)
  local content = pandocAstParse(inlines)
  return utils.createCommand("textsubscript", {}, content)
end

-- SmallCaps [Inline]
Pandoc.SmallCaps = function (inlines)
  local content = pandocAstParse(inlines)
  return utils.createCommand("font", { features = "+smcp" }, content)
end

-- Quoted QuoteType [Inline]
--   Where QuoteType is a tag DoubleQuote or SingleQuote
Pandoc.Quoted = function (quotetype, inlines)
  if quotetype.t == "DoubleQuote" then
    return pandocAstParse({ "“", inlines, "”" })
  end
  return pandocAstParse({ "‘", inlines, "’" })
end

-- Cite [Citation] [Inline]
--   Where a Citation is a dictionary
Pandoc.Cite = function (_, inlines)
  -- TODO
  -- We could possibly do better.
  -- Just render the inlines and ignore the citations
  return pandocAstParse(inlines)
end

-- Code Attr Text
Pandoc.Code = function (attributes, text)
  local options = pandocAttributes(attributes)
  return utils.createCommand("code", options, text)
end

-- Space
Pandoc.Space = function ()
  return " "
end

-- SoftBreak
Pandoc.SoftBreak = function ()
  return " " -- Yup.
end

-- LineBreak
-- Hard line break
Pandoc.LineBreak = function ()
  return utils.createCommand("cr")
end

-- Math MathType Text
-- TeX math (literal)
Pandoc.Math = function (_, text)
  return text
end

-- RawInline Format Text
Pandoc.RawInline = function (format, text)
  return utils.createCommand("markdown:internal:rawinline", { format = format}, text)
end

-- Link Attr [Inline] Target
Pandoc.Link = function (_, inlines, target) -- attributes, inlines, target
  -- We don't use the attributes?
  -- Target = (Url : Text, Title : Text)
  local uri, _ = table.unpack(target) -- uri, title (unused too?)
  local content = pandocAstParse(inlines)
  return utils.createCommand("markdown:internal:link", { src = uri }, content)
end

-- Image Attr [Inline] Target
Pandoc.Image = function (attributes, inlines, target) -- attributes, inlines, target
  local options = pandocAttributes(attributes)
  local content = pandocAstParse(inlines)
  -- Target = (Url : Text, Title : Text)
  local uri, _ = table.unpack(target)
  options.src = uri
  return utils.createCommand("markdown:internal:image", options, content)
end

-- Note [Block]
Pandoc.Note = function (blocks)
  local content = pandocAstParse(blocks)
  return utils.createCommand("markdown:internal:footnote", {}, content)
end

-- Span Attr [Inline]
Pandoc.Span = function (attributes, inlines)
  local options = pandocAttributes(attributes)
  local content = pandocAstParse(inlines)
  return utils.createCommand("markdown:internal:span" , options, content)
end

local base = require("inputters.base")

local inputter = pl.class(base)
inputter._name = "pandocast"
inputter.order = 2

function inputter.appropriate (_, filename, _)
  return filename:match("pandoc$")
end

function inputter.parse (_, doc)
  local has_json, json = pcall(require, "json.decode")
  if not has_json then
    SU.error("The pandocast inputter requires LuaJSON's json.decode() to be available.")
  end

  local ast = json.decode(doc)

  local PANDOC_API_VERSION = ast['pandoc-api-version']
  checkAstSemver(PANDOC_API_VERSION)

  local tree = pandocAstParse(ast.blocks)

  -- The Markdown parsing returns a SILE AST.
  -- Wrap it in a document structure so we can just process it, and if at
  -- root level, load a default support class.
  tree = { { tree, command = "document", options = { class = "markdown" } } }
  return tree
end

return inputter
