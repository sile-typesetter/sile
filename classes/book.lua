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
  plain._init(self, options)
  self:loadPackage("tableofcontents")
  self:loadPackage("footnotes", {
      insertInto = "footnotes",
      stealFrom = { "content" }
    })
  if not SILE.scratch.headers then SILE.scratch.headers = {} end
end

function class:endPage ()
  if (self:oddPage() and SILE.scratch.headers.right) then
    SILE.typesetNaturally(SILE.getFrame("runningHead"), function ()
      SILE.settings:toplevelState()
      SILE.settings:set("current.parindent", SILE.nodefactory.glue())
      SILE.settings:set("document.lskip", SILE.nodefactory.glue())
      SILE.settings:set("document.rskip", SILE.nodefactory.glue())
      -- SILE.settings:set("typesetter.parfillskip", SILE.nodefactory.glue())
      SILE.process(SILE.scratch.headers.right)
      SILE.call("par")
    end)
  elseif (not(self:oddPage()) and SILE.scratch.headers.left) then
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
    local lang = SILE.settings:get("document.language")
    if SU.boolean(options.numbering, true) then
      if options.template then
        SILE.call("fluent", { number = number }, { options.template })
      else
        SILE.call("show-multilevel-counter", { id = "sectioning" })
      end
      if options.postnumber then
        if SILE.Commands[options.postnumber .. ":" .. lang] then
          options.postnumber = options.postnumber .. ":" .. lang
        end
        SILE.call(options.postnumber)
      end
    end
  end)

  self:registerCommand("book:chapter:post", function (_, _)
    SILE.call("par")
  end)

  self:registerCommand("book:section:post", function (_, _)
    SILE.process({ " " })
  end)

  self:registerCommand("book:subsection:post", function (_, _)
    SILE.process({ " " })
  end)

  self:registerCommand("book:left-running-head-font", function (_, content)
    SILE.call("font", { size = "9pt" }, content)
  end)

  self:registerCommand("book:right-running-head-font", function (_, content)
    SILE.call("font", { size = "9pt", style = "Italic" }, content)
  end)

  self:registerCommand("chapter", function (options, content)
    SILE.call("open-double-page")
    SILE.call("noindent")
    SILE.scratch.headers.right = nil
    SILE.call("set-counter", { id = "footnote", value = 1 })
    SILE.call("book:chapterfont", {}, function ()
      SILE.call("book:sectioning", {
        numbering = options.numbering,
        toc = options.toc,
        level = 1,
        template = "chapter-template",
        postnumber = "book:chapter:post"
      }, content)
    end)
    SILE.call("book:chapterfont", {}, content)
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
        level = 2,
        postnumber = "book:section:post"
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
            level = 3,
            postnumber = "book:subsection:post"
          }, content)
      SILE.process(content)
    end)
    SILE.typesetter:leaveHmode()
    SILE.call("novbreak")
    SILE.call("medskip")
    SILE.call("novbreak")
    SILE.typesetter:inhibitLeading()
  end, "Begin a new subsection")

  self:registerCommand("book:chapterfont", function (_, content)
    SILE.settings:temporarily(function ()
      SILE.call("font", { weight = 800, size = "22pt" }, content)
    end)
  end)
  self:registerCommand("book:sectionfont", function (_, content)
    SILE.settings:temporarily(function ()
      SILE.call("font", { weight = 800, size = "15pt" }, content)
    end)
  end)

  self:registerCommand("book:subsectionfont", function (_, content)
    SILE.settings:temporarily(function ()
      SILE.call("font", { weight = 800, size = "12pt" }, content)
    end)
  end)

end

return class
