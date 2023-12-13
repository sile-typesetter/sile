local base = require("packages.base")

local package = pl.class(base)
package._name = "cropmarks"

local outcounter = 1

local function outputMarks ()
  local page = SILE.getFrame("page")
  -- Length of crop mark bars
  local cropsz = 20
  -- Ensure the crop marks stay outside the bleed area
  local offset = math.max(10, SILE.documentState.bleed / 2)

  SILE.outputter:drawRule(page:left() - offset, page:top(), -cropsz, 0.5)
  SILE.outputter:drawRule(page:left(), page:top() - offset, 0.5, -cropsz)
  SILE.outputter:drawRule(page:right() + offset, page:top(), cropsz, 0.5)
  SILE.outputter:drawRule(page:right(), page:top() - offset, 0.5, -cropsz)
  SILE.outputter:drawRule(page:left() - offset, page:bottom(), -cropsz, 0.5)
  SILE.outputter:drawRule(page:left() , page:bottom() + offset, 0.5, cropsz)
  SILE.outputter:drawRule(page:right() + offset, page:bottom(), cropsz, 0.5)
  SILE.outputter:drawRule(page:right(), page:bottom() + offset, 0.5, cropsz)

  local hbox, hlist = SILE.typesetter:makeHbox(function ()
    SILE.settings:temporarily(function ()
      SILE.call("noindent")
      SILE.call("font", { size="6pt" })
      if SILE.Commands["crop:header"] then
        -- Deprecation shim:
        -- If user redefined this command, still use it with a warning...
        SU.deprecated("crop:header", "cropmarks:header", "0.15.0", "0.16.0")
        SILE.call("crop:header")
      else
        SILE.call("cropmarks:header")
      end
    end)
  end)
  if #hlist > 0 then
    SU.error("Migrating content is forbidden in crop header")
  end

  SILE.typesetter.frame.state.cursorX = page:left() + offset
  SILE.typesetter.frame.state.cursorY = page:top() - offset - 4
  outcounter = outcounter + 1

  if hbox then
    for i = 1, #(hbox.value) do
      hbox.value[i]:outputYourself(SILE.typesetter, { ratio = 1 })
    end
  end
end

function package:_init ()
  base._init(self)
  self:loadPackage("date")
end

function package:registerCommands ()

  self:registerCommand("cropmarks:header", function (_, _)
    local info = SILE.input.filenames[1]
       .. " - "
       .. self.class.packages.date:date({ format = "%x %X" })
       .. " - " .. outcounter
    SILE.typesetter:typeset(info)
  end)

  self:registerCommand("cropmarks:setup", function (_, _)
    self.class:registerHook("endpage", outputMarks)
  end)

  self:registerCommand("crop:setup", function (_, _)
    SU.deprecated("crop:setup", "cropmarks:setup", "0.15.10", "0.17.0")
    SILE.call("cropmarks:setup")
  end)
end

package.documentation = [[
\begin{document}
When preparing a document for printing, you may be asked by the printer add crop marks.
This means that you need to output the document on a slightly larger page size than your target paper and add crop marks to show where the paper sheet should be trimmed down to the correct size.

Actual paper size, true page content area and bleed/trim area can all be set via class options.

This package provides the \autodoc:command{\cropmarks:setup} command which should be run early in your document file.
It places crop marks around the true page content.
The crop marks are guaranteed to stay outside the bleed/trim area, when defined.
It also adds a header at the top of the page with the filename, date and output sheet number.
You can customize this header by redefining \autodoc:command{\cropmarks:header}.
\end{document}
]]

return package
