local outcounter = 1

local outputMarks = function ()
  local page = SILE.getFrame("page")
  SILE.outputter:drawRule(page:left() - 10, page:top(), -10, 0.5)
  SILE.outputter:drawRule(page:left(), page:top() - 10, 0.5, -10)
  SILE.outputter:drawRule(page:right() + 10, page:top(), 10, 0.5)
  SILE.outputter:drawRule(page:right(), page:top() - 10, 0.5, -10)
  SILE.outputter:drawRule(page:left() - 10, page:bottom(), -10, 0.5)
  SILE.outputter:drawRule(page:left(), page:bottom() + 10, 0.5, 10)
  SILE.outputter:drawRule(page:right() + 10, page:bottom(), 10, 0.5)
  SILE.outputter:drawRule(page:right(), page:bottom() + 10, 0.5, 10)

  SILE.call("hbox", {}, function ()
    SILE.settings:temporarily(function ()
      SILE.call("noindent")
      SILE.call("font", { size="6pt" })
      SILE.call("crop:header")
    end)
  end)
  local hbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil

  SILE.typesetter.frame.state.cursorX = page:left() + 10
  SILE.typesetter.frame.state.cursorY = page:top() - 13
  outcounter = outcounter + 1

  if hbox then
    for i = 1, #(hbox.value) do hbox.value[i]:outputYourself(SILE.typesetter, { ratio = 1 }) end
  end
end

local function reconstrainFrameset(fs)
  for n, f in pairs(fs) do
    if n ~= "page" then
      if f:isAbsoluteConstraint("right") then
        f.constraints.right = "left(page) + (" .. f.constraints.right .. ")"
      end
      if f:isAbsoluteConstraint("left") then
        f.constraints.left = "left(page) + (" .. f.constraints.left .. ")"
      end
      if f:isAbsoluteConstraint("top") then
        f.constraints.top = "top(page) + (" .. f.constraints.top .. ")"
      end
      if f:isAbsoluteConstraint("bottom") then
        f.constraints.bottom = "top(page) + (" .. f.constraints.bottom .. ")"
      end
      f:invalidate()
    end
  end
end

local function init (class, _)

  class:loadPackage("date")

end

local function registerCommands (class)

  SILE.registerCommand("crop:header", function (_, _)
    local info = SILE.masterFilename .. " - " .. class:date("%x %X") .. " -  " .. outcounter
    SILE.typesetter:typeset(info)
  end)

  SILE.registerCommand("crop:setup", function (options, _)
    local papersize = SU.required(options, "papersize", "setting up crop marks")
    local size = SILE.papersize(papersize)
    local oldsize = SILE.documentState.paperSize
    SILE.documentState.paperSize = size
    local offsetx = ( SILE.documentState.paperSize[1] - oldsize[1] ) /2
    local offsety = ( SILE.documentState.paperSize[2] - oldsize[2] ) /2
    local page = SILE.getFrame("page")
    page:constrain("right", page:right() + offsetx)
    page:constrain("left", offsetx)
    page:constrain("bottom", page:bottom() + offsety)
    page:constrain("top", offsety)
    if SILE.scratch.masters then
      for _, v in pairs(SILE.scratch.masters) do
        reconstrainFrameset(v.frames)
      end
    else
      reconstrainFrameset(SILE.documentState.documentClass.pageTemplate.frames)
    end
    if SILE.typesetter.frame then SILE.typesetter.frame:init() end
    local oldEndPage = SILE.documentState.documentClass.endPage
    SILE.documentState.documentClass.endPage = function (self)
      oldEndPage(self)
      outputMarks()
    end
  end)

end


return {
  init = init,
  registerCommands = registerCommands,
documentation = [[
\begin{document}
When preparing a document for printing, you may be asked by the printer
to add crop marks. This means that you need to output the document on
a slightly larger page size than your target paper and add printers
crop marks to show where the paper should be trimmed down to the correct
size. (This is to ensure that pages where the content “bleeds” off
the side of the page are correctly cut.)

This package provides the \autodoc:command{\crop:setup} command which should be
run early in your document file. It takes one argument, \autodoc:parameter{papersize},
which is the true target paper size. It place cropmarks around the
true page content.

It also adds a header at the top of the page with the filename, date
and output sheet number. You can customize this header by redefining
\autodoc:command{\crop:header}.
\end{document}
]]
}
