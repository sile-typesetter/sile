local base = require("outputters.base")

-- This output package is deprecated and should only be used as an
-- example of how to create alternative output backends, in comparison
-- with the libtexpdf and debug backends.
local pdf = require("podofo")
local imagesize = require("imagesize")

local cursorX = 0
local cursorY = 0

local document
local page
local painter
local pagesize
local lastkey

local podofoFaces = {}

local outputter = pl.class(base)
outputter._name = "podofo"
outputter.extension = "pdf"

function outputter._init (_)
   document = pdf.PdfMemDocument()
   pagesize = pdf.PdfRect()
   pagesize:SetWidth(SILE.documentState.paperSize[1])
   pagesize:SetHeight(SILE.documentState.paperSize[2])
   page = document:CreatePage(pagesize)
   painter = pdf.PdfPainter()
   painter:SetPage(page)
end

function outputter.newPage (_)
   painter:FinishPage()
   page = document:CreatePage(pagesize)
   painter:SetPage(page)
end

function outputter:finish ()
   painter:FinishPage()
   local fname = self:getOutputFilename()
   document:Write(fname == "-" and "/dev/stdout" or fname)
end

function outputter.getCursor (_)
   return cursorX, cursorY
end

function outputter.setCursor (_, x, y, relative)
   local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
   cursorX = offset.x + x
   cursorY = offset.y + SILE.documentState.paperSize[2] - y
end

function outputter.setColor (_, color)
   painter:SetColor(color.r, color.g, color.b)
end

function outputter:drawHbox (value, _)
   local x, y = self:getCursor()
   if not value.glyphNames then
      return
   end
   for i = 1, #value.glyphNames do
      painter:DrawGlyph(document, x, y, value.glyphNames[i])
   end
end

function outputter.setFont (_, options)
   if SILE.font._key(options) == lastkey then
      return
   end
   lastkey = SILE.font._key(options)
   if not podofoFaces[lastkey] then
      local ftface = SILE.font.cache(options, function ()
         SU.error("Font should exist")
      end)
      print(ftface.filename)
      podofoFaces[lastkey] = document:CreateFont(ftface.face)
   end
   podofoFaces[lastkey]:SetFontSize(options.size)
   painter:SetFont(podofoFaces[lastkey])
   -- Podofo trashes the font, so we need to recompute.
   SILE.fontCache[lastkey] = nil
end

function outputter.getImageSize (_, src)
   local box_width, box_height, err = imagesize.imgsize(src)
   if not box_width then
      SU.error(err .. " loading image")
   end
   return box_width, box_height
end

function outputter.drawRule (_, x, y, width, depth)
   painter:Rectangle(x, SILE.documentState.paperSize[2] - y, width, depth)
   painter:Close()
   painter:Fill()
end

function outputter:debugHbox (hbox, scaledWidth)
   painter:SetColor(0.9, 0.9, 0.9)
   painter:SetStrokeWidth(0.5)
   local x, y = self:getCursor()
   painter:Rectangle(x, y + hbox.height, scaledWidth, hbox.height + hbox.depth)
   if hbox.depth then
      painter:Rectangle(x, y + hbox.height, scaledWidth, hbox.height)
   end
   painter:Stroke()
   painter:SetColor(0, 0, 0)
   --cr:move_to(x, y)
end

return outputter
