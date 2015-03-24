-- Table of contents class

-- Exports: The \tableofcontents command
--          The \tocentry command (call this in your sectioning commands)
--          writeToc (call this in finish)
--          moveTocNodes (call this in endPage)

SILE.scratch.tableofcontents = { }

local moveNodes = function(self)
  local n = SILE.scratch.info.thispage.toc
  if n then 
    for i = 1,#n do 
      n[i].pageno = SILE.formatCounter(SILE.scratch.counters.folio)
      SILE.scratch.tableofcontents[#(SILE.scratch.tableofcontents)+1] = n[i]
    end
  end
end

local writeToc = function ()
  local t = "return "..std.string.pickle(SILE.scratch.tableofcontents)
  local f,err = io.open(SILE.masterFileName .. '.toc',"w")
  if not f then return SU.error(err) end
  f:write(t)
end

SILE.registerCommand("tableofcontents", function (options, content)
  local f,err = io.open(SILE.masterFileName .. '.toc')
  if not f then
    SILE.call("tableofcontents:notocmessage")
    return
  end
  local doc = f:read("*all")
  local toc = assert(loadstring(doc))()
  SILE.call("tableofcontents:header")
  for i = 1,#toc do
    local item = toc[i]
    SILE.call("tableofcontents:item", {level = item.level, pageno= item.pageno}, item.label)
  end
end)

SILE.registerCommand("tableofcontents:item", function (o,c)
  SILE.settings.temporarily(function ()
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
    SILE.call("tableofcontents:level"..o.level.."item", {}, function()
      SILE.process({c})
      -- Ideally, leaders
      SILE.call("hss")
      SILE.typesetter:typeset(o.pageno)
    end)
  end)
end)

SILE.registerCommand("tocentry", function (options, content)
  SILE.call("info", {
    category = "toc",
    value = {
      label = content[1],
      level = (options.level or 1)
    }
  })
end)


return {
  exports = {writeToc = writeToc, moveTocNodes = moveNodes},
  init = function (self)
    self:loadPackage("infonode")
SILE.doTexlike([[%
\define[command=tableofcontents:notocmessage]{\tableofcontents:headerfont{Rerun SILE to process table of contents!}}%
\define[command=tableofcontents:headerfont]{\font[size=24pt,weight=800]{\process}}%
\define[command=tableofcontents:header]{\par\noindent\tableofcontents:headerfont{Table of Contents}\medskip}%
\define[command=tableofcontents:level1item]{\bigskip\noindent\font[size=14pt,weight=800]{\process}\medskip}%
\define[command=tableofcontents:level2item]{\noindent\font[size=12pt]{\process}\medskip}%
\define[command=tableofcontents:level3item]{\indent\font[size=10pt]{\process}\smallskip}%
]])

  end 
}