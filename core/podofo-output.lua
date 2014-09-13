local pdf = require("podofo");
if (not SILE.outputters) then SILE.outputters = {} end

local document
local page
local painter
local pagesize
local font

local cursorX = 0
local cursorY = 0
SILE.outputters.podofo = {
  init = function()
    document = pdf.PdfStreamedDocument(SILE.outputFilename)
    pagesize = pdf.PdfRect()
    pagesize:setWidth(SILE.documentState.paperSize[1])
    pagesize:setHeight(SILE.documentState.paperSize[2])
    page = document:CreatePage(pagesize)
    painter = podofo.PdfPainter();
    painter:SetPage(page)
  end,
  newPage = function()
    painter:FinishPage()
    page = document:CreatePage(pagesize)
    painter:SetPage(page)
  end,
  finish = function()
    painter:FinishPage()
    document:Close()
  end,
  setColor = function (self, color)
    painter:SetColor(color.r, color.g, color.b)
  end,
  showGlyphString = function(f,pgs, options)
    sgs(cr, f,pgs)
  end,
  setFont = function (options)
    font = document:CreateFont(options.font)
    font:setFontSize(options.size)
    -- ...
  end,
  showText = function(t)
    cr:show_text(t)
  end,
  drawPNG = function (src, x,y,w,h)
  end,
  moveTo = function (x,y)
    cursorX = 0
    cursorY = 0
  end,
  rule = function (x,y,w,d)
    painter:Rectangle(x,y,w,d)
    painter:Close()
    painter:Fill()
  end,
  debugFrame = function (self,f)
  end,
  debugHbox = function(typesetter, hbox, scaledWidth)

  end
}

SILE.outputter = SILE.outputters.podofo