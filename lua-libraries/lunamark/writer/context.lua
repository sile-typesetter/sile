-- (c) 2009-2011 John MacFarlane, Khaled Hosny, Hans Hagen.
-- Released under MIT license. See the file LICENSE in the source for details.

--- ConTeXt writer for lunamark.
-- Extends [lunamark.writer.tex].

local M = {}

local tex = require("lunamark.writer.tex")
local util = require("lunamark.util")

--- Returns a new ConTeXt writer
-- For a list of all the fields, see [lunamark.writer.generic].
function M.new(options)
  options = options or {}
  local ConTeXt = tex.new(options)

  -- we don't try to escape utf-8 characters in context
  local escape = util.escaper(ConTeXt.escaped)
  local escape_citation = util.escaper(ConTeXt.escaped_citation)
  ConTeXt.string = escape
  ConTeXt.citation = escape_citation

  function ConTeXt.singlequoted(s)
    return {"\\quote{",s,"}"}
  end

  function ConTeXt.doublequoted(s)
    return {"\\quotation{",s,"}"}
  end

  function ConTeXt.code(s)
    return {"\\type{",ConTeXt.string(s),"}"}
  end

  function ConTeXt.link(lab,src)
    return {"\\goto{",lab,"}[url(",ConTeXt.string(src),"]"}
  end

  function ConTeXt.image(_,src)
    return {"\\externalfigure[",ConTeXt.string(src),"]"}
  end

  local function listitem(s)
    return {"\\item ",s,"\n"}
  end

  function ConTeXt.bulletlist(items,tight)
    local opt = ""
    if tight then opt = "[packed]" end
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = listitem(item)
    end
    local contents = util.intersperse(buffer)
    return {"\\startitemize",opt,"\n",contents,"\\stopitemize"}
  end

  function ConTeXt.orderedlist(items,tight,startnum)
    local tightstr = ""
    if tight then tightstr = ",packed" end
    local opt = string.format("[%d%s]", startnum or 1, tightstr)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = listitem(item)
    end
    local contents = util.intersperse(buffer)
    return {"\\startitemize",opt,"\n",contents,"\\stopitemize"}
  end

  function ConTeXt.emphasis(s)
    return {"{\\em ",s,"}"}
  end

  function ConTeXt.strong(s)
    return {"{\\bf ",s,"}"}
  end

  function ConTeXt.blockquote(s)
    return {"\\startblockquote\n",s,"\\stopblockquote"}
  end

  function ConTeXt.verbatim(s)
    return {"\\starttyping\n",s,"\\stoptyping"}
  end

  function ConTeXt.fenced_code(s,i)
    if i ~= "" then
      return {"\\starttyping[option=",i:match("[^ ]*"),
        "]\n",s,"\\stoptyping"}
    else
      return ConTeXt.verbatim(s)
    end
  end

  function ConTeXt.header(s,level)
    local cmd
    if level == 1 then
      cmd = "\\section"
    elseif level == 2 then
      cmd = "\\subsection"
    elseif level == 3 then
      cmd = "\\subsubsection"
    elseif level == 4 then
      cmd = "\\paragraph"
    elseif level == 5 then
      cmd = "\\subparagraph"
    else
      cmd = ""
    end
    return {cmd,"{",s,"}"}
  end

  ConTeXt.hrule = "\\hairline"

  function ConTeXt.note(contents)
    return {"\\footnote{",contents,"}"}
  end

  function ConTeXt.definitionlist(items)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = {"\\startdescription{",item.term,"}\n",
         util.intersperse(item.definitions,ConTeXt.interblocksep),"\n\\stopdescription"}
    end
    local contents = util.intersperse(buffer, ConTeXt.containersep)
    return contents
  end

  ConTeXt.template = [===[
\startmode[*mkii]
  \enableregime[utf-8]
  \setupcolors[state=start]
\stopmode

% Enable hyperlinks
\setupinteraction[state=start, color=middleblue]

\setuppapersize [letter][letter]
\setuplayout    [width=middle,  backspace=1.5in, cutspace=1.5in,
                 height=middle, topspace=0.75in, bottomspace=0.75in]

\setuppagenumbering[location={footer,center}]

\setupbodyfont[11pt]

\setupwhitespace[medium]

\setuphead[section]      [style=\tfc]
\setuphead[subsection]   [style=\tfb]
\setuphead[subsubsection][style=\bf]

\definedescription
  [description]
  [headstyle=bold, style=normal, location=hanging, width=broad, margin=1cm]

\setupitemize[autointro]    % prevent orphan list intro
\setupitemize[indentnext=no]

\setupthinrules[width=15em] % width of horizontal rules

\setupdelimitedtext
  [blockquote]
  [before={\blank[medium]},
   after={\blank[medium]},
   indentnext=no,
  ]

\starttext
$if{ title }[=[
\startalignment[center]
\blank[2*big]
{\tfd $title}
$if{ author }[[
\blank[3*medium]
{\tfa $sepby{author}[==[$it]==][==[\crlf ]==]}
]]
$if{ date }[[
\blank[2*medium]
{\tfa $date}
]]
\blank[3*medium]
\stopalignment

]=]
$if{ toc }[[{\placecontent}
]]
$body

\stoptext
]===]

  return ConTeXt
end

return M
