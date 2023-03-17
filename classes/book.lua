local plain = require("classes.plain")

local class = pl.class(plain)
class._name = "book"

class.defaultFrameset = {
  content = {
    left = "8.3%pw",
    right = "86%pw",
    top = "11.6%ph",
    bottom = "top(footnotes)"
  },
  folio = {
    left = "left(content)",
    right = "right(content)",
    top = "bottom(footnotes)+3%ph",
    bottom = "bottom(footnotes)+5%ph"
  },
  runningHead = {
    left = "left(content)",
    right = "right(content)",
    top = "top(content)-8%ph",
    bottom = "top(content)-3%ph"
  },
  footnotes = {
    left = "left(content)",
    right = "right(content)",
    height = "0",
    bottom = "83.3%ph"
  }
}

function class:_init (options)
  plain._init(self, options)
  self:loadPackage("counters")
  self:loadPackage("masters", {{
      id = "right",
      firstContentFrame = self.firstContentFrame,
      frames = self.defaultFrameset
    }})
  self:loadPackage("twoside", {
      oddPageMaster = "right",
      evenPageMaster = "left"
    })
  self:loadPackage("tableofcontents")
  self:loadPackage("footnotes", {
      insertInto = "footnotes",
      stealFrom = { "content" }
    })
  if not SILE.scratch.headers then SILE.scratch.headers = {} end
end

function class:endPage ()
  if not SILE.scratch.headers.skipthispage then
    if self:oddPage() and SILE.scratch.headers.right then
      SILE.typesetNaturally(SILE.getFrame("runningHead"), function ()
        SILE.settings:toplevelState()
        SILE.settings:set("current.parindent", SILE.nodefactory.glue())
        SILE.settings:set("document.lskip", SILE.nodefactory.glue())
        SILE.settings:set("document.rskip", SILE.nodefactory.glue())
        -- SILE.settings:set("typesetter.parfillskip", SILE.nodefactory.glue())
        SILE.process(SILE.scratch.headers.right)
        SILE.call("par")
      end)
    elseif not self:oddPage() and SILE.scratch.headers.left then
      SILE.typesetNaturally(SILE.getFrame("runningHead"), function ()
        SILE.settings:toplevelState()
        SILE.settings:set("current.parindent", SILE.nodefactory.glue())
        SILE.settings:set("document.lskip", SILE.nodefactory.glue())
        SILE.settings:set("document.rskip", SILE.nodefactory.glue())
        -- SILE.settings:set("typesetter.parfillskip", SILE.nodefactory.glue())
        SILE.process(SILE.scratch.headers.left)
        SILE.call("par")
      end)
    end
  end
  SILE.scratch.headers.skipthispage = false
  return plain.endPage(self)
end

function class:finish ()
  local ret = plain.finish(self)
  return ret
end

function class:registerCommands ()

  plain.registerCommands(self)

  self:registerCommand("left-running-head", function (_, content)
    local closure = SILE.settings:wrap()
    SILE.scratch.headers.left = function () closure(content) end
  end, "Text to appear on the top of the left page")

  self:registerCommand("right-running-head", function (_, content)
    local closure = SILE.settings:wrap()
    SILE.scratch.headers.right = function () closure(content) end
  end, "Text to appear on the top of the right page")

  self:registerCommand("book:sectioning", function (options, content)
    local level = SU.required(options, "level", "book:sectioning")
    local number
    if SU.boolean(options.numbering, true) then
      SILE.call("increment-multilevel-counter", { id = "sectioning", level = level })
      number = self.packages.counters:formatMultilevelCounter(self:getMultilevelCounter("sectioning"))
    end
    if SU.boolean(options.toc, true) then
      SILE.call("tocentry", { level = level, number = number }, SU.subContent(content))
    end
    if SU.boolean(options.numbering, true) then
      if options.msg then
        SILE.call("fluent", { number = number }, { options.msg })
      else
        SILE.call("show-multilevel-counter", { id = "sectioning" })
      end
    end
  end)

  SU.deprecated("book:volume:pre", "book:volume:prenumber")
  self:registerCommand("book:volume:prenumber", function (options, content)
  end)

  SU.deprecated("book:volume:post", "book:volume:postnumber")
  self:registerCommand("book:volume:postnumber", function (options, content)
    SILE.call("par")
  end)

  SU.deprecated("book:part:pre", "book:part:prenumber")
  self:registerCommand("book:part:prenumber", function (options, content)
  end)

  SU.deprecated("book:part:post", "book:part:postnumber")
  self:registerCommand("book:part:postnumber", function (options, content)
    SILE.call("par")
  end)

  SU.deprecated("book:chapter:pre", "book:chapter:prenumber")
  self:registerCommand("book:chapter:prenumber", function (options, content)
  end)

  SU.deprecated("book:chapter:post", "book:chapter:postnumber")
  self:registerCommand("book:chapter:postnumber", function (options, content)
    SILE.call("par")
  end)

  SU.deprecated("book:section:pre", "book:section:prenumber")
  self:registerCommand("book:section:prenumber", function (options, content)
  end)

  SU.deprecated("book:section:post", "book:section:postnumber")
  self:registerCommand("book:section:postnumber", function (options, content)
    SILE.typesetter:typeset(" ")
  end)

  SU.deprecated("book:subsection:pre", "book:subsection:prenumber")
  self:registerCommand("book:subsection:prenumber", function (options, content)
  end)

  SU.deprecated("book:subsection:post", "book:subsection:postnumber")
  self:registerCommand("book:subsection:postnumber", function (options, content)
    SILE.typesetter:typeset(" ")
  end)

  SU.deprecated("book:subsubsection:pre", "book:subsubsection:prenumber")
  self:registerCommand("book:subsubsection:prenumber", function (options, content)
  end)

  SU.deprecated("book:subsubsection:post", "book:subsubsection:postnumber")
  self:registerCommand("book:subsubsection:postnumber", function (options, content)
    SILE.typesetter:typeset(" ")
  end)

  SU.deprecated("book:subsubsubsection:pre", "book:subsubsubsection:prenumber")
  self:registerCommand("book:subsubsubsection:prenumber", function (options, content)
  end)

  SU.deprecated("book:subsubsubsection:post", "book:subsubsubsection:postnumber")
  self:registerCommand("book:subsubsubsection:postnumber", function (options, content)
    SILE.typesetter:typeset(" ")
  end)

  self:registerCommand("book:left-running-head-font", function (_, content)
    SILE.call("font", { size = "9pt" }, content)
  end)

  self:registerCommand("book:right-running-head-font", function (_, content)
    SILE.call("font", { size = "9pt", style = "Italic" }, content)
  end)

  self:registerCommand("volume", function (options, content)
    SILE.call("open-double-page")
    SILE.call("nofoliosthispage")
    SILE.call("noindent")
    SILE.call("center", {}, function ()
      SILE.call("book:volume:font", {}, function ()
        SILE.call("hbox")
        SILE.call("vfill")
        SILE.call("book:sectioning", {
            numbering = options.numbering or false,
            toc = options.toc,
            level = 1,
            msg = "book-volume-title",
            prenumber = "book:volume:prenumber",
            postnumber = "book:volume:postnumber"
          }, content)
        SILE.process(content)
      end)
    end)
  end, "Begin a new volume");

  self:registerCommand("part", function (options, content)
    SILE.call("open-double-page")
    SILE.call("nofoliosthispage")
    SILE.call("noindent")
    SILE.call("center", {}, function ()
      SILE.call("book:part:font", {}, function ()
        SILE.call("hbox")
        SILE.call("vfill")
        SILE.call("book:sectioning", {
            numbering = options.numbering,
            toc = options.toc,
            level = 2,
            msg = "book-part-title",
            prenumber = "book:part:prenumber",
            postnumber = "book:part:postnumber"
          }, content)
        SILE.process(content)
      end)
    end)
  end, "Begin a new part");

  self:registerCommand("chapter", function (options, content)
    SILE.typesetter:leaveHmode()
    SILE.call("open-spread", { double = false })
    SILE.call("noindent")
    SILE.scratch.headers.right = nil
    SILE.call("set-counter", { id = "footnote", value = 1 })
    SILE.call("book:chapter:font", {}, function ()
      SILE.call("book:sectioning", {
          numbering = options.numbering,
          toc = options.toc,
          level = 3,
          msg = "book-chapter-title",
          prenumber = "book:chapter:prenumber",
          postnumber = "book:chapter:postnumber"
        }, content)
      SILE.process(content)
    end)
    SILE.call("left-running-head", {}, function ()
      SILE.settings:temporarily(function ()
        SILE.call("book:left-running-head-font", {}, content)
      end)
    end)
    SILE.call("bigskip")
    SILE.call("nofoliothispage")
  end, "Begin a new chapter")

  self:registerCommand("section", function (options, content)
    SILE.typesetter:leaveHmode()
    SILE.call("goodbreak")
    SILE.call("bigskip")
    SILE.call("noindent")
    SILE.call("book:sectionfont", {}, function ()
      SILE.call("book:sectioning", {
        numbering = options.numbering,
        toc = options.toc,
        level = 4,
        msg = "book-section-title",
        prenumber = "book:section:prenumber",
        postnumber = "book:section:postnumber"
      }, content)
      SILE.process(content)
    end)
    if not SILE.scratch.counters.folio.off then
      SILE.call("right-running-head", {}, function ()
        SILE.call("book:right-running-head-font", {}, function ()
          SILE.call("rightalign", {}, function ()
            SILE.settings:temporarily(function ()
              if SU.boolean(options.numbering, true) then
                SILE.call("show-multilevel-counter", { id = "sectioning", level = 2 })
                SILE.typesetter:typeset(" ")
              end
              SILE.process(content)
            end)
          end)
        end)
      end)
    end
    SILE.call("novbreak")
    SILE.call("bigskip")
    SILE.call("novbreak")
    SILE.typesetter:inhibitLeading()
  end, "Begin a new section")

  self:registerCommand("subsection", function (options, content)
    SILE.typesetter:leaveHmode()
    SILE.call("goodbreak")
    SILE.call("noindent")
    SILE.call("medskip")
    SILE.call("book:subsectionfont", {}, function ()
      SILE.call("book:sectioning", {
            numbering = options.numbering,
            toc = options.toc,
            level = 5,
            msg = "book-subsection-title",
            prenumber = "book:subsection:prenumber",
            postnumber = "book:subsection:postnumber"
          }, content)
      SILE.process(content)
    end)
    SILE.typesetter:leaveHmode()
    SILE.call("novbreak")
    SILE.call("medskip")
    SILE.call("novbreak")
    SILE.typesetter:inhibitLeading()
  end, "Begin a new subsection")

  self:registerCommand("subsubsection", function (options, content)
    SILE.typesetter:leaveHmode()
    SILE.call("goodbreak")
    SILE.call("noindent")
    SILE.call("medskip")
    SILE.call("book:subsection:font", {}, function ()
      SILE.call("book:sectioning", {
            numbering = options.numbering,
            toc = options.toc,
            level = 6,
            msg = "book-subsubsection-title",
            prenumber = "book:subsubsection:prenumber",
            postnumber = "book:subsubsection:postnumber"
          }, content)
      SILE.process(content)
    end)
    SILE.typesetter:leaveHmode()
    SILE.call("novbreak")
    SILE.call("medskip")
    SILE.call("novbreak")
    SILE.typesetter:inhibitLeading()
  end, "Begin a new subsubsection")

  self:registerCommand("subsubsubsection", function (options, content)
    SILE.typesetter:leaveHmode()
    SILE.call("goodbreak")
    SILE.call("noindent")
    SILE.call("medskip")
    SILE.call("book:subsection:font", {}, function ()
      SILE.call("book:sectioning", {
            numbering = options.numbering,
            toc = options.toc,
            level = 7,
            msg = "book-subsubsubsection-title",
            prenumber = "book:subsubsubsection:prenumber",
            postnumber = "book:subsubsubsection:postnumber"
          }, content)
      SILE.process(content)
    end)
    SILE.typesetter:leaveHmode()
    SILE.call("novbreak")
    SILE.call("medskip")
    SILE.call("novbreak")
    SILE.typesetter:inhibitLeading()
  end, "Begin a new subsubsubsection")

  SU.deprecated("\\book:chapterfont", "\\book:chapter:font", "0.9.6", "0.9.7")
  SU.deprecated("\\book:sectionfont", "\\book:section:font", "0.9.6", "0.9.7")
  SU.deprecated("\\book:subsectionfont", "\\book:subsection:font", "0.9.6", "0.9.7")

  self:registerCommand("book:volume:font", function (_, content)
    SILE.call("font", { weight = 800, size = "48pt" }, content)
  end)

  self:registerCommand("book:part:font", function (_, content)
    SILE.call("font", { weight = 800, size = "36pt" }, content)
  end)

  self:registerCommand("book:chapter:font", function (_, content)
    SILE.call("font", { weight = 800, size = "22pt" }, content)
  end)

  self:registerCommand("book:section:font", function (_, content)
    SILE.call("font", { weight = 800, size = "15pt" }, content)
  end)

  self:registerCommand("book:subsection:font", function (_, content)
    SILE.call("font", { weight = 800, size = "12pt" }, content)
  end)

  self:registerCommand("book:subsubsection:font", function (_, content)
    SILE.call("font", { weight = 800, size = "11pt" }, content)
  end)

  self:registerCommand("book:subsubsubsection:font", function (_, content)
    SILE.call("font", { weight = 800, size = "10pt" }, content)
  end)

end

return class
