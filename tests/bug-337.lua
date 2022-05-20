local book = require("classes.book")
SILE.require("packages.cropmarks")

book:loadPackage("masters")
book:defineMaster({
    id = "right",
    firstContentFrame = "content",
    frames = {
      content = {
        left = "0",
        right = "100%pw",
        top = "0",
        bottom = "top(folio)"
      },
      folio = {
        left = "left(content)",
        right = "right(content)",
        height = "10pt",
        bottom = "100%ph"
      }
    }
  })
book:defineMaster({
    id = "left",
    firstContentFrame = "content",
    frames = {}
  })
book:loadPackage("twoside", { oddPageMaster = "right", evenPageMaster = "left" })
book:mirrorMaster("right", "left")

SILE.call("switch-master-one-page", { id = "right" })

SILE.registerCommand("printPageInPoints", function()
  local w = SILE.measurement("100%pw"):tonumber()
  local h = SILE.measurement("100%ph"):tonumber()
  SILE.typesetter:typeset(("%.0fpt × %.0fpt"):format(w, h))
end)
