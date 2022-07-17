-- (c) 2009-2011 John MacFarlane. Released under MIT license.
-- See the file LICENSE in the source for details.

--- Generic writer for lunamark.
-- This serves as generic documentation for lunamark writers,
-- which all export a table with the same functions defined.
--
-- New writers can simply modify the generic writer: for example,
--
--     local Xml = generic.new(options)
--
--     Xml.linebreak = "<linebreak />"
--
--     local escaped = {
--          ["<" ] = "&lt;",
--          [">" ] = "&gt;",
--          ["&" ] = "&amp;",
--          ["\"" ] = "&quot;",
--          ["'" ] = "&#39;"
--     }
--
--     function Xml.string(s)
--       return s:gsub(".",escaped)
--     end

local util = require("lunamark.util")
local M = {}
local W = {}

local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined writer function '%s'\n",key))
    return (function(...) return table.concat({...}," ") end)
  end
setmetatable(W, meta)

--- Returns a table with functions defining a generic lunamark writer,
-- which outputs plain text with no formatting.  `options` is an optional
-- table with the following fields:
--
-- `layout`
-- :   `minimize` (no space between blocks)
-- :   `compact` (no extra blank lines between blocks)
-- :   `default` (blank line between blocks)
function M.new(options)

--- The table contains the following fields:

  options = options or {}
  local metadata = {}

  --- Set metadata field `key` to `val`.
  function W.set_metadata(key, val)
    metadata[key] = val
    return ""
  end

  --- Add `val` to an array in metadata field `key`.
  function W.add_metadata(key, val)
    local cur = metadata[key]
    if type(cur) == "table" then
      table.insert(cur,val)
    elseif cur then
      metadata[key] = {cur, val}
    else
      metadata[key] = {val}
    end
  end

  --- Return metadata table.
  function W.get_metadata()
    return metadata
  end

  -- Turn list of output into final result.
  function W.merge(result)
    return util.rope_to_string(result)
  end

  --- A space (string).
  W.space = " "

  --- Setup tasks at beginning of document.
  function W.start_document()
    return ""
  end

  --- Finalization tasks at end of document.
  function W.stop_document()
    return ""
  end

  --- Plain text block (not formatted as a pragraph).
  function W.plain(s)
    return s
  end

  --- A line break (string).
  W.linebreak = "\n"

  --- Line breaks to use between block elements.
  W.interblocksep = "\n\n"

  --- Line breaks to use between a container (like a `<div>`
  -- tag) and the adjacent block element.
  W.containersep = "\n"

  if options.layout == "minimize" then
    W.interblocksep = ""
    W.containersep = ""
  elseif options.layout == "compact" then
    W.interblocksep = "\n"
    W.containersep = "\n"
  end

  --- Ellipsis (string).
  W.ellipsis = "…"

  --- Em dash (string).
  W.mdash = "—"

  --- En dash (string).
  W.ndash = "–"

  --- Non-breaking space.
  W.nbsp = " "

  --- String in curly single quotes.
  function W.singlequoted(s)
    return {"‘", s, "’"}
  end

  --- String in curly double quotes.
  function W.doublequoted(s)
    return {"“", s, "”"}
  end

  --- String, escaped as needed for the output format.
  function W.string(s)
    return s
  end

  --- Citation key, escaped as needed for the output format.
  function W.citation(s)
    return s
  end

  --- Inline (verbatim) code.
  function W.code(s)
    return s
  end

  --- A link with link text `label`, uri `uri`,
  -- and title `title`.
  function W.link(label, uri, title)
    return label
  end

  --- An image link with alt text `label`,
  -- source `src`, and title `title`.
  function W.image(label, src, title)
    return label
  end

  --- A paragraph.
  function W.paragraph(s)
    return s
  end

  --- A bullet list with contents `items` (an array).  If
  -- `tight` is true, returns a "tight" list (with
  -- minimal space between items).
  function W.bulletlist(items,tight)
    return util.intersperse(items,W.interblocksep)
  end

  --- An ordered list with contents `items` (an array). If
  -- `tight` is true, returns a "tight" list (with
  -- minimal space between items). If optional
  -- number `startnum` is present, use it as the
  -- number of the first list item.
  function W.orderedlist(items,tight,startnum)
    return util.intersperse(items,W.interblocksep)
  end

  --- Inline HTML.
  function W.inline_html(s)
    return ""
  end

  --- Display HTML (HTML block).
  function W.display_html(s)
    return ""
  end

  --- Emphasized text.
  function W.emphasis(s)
    return s
  end

  --- Strongly emphasized text.
  function W.strong(s)
    return s
  end

  --- Strikethrough text
  function W.strikethrough(s)
    return s
  end

  --- Block quotation.
  function W.blockquote(s)
    return s
  end

  --- Verbatim block.
  function W.verbatim(s)
    return s
  end

  --- Fenced code block, with infostring `i`.
  function W.fenced_code(s, i)
    return s
  end

  --- Header level `level`, with text `s`.
  function W.header(s, level)
    return s
  end

  --- Horizontal rule.
  W.hrule = ""

  --- A string of one or more citations. `text_cites` is a boolean, true if the
  -- citations are in-text citations. `cites` - is an array of tables, each of
  -- the form `{ prenote = q, name = n, postnote = e, suppress_author = s }`,
  -- where:
  -- - `q` is a nil or a rope that should be inserted before the citation,
  -- - `e` is a nil or a rope that should be inserted after the citation,
  -- - `n` is a string with the citation name, and
  -- - `s` is a boolean, true if the author should be omitted from the
  --   citation.
  function W.citations(text_cites, cites)
    local buffer = {}
    local opened_brackets = false
    for i, cite in ipairs(cites) do
      if i == 1 then -- Opening in-text citation
        if text_cites then
          buffer[#buffer + 1] = {cite.suppress_author and "-" or "", "@",
            cite.name}
          if cite.postnote then
            opened_brackets = true
            buffer[#buffer + 1] = {" [", cite.postnote}
          end
        else -- Opening regular citation
          opened_brackets = true
          buffer[#buffer + 1] = {"[", cite.prenote and {cite.prenote, " "} or "",
            cite.suppress_author and "-" or "", "@", cite.name, cite.postnote and
            {" ", cite.postnote}}
        end
      else -- Continuation citation
        buffer[#buffer + 1] = {"; ", cite.prenote and {cite.prenote, " "} or "",
          cite.suppress_author and "-" or "", "@", cite.name, cite.postnote and
          {" ", cite.postnote}}
      end
    end
    if opened_brackets then
      buffer[#buffer + 1] = "]"
    end
    return buffer
  end

  --- A footnote or endnote.
  function W.note(contents)
    return contents
  end

  --- A definition list. `items` is an array of tables,
  -- each of the form `{ term = t, definitions = defs, tight = tight }`,
  -- where `t` is a string and `defs` is an array of strings.
  -- `tight` is a boolean, true if it is a tight list.
  function W.definitionlist(items, tight)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = item.t
      buffer[#buffer + 1] = util.intersperse(item.definitions, W.interblocksep)
    end
    return util.intersperse(buffer,W.interblocksep)
  end

  --- A cosmo template to be used in producing a standalone document.
  -- `$body` is replaced with the document body, `$title` with the
  -- title, and so on.
  W.template = [[
$body
]]

  return util.table_copy(W)
end

return M
