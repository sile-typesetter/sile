-- (c) 2009-2011 John MacFarlane. Released under MIT license.
-- See the file LICENSE in the source for details.

--- Groff man writer for lunamark.
-- Extends [lunamark.writer.groff].
--
-- Note: continuation paragraphs in lists are not
-- handled properly.

local M = {}

local groff = require("lunamark.writer.groff")
local util = require("lunamark.util")
local gsub = string.gsub
local format = string.format

--- Returns a new groff writer.
-- For a list of fields, see [lunamark.writer.generic].
function M.new(options)
  local options = options or {}
  local Man = groff.new(options)

  local endnotes = {}

  function Man.link(lab,src,tit)
    return {lab," (",src,")"}
  end

  function Man.image(lab,src,tit)
    return {"[IMAGE (",lab,")]"}
  end

  -- TODO handle continuations properly.
  -- pandoc does this:
  -- .IP \[bu] 2
  -- one
  -- .RS 2
  -- .PP
  -- cont
  -- .RE

  function Man.paragraph(contents)
    return {".PP\n",contents}
  end

  function Man.bulletlist(items,tight)
    local buffer = {}
    for _,item in ipairs(items) do
      local revitem = item
      -- we don't want to have .IP then .PP
      if revitem[1][1] == ".PP\n" then revitem[1][1] = "" end
      buffer[#buffer + 1] = {".IP \\[bu] 2\n",item}
    end
    return util.intersperse(buffer, Man.containersep)
  end

  function Man.orderedlist(items,tight,startnum)
    local buffer = {}
    local num = startnum or 1
    for _,item in ipairs(items) do
      local revitem = item
      -- we don't want to have .IP then .PP
      if revitem[1][1] == ".PP\n" then revitem[1][1] = "" end
      buffer[#buffer + 1] = {format(".IP \"%d.\" 4\n",num),item}
      num = num + 1
    end
    return util.intersperse(buffer, Man.containersep)
  end

  function Man.blockquote(s)
    return {".RS\n",s,"\n.RE"}
  end

  function Man.verbatim(s)
    return {".IP\n.nf\n\\f[C]\n",s,".fi"}
  end

  function Man.header(s,level)
    local hcode = ".SS"
    if level == 1 then hcode = ".SH" end
    return {hcode," ",s}
  end

  Man.hrule = ".PP\n * * * * *"

  function Man.note(contents)
    local num = #endnotes + 1
    endnotes[num] = {format(".SS [%d]\n",num),contents}
    return format('[%d]', num)
  end

  function Man.definitionlist(items,tight)
    local buffer = {}
    local ds
    for _,item in ipairs(items) do
        if tight then
          ds = util.intersperse(item.definitions,"\n.RS\n.RE\n")
          buffer[#buffer + 1] = {".TP\n.B ",item.term,"\n",ds,"\n.RS\n.RE"}
        else
          ds = util.intersperse(item.definitions,"\n.RS\n.RE\n")
          buffer[#buffer + 1] = {".TP\n.B ",item.term,"\n.RS\n",ds,"\n.RE"}
        end
    end
    local contents = util.intersperse(buffer,"\n")
    return contents
  end

  function Man.start_document()
    endnotes = {}
    return ""
  end

  function Man.stop_document()
    if #endnotes == 0 then
      return ""
    else
      return {"\n.SH NOTES\n", util.intersperse(endnotes, "\n")}
    end
  end

  Man.template = [===[
.TH "$title" "$section" "$date" "$left_footer" "$center_header"
$body
]===]

  return Man
end

return M
