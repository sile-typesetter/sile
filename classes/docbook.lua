local plain = require("classes.plain")

local class = pl.class(plain)
class._name = "docbook"

SILE.scratch.docbook = {
  seclevel = 0,
  seccount = {}
}

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
  self:loadPackage("footnotes")
  return self
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

  -- Unfinished! commands found in howto.xml example document on docbook.org
  self:registerCommand("acronym", function (_, content) SILE.process(content) end)
  self:registerCommand("alt", function (_, content) SILE.process(content) end)
  self:registerCommand("note", function (_, content) SILE.process(content) end)
  self:registerCommand("colspec", function (_, content) SILE.process(content) end)
  self:registerCommand("phrase", function (_, content) SILE.process(content) end)
  self:registerCommand("literal", function (_, content) SILE.process(content) end)
  self:registerCommand("docbook-section-3-title", function (_, content) SILE.process(content) end)
  self:registerCommand("variablelist", function (_, content) SILE.process(content) end)
  self:registerCommand("varlistentry", function (_, content) SILE.process(content) end)
  self:registerCommand("term", function (_, content) SILE.process(content) end)
  self:registerCommand("procedure", function (_, content) SILE.process(content) end)
  self:registerCommand("step", function (_, content) SILE.process(content) end)
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
  self:registerCommand("answer", function (_, content) SILE.process(content) end)

  self:registerCommand("docbook-line", function (_, _)
    SILE.call("medskip")
    SILE.call("hrule", { height = "0.5pt", width = "50mm" })
    SILE.call("medskip")
  end)

  self:registerCommand("docbook-sectionsfont", function (_, content)
    SILE.call("font", { family = "DejaVu Sans", style = "Condensed", weight = 800 }, content)
  end)

  self:registerCommand("docbook-ttfont", function (_, content)
    SILE.call("font", { family = "Hack", size = "2ex" }, content)
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


  self:registerCommand("para", function (_, content)
    SILE.process(content)
    SILE.call("par")
  end)

  self:registerCommand("emphasis", function (_, content)
    SILE.call("em", {}, content)
  end)

  self:registerCommand("replaceable", function (_, content)
    SILE.call("em", {}, content)
  end)

  self:registerCommand("abbrev", function (_, content)
    SILE.call("font", { variant = "smallcaps" }, content)
  end)

  self:registerCommand("title", function (_, content)
    SILE.call("em", {}, content)
  end)

  self:registerCommand("personname", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("email", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("uri", function (_, content)
    SILE.call("code", {}, content)
  end)

  self:registerCommand("personblurb", function (_, content)
    SILE.call("font", { size = "2ex" }, content)
  end)

  self:registerCommand("affiliation", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("jobtitle", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("orgname", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("application", function (_, content)
    SILE.call("em", {}, content)
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

  self:registerCommand("code", function (_, content)
    SILE.call("docbook-ttfont", {}, content)
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

  self:registerCommand("xref", function (_, _)
    SILE.typesetter:typeset("XXX")
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
    SILE.process(content)
  end)

  self:registerCommand("imageobject", function (_, content)
    SILE.process(content)
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

  self:registerCommand("article", function (_, content)
    local info = SILE.inputter:findInTree(content, "info") or SILE.inputter:findInTree(content, "articleinfo")
    local title = SILE.inputter:findInTree(content, "title") or (info and SILE.inputter:findInTree(info, "title"))
    local author = SILE.inputter:findInTree(content, "author") or (info and SILE.inputter:findInTree(info, "author"))

    if title then
      SILE.call("docbook-article-title", {}, title)
      self.wipe(title)
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
    SILE.process(content)
    SILE.typesetter:chuck()
  end)

  self:registerCommand("info", function ()end)

  self:registerCommand("section", function (_, content)
    SILE.scratch.docbook.seclevel = SILE.scratch.docbook.seclevel + 1
    SILE.scratch.docbook.seccount[SILE.scratch.docbook.seclevel] = (SILE.scratch.docbook.seccount[SILE.scratch.docbook.seclevel] or 0) + 1
    while #(SILE.scratch.docbook.seccount) > SILE.scratch.docbook.seclevel do
      SILE.scratch.docbook.seccount[#(SILE.scratch.docbook.seccount)] = nil
    end
    local title = SILE.inputter:findInTree(content, "title")
    local number = table.concat(SILE.scratch.docbook.seccount, '.')
    if title then
      SILE.call("docbook-section-"..SILE.scratch.docbook.seclevel.."-title", {}, function ()
        SILE.typesetter:typeset(number.." ")
        SILE.process(title)
      end)
      self.wipe(title)
    end
    SILE.process(content)
    SILE.scratch.docbook.seclevel = SILE.scratch.docbook.seclevel - 1
  end)

  local function countedThing(thing, _, content)
    SILE.call("increment-counter", {id=thing})
    SILE.call("bigskip")
    SILE.call("docbook-line")
    SILE.call("docbook-titling", {}, function ()
      SILE.typesetter:typeset(thing.." ".. self:formatCounter(SILE.scratch.counters[thing]))
      local t = SILE.inputter:findInTree(content, "title")
      if t then
        SILE.typesetter:typeset(": ")
        SILE.process(t)
        self.wipe(t)
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

  self:registerCommand("table", function (options, content)
    countedThing("Table", options, content)
  end)
  self:registerCommand("figure", function (options, content)
    countedThing("Figure", options, content)
  end)

  self:registerCommand("imagedata", function (options, _)
    local width = SILE.parseComplexFrameDimension(options.width or "100%pw") or 0
    SILE.call("img", {
      src = options.fileref,
      width = width / 2
    })
  end)


  self:registerCommand("itemizedlist", function (_, content)
    self.push("list", {type = "itemized"})
    SILE.call("medskip")
    -- Indentation
    SILE.process(content)
    SILE.call("medskip")
    self.pop("list")
  end)


  self:registerCommand("orderedlist", function (_, content)
    self.push("list", {type = "ordered", ctr = 1})
    SILE.call("medskip")
    -- Indentation
    SILE.process(content)
    SILE.call("medskip")
    self.pop("list")
  end)

  self:registerCommand("listitem", function (_, content)
    local ctx = self.val("list")
    if ctx and ctx.type == "ordered" then
      SILE.typesetter:typeset( ctx.ctr ..". ")
      ctx.ctr = ctx.ctr + 1
    elseif ctx and ctx.type == "itemized" then
      SILE.typesetter:typeset( "• ")
    -- elseif ctx and ctx.type == "" then
    --   -- Other types?
    else
      return SU.warn("Listitem in outer space")
    end
    SILE.call("noindent")
    for _=1, #ctx-1 do SILE.call("qquad") end -- Setting lskip better?
    SILE.process(content)
    SILE.call("medskip")
  end)

  self:registerCommand("link", function (options, content)
    SILE.process(content)
    if (options["xl:href"]) then
      SILE.typesetter:typeset(" (")
      SILE.call("code", {}, {options["xl:href"]})
      SILE.typesetter:typeset(")")
    end
  end)

end

return class
