-- You will need my lunamark fork from https://github.com/simoncozens/lunamark
-- for the AST writer.

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
  local opts = options or {}
  local AST = generic.new(opts)

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

  AST.genericCommand = function (name)
    return function (s)
      return createCommand (0, 0, 0, name, {}, s)
    end
  end

  AST.note = AST.genericCommand("footnote")
  AST.strong = AST.genericCommand("strong")
  AST.paragraph = AST.genericCommand("paragraph")
  AST.code = AST.genericCommand("code")
  AST.emphasis = AST.genericCommand("em")
  AST.blockquote = AST.genericCommand("blockquote")
  AST.verbatim = AST.genericCommand("em")
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
  AST.orderedlist = function (items, _, _) -- items, tight, startnum
    local node = {command = "enumerate"}
    for i= 1, #items do node[i] = AST.listitem(items[i]) end
    return node
  end
  AST.link = function(_, uri, _) -- label, uri, title
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
  AST.image = function(_, src, _) -- label, src, title
    if getFileExtension(src) == "svg" then
      return createCommand(0, 0, 0, "svg", { src = src })
    end
    return createCommand(0, 0, 0, "img", { src = src })
  end
  AST.hrule = AST.genericCommand("fullrule")

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
    local parse = reader.new(writer, { smart = true, notes = true, fenced_code_blocks = true })
    local t = parse(data)
    -- t = { [1] = t, id = "document", options = { class = "markdown" }}
    SILE.process(t[1])
  end
}

function markdown:_init (options)
  book._init(self, options)
  self:loadPackage("url")
  self:loadPackage("image")
  self:loadPackage("svg")
  self:loadPackage("rules")
  self:loadPackage("lists")
  return self
end

function markdown:registerCommands ()

  book.registerCommands(self)

  SILE.registerCommand("blockquote", function (_, content)
    SILE.process(content)
  end)

  SILE.registerCommand("paragraph", function (_, content)
    SILE.process(content)
    SILE.call("par")
  end)
end

return markdown
