-- This output package is deprecated and should only be used as an
-- example of how to create alternative output backends, in comparison
-- with the libtexpdf and debug backends.
local pdf = require("podofo")
local imagesize = require("imagesize")
if (not SILE.outputters) then SILE.outputters = {} end

local cursorX = 0
local cursorY = 0

local document
local page
local painter
local pagesize
local lastkey

local podofoFaces = {}

local _deprecationCheck = function (caller)
  if type(caller) ~= "table" or type(caller.debugHbox) ~= "function" then
    SU.deprecated("SILE.outputter.*", "SILE.outputter:*", "0.10.9", "0.10.10")
  end
end

SILE.outputters.podofo = {

  init = function (self)
    _deprecationCheck(self)
    document = pdf.PdfMemDocument()
    pagesize = pdf.PdfRect()
    pagesize:SetWidth(SILE.documentState.paperSize[1])
    pagesize:SetHeight(SILE.documentState.paperSize[2])
    page = document:CreatePage(pagesize)
    painter = pdf.PdfPainter()
    painter:SetPage(page)
  end,

  newPage = function (self)
    _deprecationCheck(self)
    painter:FinishPage()
    page = document:CreatePage(pagesize)
    painter:SetPage(page)
  end,

  finish = function (self)
    _deprecationCheck(self)
    painter:FinishPage()
    document:Write(SILE.outputFilename)
  end,

  cursor = function (_)
    SU.deprecated("SILE.outputter:cursor", "SILE.outputter:getCursor", "0.10.10", "0.11.0")
  end,

  getCursor = function (self)
    _deprecationCheck(self)
    return cursorX, cursorY
  end,

  moveTo = function (_, _, _)
    SU.deprecated("SILE.outputter:moveTo", "SILE.outputter:setCursor", "0.10.10", "0.11.0")
  end,

  setCursor = function (self, x, y, relative)
    _deprecationCheck(self)
    local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
    cursorX = offset.x + x
    cursorY = offset.y + SILE.documentState.paperSize[2] - y
  end,

  setColor = function (self, color)
    _deprecationCheck(self)
    painter:SetColor(color.r, color.g, color.b)
  end,

  outputHbox = function (_, _, _)
    SU.deprecated("SILE.outputter:outputHbox", "SILE.outputter:drawHbox", "0.10.10", "0.11.0")
  end,

  drawHbox = function (self, value, _)
    _deprecationCheck(self)
    if not value.glyphNames then return end
    for i = 1, #(value.glyphNames) do
      painter:DrawGlyph(document, cursorX, cursorY, value.glyphNames[i])
    end
  end,

  setFont = function (self, options)
    _deprecationCheck(self)
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

  drawImage = function (self, _, _, _, _)
    _deprecationCheck(self)
  end,

  imageSize = function (_, _)
    SU.deprecated("SILE.outputter:imageSize", "SILE.outputter:getImageSize", "0.10.10", "0.11.0")
  end,

  getImageSize = function (self, src)
    _deprecationCheck(self)
    local box_width, box_height, err = imagesize.imgsize(src)
    if not box_width then
      SU.error(err.." loading image")
    end
    return box_width, box_height
  end,

  drawSVG = function (self, _, _, _, _)
    _deprecationCheck(self)
  end,

  rule = function (_, _, _, _, _)
    SU.deprecated("SILE.outputter:rule", "SILE.outputter:drawRule", "0.10.10", "0.11.0")
  end,

  drawRule = function (self, x, y, width, depth)
    _deprecationCheck(self)
    painter:Rectangle(x, SILE.documentState.paperSize[2] - y, width, depth)
    painter:Close()
    painter:Fill()
  end,

  debugFrame = function (self, _)
    _deprecationCheck(self)
  end,

  debugHbox = function (self, typesetter, hbox, scaledWidth)
    _deprecationCheck(self)
    painter:SetColor(0.9, 0.9, 0.9)
    painter:SetStrokeWidth(0.5)
    painter:Rectangle(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY+(hbox.height), scaledWidth, hbox.height+hbox.depth)
    if (hbox.depth) then painter:Rectangle(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY+(hbox.height), scaledWidth, hbox.height); end
    painter:Stroke()
    painter:SetColor(0, 0, 0)
    --cr:move_to(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
  end
}

SILE.outputter = SILE.outputters.podofo
