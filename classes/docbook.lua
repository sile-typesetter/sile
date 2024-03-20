local plain = require("classes.plain")

local class = pl.class(plain)
class._name = "docbook"

SILE.scratch.docbook = {
  seclevel = 0,
  seccount = {}
}

-- BEGIN UTILITIES

-- TAKEN FROM RESILIENT XUTILS (v2.1-draft)
local function getFileExtension (fname)
  return fname:match("[^/]+$"):match("[^.]+$")
end

-- String trimming
local trimLeft = function (str)
  return str:gsub("^%s*", "")
end
local trimRight = function (str)
  return str:gsub("%s*$", "")
end

-- Content tree trimming: remove leading and trailing spaces, but from
-- a content tree i.e. possibly containing several elements.
local function trimContent (content)
  -- Remove leading and trailing spaces
  if #content == 0 then return end
  if type(content[1]) == "string" then
    content[1] = trimLeft(content[1])
    if content[1] == "" then table.remove(content, 1) end
  end
  if type(content[#content]) == "string" then
    content[#content] = trimRight(content[#content])
    if content[#content] == "" then table.remove(content, #content) end
  end
  return content
end

local function extractFromTree (tree, command)
  for i = 1, #tree do
    if type(tree[i]) == "table" and tree[i].command == command then
      return table.remove(tree, i)
    end
  end
end

-- Walk through content nodes as a "structure":
-- Text nodes are ignored (= usually just spaces, due to XML indentation)
-- Command nodes are enriched with their position, so we can later refer
-- to it (as with an XPath pos()).
local function walkAsStructure(content)
  local iElem = 0
  local nElem = 0
  for i = 1, #content do
    if type(content[i]) == "table" then
      nElem = nElem + 1
    end
  end
  for i = 1, #content do
    if type(content[i]) == "table" then
      iElem = iElem + 1
      content[i].options._pos_  = iElem
      content[i].options._last_ = iElem == nElem
      SILE.process({ content[i] })
    end
    -- All text nodes in ignored in structure tags.
  end
end

local function contentAsStructure(content)
  local structure = {}
  for i = 1, #content do
    if type(content[i]) == "table" then
      structure[#structure+1] = content[i]
    end
    -- All text nodes in ignored in structure tags.
  end
  return structure
end

-- TAKEN FROM OMIKHLEIA'S MARKDOWN.SILE UTILS 1.2.x

-- @tparam  string command name of the command
-- @tparam  table  options command options
-- @tparam  table  content content tree
-- @treturn table  SILE AST command
local function createCommand (command, options, content)
  local result = { content }
  result.col = 0
  result.lno = 0
  result.pos = 0
  result.options = options or {}
  result.command = command
  result.id = "command"
  return result
end

--- Create a command from a structured content tree.
-- The content is normally a table of an already prepared content list.
--
-- @tparam  string command name of the command
-- @tparam  table  options command options
-- @tparam  table  contents content tree list
-- @treturn table  SILE AST command
local function createStructuredCommand (command, options, contents)
  -- contents = normally a table of an already prepared content list.
  local result = type(contents) == "table" and contents or { contents }
  result.col = 0
  result.lno = 0
  result.pos = 0
  result.options = options or {}
  result.command = command
  result.id = "command"
  return result
end
-- END UTILITIES

function class:_init (options)
  plain._init(self, options)
  self:loadPackage("image")
  self:loadPackage("simpletable", {
      tableTag = "tgroup",
      trTag = "row",
      tdTag = "entry"
    })
  self:loadPackage("rules")
  self:loadPackage("verbatim")
  self:loadPackage("lists")
  self:loadPackage("footnotes")

  self.originalFootnote = SILE.Commands["footnote"] -- DOH WE NEED A WAY TO NAMESPACE THE XML!
  self:registerCommand("footnote", function (_, content) -- DIRTY OVERRIDE
    self.originalFootnote({}, contentAsStructure(content))
  end)

  self:loadPackage("tableofcontents")
   -- 3rd-party labelrefs (+ must come after tableofcontents)
  local ok
  ok = pcall(function () return self:loadPackage("labelrefs") end)
  if not ok then
    SU.error("DocBook needs the labelrefs.sile 3rd-party collection")
  end
  -- 3rd-party textsubsuper
  ok = pcall(function () return self:loadPackage("textsubsuper") end)
  if not ok then
    SU.error("DocBook needs the textsubsuper.sile 3rd-party collection")
  end

  self:loadPackage("url")
  self:loadPackage("svg")

  SILE.call("font", { family="Libertinus Serif" }) -- HACK TEMPORARY

  -- SILE sensibly does not define a pixels unit because it has no meaning in its frame of reference. However the
  -- Docbook standard requires them and even defaults to them for bare numbers, even while warning against their use.
  -- Here we define a px arbitrarily to be the equivalent point unit if output was 300 DPI.
  SILE.units.px = {
    definition = "0.24pt"
  }
end

function class.push (t, val)
  if not SILE.scratch.docbook[t] then SILE.scratch.docbook[t] = {} end
  local q = SILE.scratch.docbook[t]
  q[#q+1] = val
end

function class.pop (t)
  local q = SILE.scratch.docbook[t]
  q[#q] = nil
end

function class.val (t)
  local q = SILE.scratch.docbook[t]
  return q[#q]
end

function class.wipe (tbl)
  while((#tbl) > 0) do tbl[#tbl] = nil end
end

class.registerCommands = function (self)

  plain.registerCommands(self)
  self:registerCommand("abbrev", function (_, content)
    SILE.call("font", { variant = "smallcaps" }, content)
  end)

  self:registerCommand("abstract", function (_, content) SILE.process(content) end) -- TODO
  self:registerCommand("accel", function (_, content) SILE.process(content) end) -- TODO
  self:registerCommand("acknowledgements", function (_, content) SILE.process(content) end) -- TODO
  self:registerCommand("acronym", function (_, content) SILE.process(content) end) -- TODO
  self:registerCommand("address", function (_, content) SILE.process(content) end) -- TODO

  self:registerCommand("affiliation", function (_, content) SILE.process(content) end) -- TODO

  self:registerCommand("alt", function (_, _)
    -- It is not usually rendered where it occurs, rather it is used to annotate some other aspect
    -- of the presentation.
    -- SKIPPED
  end)

  self:registerCommand("anchor", function (options)
    -- It is only useful as a target.
    local id = options["xml:id"]
    if id then
      SILE.call("label", { marker = id })
    end
  end)

  self:registerCommand("annotation", function (_, content) SILE.process(content) end) -- TODO
  self:registerCommand("answer", function (_, content) SILE.process(content) end) -- TODO

  self:registerCommand("appendix", function (options, content) -- TODO PARTIAL
    SILE.call("section", options, content)
  end)

  self:registerCommand("application", function (_, content)
    SILE.call("em", {}, content)
  end)

  self:registerCommand("arc", function (_, _) end) -- IGNORE (arc: will be removed in DocBook V6.0.)
  self:registerCommand("area", function (_, _) end) -- IGNORE
  self:registerCommand("areaset", function (_, _) end) -- IGNORE ("suppressed")
  self:registerCommand("areaspec", function (_, _) end) -- IGNORE ("suppressed")

  self:registerCommand("arg", function (_, content) SILE.process(content) end)

  self:registerCommand("article", function (_, content) -- TODO PARTIAL
    local info = extractFromTree(content, "info") or extractFromTree(content, "articleinfo")
    local title = extractFromTree(content, "title") or (info and extractFromTree(info, "title"))
    local _ = extractFromTree(content, "titleabbrev") or (info and extractFromTree(info, "titleabbrev"))

    local author = extractFromTree(content, "author") or (info and extractFromTree(info, "author"))

    if title then
      SILE.call("docbook-article-title", {}, title)
    end
    if author then
      SILE.call("docbook-main-author", {}, function ()
        for _, t in ipairs(author) do
          if type(t) == "table" then
            SILE.call(t.command, {}, t)
            SILE.typesetter:leaveHmode()
            SILE.call("bigskip")
          end
        end
      end)
    end
    walkAsStructure(content)
    SILE.typesetter:chuck()
  end)

  self:registerCommand("artpagenums", function (_, _) end) -- IGNORE ("sometimes suppressed")

  -- attribution: identifies the source to whom a blockquote or epigraph is ascribed.
  -- = should be extracted there.

  self:registerCommand("audiodata", function (_, _) end) -- IGNORE
  self:registerCommand("audioobject", function (_, _) end) -- IGNORE

  self:registerCommand("author", function (_, content) SILE.process(content) end) -- PARTIAL

  self:registerCommand("author", function (_, _) end) -- TODO PARTIAL, depends on context...

  self:registerCommand("authorgroup", function (_, content) SILE.process(content) end) -- TODO wrapper

  self:registerCommand("authorinitials", function (_, _) end) -- IGNORE ("sometimes suppressed")


  for _, tag in ipairs({ -- TODO
    "bibliocoverage", "bibliodiv", "biblioentry", "bibliography", "biblioid",
    "bibliolist", "bibliomisc", "bibliomixed", "bibliomset", "biblioref",
    "bibliorelation", "biblioset", "bibliosource"
  }) do
    self:registerCommand(tag, function (_, content)
      SILE.process(content)
    end)
  end

  self:registerCommand("blockquote", function (_, content)
    local info = extractFromTree(content, "info")
    local title = extractFromTree(content, "title") or (info and extractFromTree(info, "title"))
    local _ = extractFromTree(content, "titleabbrev") or (info and extractFromTree(info, "titleabbrev"))
    if title then
      SU.warn("DocBook title in blockquote is currently ignored")
    end
    local attribution = extractFromTree(content, "attribution")
    if attribution then
      SU.warn("DocBook attribution in blockquote is currently ignored")
    end

    SILE.call("smallskip")
    SILE.settings:temporarily(function ()
      local indent = SILE.measurement("2em"):absolute()
      local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
      local rskip = SILE.settings:get("document.rskip") or SILE.nodefactory.glue()
      SILE.settings:set("document.lskip",
        SILE.nodefactory.glue(lskip.width.length + indent))
      SILE.settings:set("document.rskip",
        SILE.nodefactory.glue(rskip.width.length + indent))
      walkAsStructure(content)
      SILE.typesetter:leaveHmode() -- gather paragraphs now.
    end)
    SILE.call("smallskip")
  end, "A naive blockquote environment")

  self:registerCommand("book", function (_, content) SILE.process(content) end) -- TODO BAD FIXME

  self:registerCommand("bridgehead", function (_, _) end) -- TODO IGNORE

  -- TODO FIXME STILL LOTS OF TAGS MISSING...

  self:registerCommand("emphasis", function (options, content)
    -- Formatted inline.
    -- Emphasized text is traditionally presented in italics or boldface.
    -- A role attribute of bold or strong is often used to generate boldface, if italics is the default presentation.
    -- N.B. Other roles below taken from what Pandoc generates from a Markdown input.
    if options.role == "bold" or options.role == "strong" then
      SILE.call("strong", {}, content)
    elseif options.role == "underline" then
      SILE.call("underline", {}, content)
    elseif options.role == "strikethrough" then
      SILE.call("strikethrough", {}, content)
    elseif options.role == "smallcaps" then
      SILE.call("font", { features = "+smcp" }, content)
    else
      SILE.call("em", {}, content)
    end
  end)

  self:registerCommand("firstterm", function (_, content) SILE.process(content) end) -- Partial

  self:registerCommand("foreignphrase", function (_, content)
    -- A foreignphrase is often given special typographic treatment, such as italics.
    SILE.call("em", {}, content)
  end)

  self:registerCommand("note", function (_, content) SILE.process(content) end)
  self:registerCommand("colspec", function (_, content) SILE.process(content) end)
  self:registerCommand("phrase", function (_, content) SILE.process(content) end)
  self:registerCommand("literal", function (_, content)
    SILE.call("code", {}, content)
  end)
  self:registerCommand("parameter", function (_, content)
    SILE.call("code", {}, content)
  end)
  self:registerCommand("important", function (_, content)
    local info = extractFromTree(content, "info") or extractFromTree(content, "articleinfo")
    local title = extractFromTree(content, "title") or (info and extractFromTree(info, "title"))
    local _ = extractFromTree(content, "titleabbrev") or (info and extractFromTree(info, "titleabbrev"))
    if title then
      SU.warn("DocBook title in important is currently ignored")
    end
    walkAsStructure(content)
  end)

  self:registerCommand("procedure", function (_, content)
    walkAsStructure(content)
  end)
  self:registerCommand("step", function (_, content)
    walkAsStructure(content)
  end)
  self:registerCommand("screen", function (_, content) SILE.process(content) end)
  self:registerCommand("command", function (_, content) SILE.process(content) end)
  self:registerCommand("option", function (_, content) SILE.process(content) end)
  self:registerCommand("package", function (_, content) SILE.process(content) end)
  self:registerCommand("tip", function (_, content) SILE.process(content) end)
  self:registerCommand("varname", function (_, content) SILE.process(content) end)
  self:registerCommand("qandaset", function (_, content) SILE.process(content) end)
  self:registerCommand("qandadiv", function (_, content) SILE.process(content) end)
  self:registerCommand("qandaentry", function (_, content) SILE.process(content) end)
  self:registerCommand("question", function (_, content) SILE.process(content) end)

  self:registerCommand("subscript", function (_, content)
    SILE.call("textsubscript", {}, content)
  end)
  self:registerCommand("superscript", function (_, content)
    SILE.call("textsuperscript", {}, content)
  end)

  self:registerCommand("inlinemediaobject", function (_, content)
    walkAsStructure(content)
  end)
  self:registerCommand("objectinfo", function (_, _) end)

  self:registerCommand("docbook-line", function (_, _)
    SILE.call("medskip")
    SILE.call("hrule", { height = "0.5pt", width = "50mm" })
    SILE.call("medskip")
  end)

  self:registerCommand("docbook-sectionsfont", function (_, content)
    SILE.call("font", { family = "DejaVu Sans", style = "Condensed", weight = 800 }, content)
  end)

  self:registerCommand("docbook-ttfont", function (_, content)
    SILE.call("code", {}, content)
  end)

  self:registerCommand("docbook-article-title", function (_, content)
    SILE.call("center", {}, function ()
      SILE.call("docbook-sectionsfont", {}, function ()
        SILE.call("font", { size = "20pt" }, content)
      end)
    end)
    SILE.call("bigskip")
  end)

  self:registerCommand("docbook-section-title", function (_, content)
    SILE.call("noindent")
    SILE.call("bigskip")
    SILE.call("docbook-sectionsfont", {}, {content})
    SILE.call("bigskip")
  end)

  self:registerCommand("docbook-main-author", function (_, content)
    SILE.call("center", {}, function()
      SILE.call("docbook-sectionsfont", {}, content)
    end)
    SILE.call("bigskip")
  end)

  self:registerCommand("docbook-section-1-title", function (_, content)
    SILE.call("font", { size = "16pt" }, function()
      SILE.call("docbook-section-title", {}, content)
    end)
  end)

  self:registerCommand("docbook-section-2-title", function (_, content)
    SILE.call("font", { size = "12pt" }, function()
      SILE.call("docbook-section-title", {}, content)
    end)
  end)

  self:registerCommand("docbook-titling", function (_, content)
    SILE.call("noindent")
    SILE.call("docbook-sectionsfont", {}, content)
  end)
  self:registerCommand("docbook-section-3-title", function (_, content)
    SILE.process(content)
    SILE.call("par")
  end)

  self:registerCommand("para", function (_, content)
    SILE.process(trimContent(content))
    SILE.call("par")
  end)

  self:registerCommand("replaceable", function (_, content)
    SILE.call("em", {}, content)
  end)

  self:registerCommand("title", function (_, content)
    SU.error("title")
    SILE.call("em", {}, content)
  end)

  self:registerCommand("personname", function (_, content)
    SILE.process(content)
  end)
  for _, tag in ipairs({
    "firstname", "surname", "othername", "honorific", "lineage"
  }) do
    self:registerCommand(tag, function (_, content)
      SILE.process(content)
    end)
  end

  self:registerCommand("email", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("uri", function (_, content)
    SILE.call("code", {}, content)
  end)

  self:registerCommand("personblurb", function (_, content)
    SILE.call("font", { size = "2ex" }, content)
  end)

  self:registerCommand("jobtitle", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("orgname", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("menuchoice", function (_, content)
    SILE.typesetter:typeset("“")
    SILE.process(content)
    SILE.typesetter:typeset("”")
  end)

  self:registerCommand("programlisting", function (_, content)
    SILE.call("verbatim", {}, content)
  end)

  self:registerCommand("tag", function (_, content)
    SILE.call("docbook-ttfont", {}, function ()
      SILE.typesetter:typeset("<")
      SILE.process(content)
      SILE.typesetter:typeset(">")
    end)
  end)

  self:registerCommand("filename", function (_, content)
    SILE.call("docbook-ttfont", {}, content)
  end)

  self:registerCommand("guimenu", function (_, content)
    SILE.call("docbook-ttfont", {}, content)
  end)

  self:registerCommand("guimenuitem", function (_, content)
    SILE.typesetter:typeset(" > ")
    SILE.call("docbook-ttfont", {}, content)
  end)

  self:registerCommand("guilabel", function (_, content)
    SILE.call("docbook-ttfont", {}, content)
  end)

  self:registerCommand("guibutton", function (_, content)
    SILE.call("docbook-ttfont", {}, content)
  end)

  self:registerCommand("computeroutput", function (_, content)
    SILE.call("docbook-ttfont", {}, content)
  end)

  self:registerCommand("xref", function (options, _)
    if options.endterm then
      SILE.call("ref", { marker = options.endterm, type = "title" })
    elseif options.linkend then
      SILE.call("ref", { marker = options.linkend, type = options.role })
    else
      SU.warn("DocBook xref without endterm or linkend is not supported yet")
      SILE.call("strong", {}, { "‹broken›" })
    end
  end)

  self:registerCommand("citetitle", function (_, content)
    SILE.call("em", {}, content)
  end)

  self:registerCommand("quote", function (_, content)
    SILE.typesetter:typeset("“")
    SILE.process(content)
    SILE.typesetter:typeset("”")
  end)

  self:registerCommand("citation", function (_, content)
    SILE.typesetter:typeset("[")
    SILE.process(content)
    SILE.typesetter:typeset("]")
  end)

  self:registerCommand("thead", function (_, content)
    SILE.call("font", { weight = 800 }, content)
  end)

  self:registerCommand("tbody", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("mediaobject", function (_, content)
    local _ = extractFromTree(content, "info")
    walkAsStructure(content)
  end)

  self:registerCommand("imageobject", function (_, content)
    local _ = extractFromTree(content, "info")
    walkAsStructure(content)
  end)

  self:registerCommand("bibliography", function (_, content)
    SILE.call("font", { size = "16pt" }, function ()
      SILE.call("docbook-section-title", { "Bibliography" })
    end)
    SILE.call("par")
    SILE.call("font", { size = "2ex" }, content)
  end)

  self:registerCommand("bibliomixed", function (_, content)
    SILE.process(content)
    SILE.call("smallskip")
  end)

  self:registerCommand("bibliomisc", function (_, content)
    SILE.process(content)
  end)

  -- DOH WE NEED A WAY TO NAMESPACE THE XML!
  -- Avoid breaking info nodes...
  --self:registerCommand("info", function () end)

  self:registerCommand("section", function (options, content)
    SILE.scratch.docbook.seclevel = SILE.scratch.docbook.seclevel + 1
    SILE.scratch.docbook.seccount[SILE.scratch.docbook.seclevel] = (SILE.scratch.docbook.seccount[SILE.scratch.docbook.seclevel] or 0) + 1
    while #(SILE.scratch.docbook.seccount) > SILE.scratch.docbook.seclevel do
      SILE.scratch.docbook.seccount[#(SILE.scratch.docbook.seccount)] = nil
    end

    local id = options["xml:id"]
    local title = extractFromTree(content, "title")
    local number = table.concat(SILE.scratch.docbook.seccount, '.')
    if title then
      SILE.call("docbook-section-"..SILE.scratch.docbook.seclevel.."-title", {}, function ()
        SILE.typesetter:typeset(number.." ")
        SILE.call("tocentry", { level = SILE.scratch.docbook.seclevel, number = number, bookmark = true }, SU.subContent(title))
        if id then SILE.call("label", { marker = id }) end
        local titleid = title.options and title.options["xml:id"]
        if titleid then SILE.call("label", { marker = titleid }) end
        SILE.process(title)
      end)
    elseif id then SILE.call("label", { marker = id }) end

    walkAsStructure(content)
    SILE.scratch.docbook.seclevel = SILE.scratch.docbook.seclevel - 1
  end)

  local function countedThing(thing, _, content)
    SILE.call("increment-counter", {id=thing})
    SILE.call("bigskip")
    SILE.call("docbook-line")
    SILE.call("docbook-titling", {}, function ()
      SILE.typesetter:typeset(thing.." ".. self.packages.counters:formatCounter(SILE.scratch.counters[thing]))
      local t = extractFromTree(content, "title")
      if t then
        SILE.typesetter:typeset(": ")
        SILE.process(t)
      end
    end)
    SILE.call("smallskip")
    SILE.process(content)
    SILE.call("docbook-line")
    SILE.call("bigskip")
  end

  self:registerCommand("example", function (options, content)
    countedThing("Example", options, content)
  end)
  self:registerCommand("informaltable", function (options, content)
    countedThing("Table", options, content)
  end)
  self:registerCommand("table", function (options, content)
    countedThing("Table", options, content)
  end)
  self:registerCommand("figure", function (options, content)
    countedThing("Figure", options, content)
  end)

  local function docmook_measurement (value)
    value = value:gsub("(%d)$", "%1px") -- bare numbers are pixels, not points
    value = value:gsub("(%%)$", "%1lw") -- percentages are relative to viewport
    return SU.cast("measurement", value)
  end

  self:registerCommand("imagedata", function (options, _)
    local width = options.width and docmook_measurement(options.width)
    local depth = options.depth and docmook_measurement(options.depth)

    local ext = getFileExtension(options.fileref)
    if ext == "svg" then
      SILE.call("svg", { src = options.fileref, width = width, height = depth })
    else
      SILE.call("img", { src = options.fileref, width = width, height = depth })
    end
  end)

  self:registerCommand("itemizedlist", function (_, content)
    local info = extractFromTree(content, "info")
    local title = extractFromTree(content, "title") or (info and extractFromTree(info, "title"))
    local _ = extractFromTree(content, "titleabbrev") or (info and extractFromTree(info, "titleabbrev"))
    if title then
      SU.warn("DocBook title in itemizedlist is currently ignored")
    end

    local items = {}
    for _, node in ipairs(content) do
      if type(node) == "table" then
        if node.command == "listitem" then
          items[#items+1] = createCommand("item", {} , contentAsStructure(node))
        else
          SU.warn("DocBook " .. node.command .. " in itemizedlist is currently ignored")
        end
      end
      -- Structure: ignore (normally empty) text nodes
    end
    local list = createStructuredCommand("itemize", {}, items)
    SILE.process({ list })
  end)

  self:registerCommand("orderedlist", function (_, content)
    local info = extractFromTree(content, "info")
    local title = extractFromTree(content, "title") or (info and extractFromTree(info, "title"))
    local _ = extractFromTree(content, "titleabbrev") or (info and extractFromTree(info, "titleabbrev"))
    if title then
      SU.warn("DocBook title in orderedlist is currently ignored")
    end

    local items = {}
    for _, node in ipairs(content) do
      if type(node) == "table" then
        if node.command == "listitem" then
          items[#items+1] = createCommand("item", {} , contentAsStructure(node))
        else
          SU.warn("DocBook " .. node.command .. " in itemizedlist is currently ignored")
        end
      end
      -- Structure: ignore (normally empty) text nodes
    end
    local list = createStructuredCommand("enumerate", {}, items)
    SILE.process({ list })
  end)

  self:registerCommand("listitem", function (_, _)
    return SU.warn("DocBook listitem in outer space")
  end)

  self:registerCommand("variablelist", function (_, content)
    local info = extractFromTree(content, "info")
    local title = extractFromTree(content, "title") or (info and extractFromTree(info, "title"))
    local _ = extractFromTree(content, "titleabbrev") or (info and extractFromTree(info, "titleabbrev"))
    if title then
      SU.warn("DocBook title in variablelist is currently ignored")
    end
    walkAsStructure(content)
  end)

  self:registerCommand("varlistentry", function (_, content)
    local item
    -- terms
    for _, node in ipairs(content) do
      if node.command == "term" then
        SILE.call("font", { weight = 600 }, node)
        SILE.call("par")
      elseif node.command == "listitem" then
        item = node
      end
    end
    -- item
    if item then
      SILE.settings:temporarily(function ()
        local indent = SILE.measurement("2em"):absolute()
        local lskip = SILE.settings:get("document.lskip") or SILE.nodefactory.glue()
        SILE.settings:set("document.lskip", SILE.nodefactory.glue(lskip.width + indent))
        walkAsStructure(item)
        SILE.typesetter:leaveHmode()
      end)
    end
    SILE.call("smallskip")
  end)
  self:registerCommand("term", function (_, content) SILE.process(content) end)

  self:registerCommand("link", function (options, content)
    local uri = options["xlink:href"]
    if uri then
      SILE.call("href", { src = uri }, content)
    elseif options.linkend then
      -- HACK. We use the target of a `\label`, knowing it is internally
      -- prefixed by "ref:" in the labelrefs package.
      -- That's not very nice to rely on internals...
      SILE.call("pdf:link", { dest = "ref:" .. options.linkend }, content)
    else
      SU.warn("A link shall have either a linkend attribute or an xlink:href attribute")
      SILE.process(content)
    end
  end)

  self:registerCommand("literallayout", function (_, content) SILE.process(content) end) -- TODO INCORRECT
  self:registerCommand("textobject", function (_, _) end) -- TODO INCORRECT

end

return class
