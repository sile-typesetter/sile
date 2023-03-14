local plain = SILE.require("plain", "classes")
local book = plain { id = "book" }

book:loadPackage("masters")
book:defineMaster({
    id = "right",
    firstContentFrame = "content",
    frames = {
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
  })

book:loadPackage("twoside", { oddPageMaster = "right", evenPageMaster = "left" })

book:loadPackage("tableofcontents")

if not SILE.scratch.headers then SILE.scratch.headers = {} end

book.init = function (self)
  self:mirrorMaster("right", "left")
  self.switchMaster("right")
  self:loadPackage("footnotes", { insertInto = "footnotes", stealFrom = { "content" } })
  return plain.init(self)
end

book.newPage = function (self)
  self:switchPage()
  self:newPageInfo()
  return plain.newPage(self)
end

book.finish = function (self)
  local ret = plain.finish(self)
  self:writeToc()
  return ret
end

book.endPage = function (self)
  self:moveTocNodes()

  if (self:oddPage() and SILE.scratch.headers.right) then
    SILE.typesetNaturally(SILE.getFrame("runningHead"), function ()
      SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
      SILE.settings.set("document.lskip", SILE.nodefactory.zeroGlue)
      SILE.settings.set("document.rskip", SILE.nodefactory.zeroGlue)
      -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
      SILE.process(SILE.scratch.headers.right)
      SILE.call("par")
    end)
  elseif (not(self:oddPage()) and SILE.scratch.headers.left) then
      SILE.typesetNaturally(SILE.getFrame("runningHead"), function ()
        SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
        SILE.settings.set("document.lskip", SILE.nodefactory.zeroGlue)
        SILE.settings.set("document.rskip", SILE.nodefactory.zeroGlue)
          -- SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
        SILE.process(SILE.scratch.headers.left)
        SILE.call("par")
      end)
  end
  return plain.endPage(book)
end

SILE.registerCommand("left-running-head", function (options, content)
  local closure = SILE.settings.wrap()
  SILE.scratch.headers.left = function () closure(content) end
end, "Text to appear on the top of the left page")

SILE.registerCommand("right-running-head", function (options, content)
  local closure = SILE.settings.wrap()
  SILE.scratch.headers.right = function () closure(content) end
end, "Text to appear on the top of the right page")

SILE.registerCommand("book:sectioning", function (options, content)
  local level = SU.required(options, "level", "book:sectioning")
  SILE.call("increment-multilevel-counter", {id = "sectioning", level = level})
  if SU.boolean(options.toc, true) then
    SILE.call("tocentry", {level = level}, SU.subContent(content))
  end
  local lang = SILE.settings.get("document.language")
  if options.numbering == nil or options.numbering == "yes" then
    if options.prenumber then
      if SILE.Commands[options.prenumber .. ":"  .. lang] then
        options.prenumber = options.prenumber .. ":" .. lang
      end
      SILE.call(options.prenumber)
    end
    SILE.call("show-multilevel-counter", {id="sectioning"})
    if options.postnumber then
      if SILE.Commands[options.postnumber .. ":" .. lang] then
        options.postnumber = options.postnumber .. ":" .. lang
      end
      SILE.call(options.postnumber)
    end
  end
end)

book.registerCommands = function ()
  plain.registerCommands()

  SU.deprecate("book:volume:pre", "book:volume:prenumber")
  SILE.registerCommand("book:volume:prenumber", function (options, content)
  end)

  SU.deprecate("book:volume:post", "book:volume:postnumber")
  SILE.registerCommand("book:volume:postnumber", function (options, content)
    SILE.call("par")
  end)

  SU.deprecate("book:part:pre", "book:part:prenumber")
  SILE.registerCommand("book:part:prenumber", function (options, content)
  end)

  SU.deprecate("book:part:post", "book:part:postnumber")
  SILE.registerCommand("book:part:postnumber", function (options, content)
    SILE.call("par")
  end)

  SU.deprecate("book:chapter:pre", "book:chapter:prenumber")
  SILE.registerCommand("book:chapter:prenumber", function (options, content)
  end)

  SU.deprecate("book:chapter:post", "book:chapter:postnumber")
  SILE.registerCommand("book:chapter:postnumber", function (options, content)
    SILE.call("par")
  end)

  SU.deprecate("book:section:pre", "book:section:prenumber")
  SILE.registerCommand("book:section:prenumber", function (options, content)
  end)

  SU.deprecate("book:section:post", "book:section:postnumber")
  SILE.registerCommand("book:section:postnumber", function (options, content)
    SILE.typesetter:typeset(" ")
  end)

  SU.deprecate("book:subsection:pre", "book:subsection:prenumber")
  SILE.registerCommand("book:subsection:prenumber", function (options, content)
  end)

  SU.deprecate("book:subsection:post", "book:subsection:postnumber")
  SILE.registerCommand("book:subsection:postnumber", function (options, content)
    SILE.typesetter:typeset(" ")
  end)

  SU.deprecate("book:subsubsection:pre", "book:subsubsection:prenumber")
  SILE.registerCommand("book:subsubsection:prenumber", function (options, content)
  end)

  SU.deprecate("book:subsubsection:post", "book:subsubsection:postnumber")
  SILE.registerCommand("book:subsubsection:postnumber", function (options, content)
    SILE.typesetter:typeset(" ")
  end)

  SU.deprecate("book:subsubsubsection:pre", "book:subsubsubsection:prenumber")
  SILE.registerCommand("book:subsubsubsection:prenumber", function (options, content)
  end)

  SU.deprecate("book:subsubsubsection:post", "book:subsubsubsection:postnumber")
  SILE.registerCommand("book:subsubsubsection:postnumber", function (options, content)
    SILE.typesetter:typeset(" ")
  end)

  SILE.registerCommand("book:left-running-head-font", function (options, content)
    SILE.call("font", { size = "9pt" })
  end)

  SILE.registerCommand("book:right-running-head-font", function (options, content)
    SILE.call("font", { size = "9pt", style = "Italic" })
  end)

  SILE.registerCommand("volume", function (options, content)
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
            prenumber = "book:volume:prenumber",
            postnumber = "book:volume:postnumber"
          }, content)
        end)
        SILE.call("book:volume:font", {}, content)
    end)
  end, "Begin a new volume");

  SILE.registerCommand("part", function (options, content)
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
            prenumber = "book:part:prenumber",
            postnumber = "book:part:postnumber"
          }, content)
        end)
        SILE.call("book:part:font", {}, content)
    end)
  end, "Begin a new part");

  SILE.registerCommand("chapter", function (options, content)
    SILE.call("open-double-page")
    SILE.call("noindent")
    SILE.scratch.headers.right = nil
    SILE.call("set-counter", {id = "footnote", value = 1})
    SILE.call("book:chapter:font", {}, function ()
      SILE.call("book:sectioning", {
        numbering = options.numbering,
        toc = options.toc,
        level = 3,
        prenumber = "book:chapter:prenumber",
        postnumber = "book:chapter:postnumber"
      }, content)
    end)
    SILE.call("book:chapter:font", {}, content)
    SILE.call("left-running-head", {}, function ()
      SILE.settings.temporarily(function ()
        SILE.call("book:left-running-head-font")
        SILE.process(content)
      end)
    end)
    SILE.call("bigskip")
    SILE.call("nofoliosthispage")
  end, "Begin a new chapter")

  SILE.registerCommand("section", function (options, content)
    SILE.typesetter:leaveHmode()
    SILE.call("goodbreak")
    SILE.call("bigskip")
    SILE.call("noindent")
    SILE.call("book:section:font", {}, function ()
      SILE.call("book:sectioning", {
        numbering = options.numbering,
        toc = options.toc,
        level = 3,
        prenumber = "book:section:prenumber",
        postnumber = "book:section:postnumber"
      }, content)
      SILE.process(content)
    end)
    if not SILE.scratch.counters.folio.off then
      SILE.call("right-running-head", {}, function ()
        SILE.call("book:right-running-head-font")
        SILE.call("rightalign", {}, function ()
          SILE.settings.temporarily(function ()
            SILE.call("show-multilevel-counter", { id = "sectioning", level = 4 })
            SILE.typesetter:typeset(" ")
            SILE.process(content)
          end)
        end)
      end)
    end
    SILE.call("novbreak")
    SILE.call("bigskip")
    SILE.call("novbreak")
    SILE.typesetter:inhibitLeading()
  end, "Begin a new section")

  SILE.registerCommand("subsection", function (options, content)
    SILE.typesetter:leaveHmode()
    SILE.call("goodbreak")
    SILE.call("noindent")
    SILE.call("medskip")
    SILE.call("book:subsection:font", {}, function ()
      SILE.call("book:sectioning", {
            numbering = options.numbering,
            toc = options.toc,
            level = 5,
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

  SILE.registerCommand("subsubsection", function (options, content)
    SILE.typesetter:leaveHmode()
    SILE.call("goodbreak")
    SILE.call("noindent")
    SILE.call("medskip")
    SILE.call("book:subsection:font", {}, function ()
      SILE.call("book:sectioning", {
            numbering = options.numbering,
            toc = options.toc,
            level = 6,
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

  SILE.registerCommand("subsubsubsection", function (options, content)
    SILE.typesetter:leaveHmode()
    SILE.call("goodbreak")
    SILE.call("noindent")
    SILE.call("medskip")
    SILE.call("book:subsection:font", {}, function ()
      SILE.call("book:sectioning", {
            numbering = options.numbering,
            toc = options.toc,
            level = 7,
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

  -- Deprecated function names, change to error after min 0.9.6, drop after min 0.9.7
  SU.deprecate("book:chapterfont", "book:chapter:font")
  SU.deprecate("book:sectionfont", "book:section:font")
  SU.deprecate("book:subsectionfont", "book:subsection:font")

  SILE.registerCommand("book:volume:font", function (options, content)
    SILE.call("font", { weight = 800, size = "48pt" }, content)
  end)

  SILE.registerCommand("book:part:font", function (options, content)
    SILE.call("font", { weight = 800, size = "36pt" }, content)
  end)

  SILE.registerCommand("book:chapter:font", function (options, content)
    SILE.call("font", { weight = 800, size = "22pt" }, content)
  end)

  SILE.registerCommand("book:section:font", function (options, content)
    SILE.call("font", { weight = 800, size = "15pt" }, content)
  end)

  SILE.registerCommand("book:subsection:font", function (options, content)
    SILE.call("font", { weight = 800, size = "12pt" }, content)
  end)

  SILE.registerCommand("book:subsubsection:font", function (options, content)
    SILE.call("font", { weight = 800, size = "11pt" }, content)
  end)

  SILE.registerCommand("book:subsubsubsection:font", function (options, content)
    SILE.call("font", { weight = 800, size = "10pt" }, content)
  end)

end

return book
