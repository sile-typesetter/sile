local book = SILE.require("book", "classes")
local jbook = book { id = "jbook", base = book }

SILE.call("bidi-off")

jbook:declareOption("layout", "yoko")
jbook:loadPackage("masters")

function jbook:init()
  jbook:loadPackage("twoside", { oddPageMaster = "right", evenPageMaster = "left" })
  jbook:mirrorMaster("right", "left")
  jbook:loadPackage("hanmenkyoshi")
  jbook:defineMaster({ id = "right", firstContentFrame = "content",
    frames = {
      runningHead = {left = "left(content) + 9pt", right = "right(content) - 9pt", height = "20pt", bottom = "top(content)-9pt" },
      content = self:declareHanmenFrame( "content", {
        left = "8.3%pw", top = "12%ph",
        gridsize = 10, linegap = 7, linelength = 40,
        linecount = 35,
        tate = self.options.layout() == "tate"
      }),
      folio = {left = "left(content)", right = "right(content)", top = "bottom(footnotes)+3%ph",bottom = "bottom(footnotes)+5%ph" },
      footnotes = { left="left(content)", right = "right(content)", height = "0", bottom="83.3%ph"}
    }
  })
  book:loadPackage("twoside", { oddPageMaster = "right", evenPageMaster = "left" })
  book:mirrorMaster("right", "left")
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames.content
  return book.init(self)
end

jbook.registerCommands = function(_)
  book:registerCommands()
  SILE.call("language", { main = "ja" })
end

SILE.settings.set("document.parindent",SILE.nodefactory.glue("10pt"))
return jbook
