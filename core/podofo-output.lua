-- This output package is deprecated and should only be used as an
-- example of how to create alternative output backends, in comparison
-- with the libtexpdf and debug backends.
local pdf = require("podofo")
local imagesize = SILE.require("imagesize")
if (not SILE.outputters) then SILE.outputters = {} end

local document
local page
local painter
local pagesize
local font
local lastfont

local podofoFaces = {}

local cursorX = 0
local cursorY = 0
SILE.outputters.podofo = {
  init = function()
    document = pdf.PdfMemDocument()
    pagesize = pdf.PdfRect()
    pagesize:SetWidth(SILE.documentState.paperSize[1])
    pagesize:SetHeight(SILE.documentState.paperSize[2])
    page = document:CreatePage(pagesize)
    painter = podofo.PdfPainter()
    painter:SetPage(page)
  end,
  newPage = function()
    painter:FinishPage()
    page = document:CreatePage(pagesize)
    painter:SetPage(page)
  end,
  finish = function()
    painter:FinishPage()
    document:Write(SILE.outputFilename)
  end,
  setColor = function (self, color)
    painter:SetColor(color.r, color.g, color.b)
  end,
  outputHbox = function (value)
    if not value.glyphNames then return end
    for i = 1,#(value.glyphNames) do
      painter:DrawGlyph(document,cursorX, cursorY, value.glyphNames[i])
    end
  end,
  setFont = function (options)
    if SILE.font._key(options) == lastkey then return end
    lastkey = SILE.font._key(options)
    if not podofoFaces[lastkey] then
      local ftface = SILE.font.cache(options, function () SU.error("Font should exist") end)
      print(ftface.filename)
      podofoFaces[lastkey] = document:CreateFont(ftface.face)
    end
    podofoFaces[lastkey]:SetFontSize(options.size)
    painter:SetFont(podofoFaces[lastkey])
    -- Podofo trashes the font, so we need to recompute.
    SILE.fontCache[lastkey] = nil
  end,
  drawPNG = function (src, x,y,w,h)
  end,
  imageSize = function (src)
    local box_width,box_height, err = imagesize.imgsize(src)imagesize.imgsize(src)
    if not box_width then
      SU.error(err.." loading image")
    end
    return box_width, box_height
  end,
  moveTo = function (x,y)
    cursorX = x
    cursorY = SILE.documentState.paperSize[2] - y
  end,
  rule = function (x,y,w,d)
    painter:Rectangle(x,SILE.documentState.paperSize[2] - y,w,d)
    painter:Close()
    painter:Fill()
  end,
  debugFrame = function (self,f)
  end,
  debugHbox = function(typesetter, hbox, scaledWidth)
    painter:SetColor(0.9,0.9,0.9)
    painter:SetStrokeWidth(0.5)
    painter:Rectangle(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY+(hbox.height), scaledWidth, hbox.height+hbox.depth)
    if (hbox.depth) then painter:Rectangle(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY+(hbox.height), scaledWidth, hbox.height); end
    painter:Stroke()
    painter:SetColor(0,0,0)
    --cr:move_to(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
  end
}

SILE.outputter = SILE.outputters.podofo
