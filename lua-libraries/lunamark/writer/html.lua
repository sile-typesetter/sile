-- (c) 2009-2011 John MacFarlane. Released under MIT license.
-- See the file LICENSE in the source for details.

--- HTML writer for lunamark.
-- Extends [lunamark.writer.xml].

local M = {}

local xml = require("lunamark.writer.xml")
local util = require("lunamark.util")
local flatten, intersperse, map = util.flatten, util.intersperse, util.map

--- Return a new HTML writer.
-- For a list of all fields in the writer, see [lunamark.writer.generic].
--
--`options` is a table that can contain the following fields:
--
-- `containers`
-- :   Put sections in `<div>` tags.
--
-- `slides`
-- :   Do not allow containers to nest; when a subsection begins,
--     close the section's container and start a new one.
--
-- `layout`
-- :   `minimize` removes semantically insignificant white space.
-- :   `compact` removes unneeded blank lines.
-- :   `default` puts blank lines between block elements.
function M.new(options)
  options = options or {}
  local Html = xml.new(options)

  local endnotes = {}
  local containersep = Html.containersep
  local interblocksep = Html.interblocksep

  Html.container = "div"
  Html.linebreak = "<br/>"
  Html.nbsp = "&nbsp;"

  function Html.code(s)
    return {"<code>", Html.string(s), "</code>"}
  end

  function Html.link(lab,src,tit)
    local titattr
    if type(tit) == "string" and #tit > 0
       then titattr = " title=\"" .. Html.string(tit) .. "\""
       else titattr = ""
       end
    return {"<a href=\"", Html.string(src), "\"", titattr, ">", lab, "</a>"}
  end

  function Html.image(lab,src,tit,attr)
    local titattr
    if type(tit) == "string" and #tit > 0
       then titattr = " title=\"" .. Html.string(tit) .. "\""
       else titattr = ""
    end
    local w = attr and attr.width and ' width="'..attr.width..'"'
    local h = attr and attr.height and ' height="'..attr.height..'"'
    return {"<img src=\"", Html.string(src), "\" alt=\"", lab, "\"", titattr, w, h, " />"}
  end

  function Html.paragraph(s)
    return {"<p>", s, "</p>"}
  end

  local function listitem(s)
    return {"<li>", s, "</li>"}
  end

  function Html.bulletlist(items)
    return {"<ul>", containersep, intersperse(map(items, listitem), containersep), containersep, "</ul>"}
  end

  local listStyle = {
    -- Decimal = "1", -- That's the default
    UpperRoman = "I",
    LowerRoman = "i",
    UpperAlpha = "A",
    LowerAlpha = "a",
  }
  function Html.orderedlist(items,_,startnum,numstyle,numdelim)
    local start = ""
    if startnum and startnum ~= 1 then
      start = " start=\"" .. startnum .. "\""
    end
    local oltype = numstyle and listStyle[numstyle]
    local oltypeattr = oltype and (' type="'..oltype..'"') or ""
    local olmark = numdelim == "OneParen" and ' class="custom-marker-oneparen"' or ""
    return {
        "<ol", start, oltypeattr, olmark, ">",
        containersep, intersperse(map(items, listitem), containersep), containersep,
        "</ol>"
    }
  end

  local function tasklistitem(s)
    local status = (s[1] == "[X]") and "checked" or "unchecked"
    local icon = (status == "checked") and "☑" or "☐"
    return {'<li class="tasklist-item '..status..'"><span>'..icon..' </span>', s[2], "</li>"}
  end

  function Html.tasklist(items)
    return {"<ul>", containersep, intersperse(map(items, tasklistitem), containersep), containersep, "</ul>"}
  end

  function Html.inline_html(s)
    return s
  end

  function Html.display_html(s)
    return s
  end

  function Html.emphasis(s)
    return {"<em>", s, "</em>"}
  end

  function Html.strong(s)
    return {"<strong>", s, "</strong>"}
  end

  function Html.strikeout(s)
    return {"<strike>", s, "</strike>"}
  end

  function Html.subscript(s)
    return {"<sub>", s, "</sub>"}
  end

  function Html.superscript(s)
    return {"<sup>", s, "</sup>"}
  end

  function Html.span(s, attr)
    local class = attr.class and attr.class ~="" and ' class="'..attr.class..'"' or ""
    local id = attr.id and ' id="'..attr.id..'"' or ""
    local lang = attr.lang and ' lang="'..attr.lang..'"' or ""
    local tag = (class and string.match(' ' ..attr.class .. ' ',' underline ')) and "u" or "span"
    local opentag = "<"..tag..id..class..lang..'>'
    local closetag = "</"..tag..">"
    return {opentag, s, closetag}
  end

  function Html.div(s, attr)
    local class = attr.class and attr.class ~="" and ' class="'..attr.class..'"' or ""
    local id = attr.id and ' id="'..attr.id..'"' or ""
    local lang = attr.lang and ' lang="'..attr.lang..'"' or ""
    local opentag = '<div'..id..class..lang..'>'
    local closetag = "</div>"
    return {opentag, s, closetag}
  end

  function Html.blockquote(s)
    return {"<blockquote>", containersep, s, containersep, "</blockquote>"}
  end

  function Html.verbatim(s)
    return {"<pre><code>", Html.string(s), "</code></pre>"}
  end

  function Html.fenced_code(s,i)
    if i ~= "" then
      return {'<pre><code class="language-', i:match("[^ ]*"),
        '">', Html.string(s), "</code></pre>"}
    else
      return Html.verbatim(s)
    end
  end

  function Html.rawinline(s,format)
    return format == "html" and s or {}
  end

  function Html.rawblock(s,format)
    return format == "html" and s or {}
  end

  function Html.header(s,level,attr)
    local class = attr.class and attr.class ~= "" and ' class="'..attr.class..'"' or ""
    local id = attr.id and ' id="'..attr.id..'"' or ""
    local lang = attr.lang and ' lang="'..attr.lang..'"' or ""
    local sep = ""
    if options.slides or options.containers then
      local lev = (options.slides and 1) or level
      local stop = Html.stop_section(lev)
      if stop ~= "" then
        stop = stop .. Html.interblocksep
      end
      sep = stop .. Html.start_section(lev) .. Html.containersep
    end
    return {sep, "<h", level, id, class, lang, ">", s, "</h", level, ">"}
  end

  Html.hrule = "<hr />"

  function Html.note(contents)
    local num = #endnotes + 1
    local backref = ' <a href="#fnref' .. num .. '" class="footnoteBackLink">↩</a>'
    local contentsf = flatten(contents)
    if contentsf[#contentsf] == "</p>" then
      table.insert(contentsf, #contentsf, backref)
    else
      contentsf[#contentsf + 1] = backref
    end
    endnotes[num] = {'<li id="fn', num, '">', contentsf, '</li>'}
    return {'<sup><a href="#fn', num, '" class="footnoteRef" id="fnref', num, '">', num, '</a></sup>'}
  end

  function Html.start_document()
    endnotes = {}
    return ""
  end

  function Html.stop_document()
    return function()
      local stop = Html.stop_section(1) -- close section containers
      if stop ~= "" then stop = Html.containersep .. stop end
      if #endnotes == 0 then
        return stop
      else
        return {stop, interblocksep, '<hr />', interblocksep, '<ol class="notes">',
           containersep, intersperse(endnotes, interblocksep), containersep, '</ol>'}
      end
    end
  end

  function Html.definitionlist(items, tight)
    local buffer = {}
    local sep
    if tight then sep = "" else sep = Html.containersep end
    for _,item in ipairs(items) do
      local defs = {}
      for _,def in ipairs(item.definitions) do
        defs[#defs + 1] = {"<dd>", sep, def, sep, "</dd>"}
      end
      buffer[#buffer + 1] = {"<dt>", item.term, "</dt>", containersep, intersperse(defs, containersep)}
    end
    return {"<dl>", containersep, intersperse(buffer, containersep), containersep, "</dl>"}
  end

  local function tableCellAlign (align)
    if align == 'l' then
      return ' style="text-align: left;"'
    elseif align == 'r' then
      return ' style="text-align: right;"'
    elseif align == 'c' then
      return ' style="text-align: center;"'
    end
    return ''
  end

  function Html.table(rows, caption)
    -- Mimic Pandoc output for such tables (in terms of carriage returns, class, styles, etc.)
    local t = {}
    local aligns = rows[2]

    if caption then
      t[#t+1] = { "<caption>", caption, "</caption>\n" }
    end

    local theadrow = { '<tr class="header">\n' }
    for j, column in ipairs(rows[1]) do
      local col = { "<th"..tableCellAlign(aligns[j])..">", column, "</th>\n" }
      theadrow[#theadrow+1] = col
    end
    theadrow[#theadrow+1] = "</tr>\n"
    t[#t+1] = { "<thead>\n", theadrow, "</thead>\n" }

    t[#t+1] = "<tbody>\n"
    for i = 3, #rows do
      local tbodyrows = { '<tr class="', (i % 2 == 0) and "even" or "odd",'">\n' }
      for j, column in ipairs(rows[i]) do
        local col = { "<td"..tableCellAlign(aligns[j])..">", column, "</td>\n" }
        tbodyrows[#tbodyrows+1] = col
      end
      tbodyrows[#tbodyrows+1]= "</tr>\n"
      t[#t+1] = tbodyrows
    end
    t[#t+1] = "</tbody>\n"

    return { "<table>\n", t, "</table>\n" }
  end

  Html.template = [[
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>$title</title>
</head>
<body>
$body
</body>
</html>
]]

  return Html
end

return M
