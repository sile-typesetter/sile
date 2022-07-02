local base = require("packages.base")

local package = pl.class(base)
package._name = "cropmarks"

local outcounter = 1

local function outputMarks ()
  local page = SILE.getFrame("page")

  -- Ensure the crop marks stay outside the bleed area
  local offset = math.max(10, SILE.documentState.bleed / 2)

  SILE.outputter:drawRule(page:left() - offset, page:top(), -10, 0.5)
  SILE.outputter:drawRule(page:left(), page:top() - offset, 0.5, -10)
  SILE.outputter:drawRule(page:right() + offset, page:top(), 10, 0.5)
  SILE.outputter:drawRule(page:right(), page:top() - offset, 0.5, -10)
  SILE.outputter:drawRule(page:left() - offset, page:bottom(), -10, 0.5)
  SILE.outputter:drawRule(page:left(), page:bottom() + offset, 0.5, 10)
  SILE.outputter:drawRule(page:right() + offset, page:bottom(), 10, 0.5)
  SILE.outputter:drawRule(page:right(), page:bottom() + offset, 0.5, 10)

  SILE.call("hbox", {}, function ()
    SILE.settings:temporarily(function ()
      SILE.call("noindent")
      SILE.call("font", { size="6pt" })
      if SILE.Commands["crop:header"] then
        -- If user redefined this command, still use it with a warning...
        SU.deprecated(" crop:header", "cropmarks:header", "0.14.0", "0.16.0")
        SILE.call("crop:header")
      else
        SILE.call("cropmarks:header")
      end
    end)
  end)
  local hbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil

  SILE.typesetter.frame.state.cursorX = page:left() + offset
  SILE.typesetter.frame.state.cursorY = page:top() - offset - 3
  outcounter = outcounter + 1

  if hbox then
    for i = 1, #(hbox.value) do hbox.value[i]:outputYourself(SILE.typesetter, { ratio = 1 }) end
  end
end

function package:_init ()
  base._init(self)
  self.class:loadPackage("date")
end

function package:registerCommands ()

  self:registerCommand("cropmarks:header", function (_, _)
    local info = SILE.masterFilename .. " - " .. self.class:date("%x %X") .. " -  " .. outcounter
    SILE.typesetter:typeset(info)
  end)

  self:registerCommand("cropmarks:setup", function (options, _)
    if options.papersize then
      SU.deprecated("papersize parameter of crop(marks):setup", "papersize, pagesize and bleed class options", "0.14.0", "0.16.0")
    end
    local oldEndPage = SILE.documentState.documentClass.endPage
    SILE.documentState.documentClass.endPage = function (self_)
      oldEndPage(self_)
      outputMarks()
    end
  end)

  self:registerCommand("crop:setup", function (options, _)
    SU.deprecated("crop:setup", "cropmarks:setup", "0.14.0", "0.16.0")
    SILE.call("cropmarks:setup", options)
  end)

end

package.documentation = [[
\begin{document}
When preparing a document for printing, you may be asked by the printer
to output the document on a larger page size than your target paper
and to also add crop marks showing where the paper sheet should be
trimmed down to the correct size.
Actual paper size, true page content area and bleed/trim area can all
be set via class options.

This package provides the \autodoc:command{\cropmarks:setup} command which
should be run early in your document file. It places crop marks around the
true page content. The crop marks are guaranteed to stay outside the
bleed/trim area, when defined.

It also adds a header at the top of the page with the filename, date
and output sheet number. You can customize this header by redefining
\autodoc:command{\cropmarks:header}.
\end{document}
]]

return package
