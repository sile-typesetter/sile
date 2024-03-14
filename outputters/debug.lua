local base = require("outputters.base")

local cursorX = 0
local cursorY = 0

local started = false

local lastFont
local outfile

local _round = SU.debug_round

local outputter = pl.class(base)
outputter._name = "debug"
outputter.extension = "debug"

-- The outputter init can't actually initialize output (as logical as it might
-- have seemed) because that requires a page size which we don't know yet.
-- function outputter:_init () end

function outputter:_ensureInit ()
  if not started then
    started = true -- keep this before self:_writeline or it will be a race condition!
    local fname = self:getOutputFilename()
    outfile = fname == "-" and io.stdout or io.open(fname, "w+")
    if SILE.documentState.paperSize then
      self:_writeline("Set paper size ", SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
    end
    self:_writeline("Begin page")
  end
end

function outputter:_writeline (...)
  self:_ensureInit()
  local args = pl.utils.pack(...)
  for i = 1, #args do
    outfile:write(args[i])
    if i < #args then outfile:write("\t") end
  end
  outfile:write("\n")
end

function outputter:newPage ()
  self:_writeline("New page")
end

function outputter:finish ()
  if SILE.status.unsupported then self:_writeline("UNSUPPORTED") end
  self:_writeline("End page")
  self:runHooks("prefinish")
  self:_writeline("Finish")
  outfile:close()
end

function outputter.getCursor (_)
  return cursorX, cursorY
end

function outputter:setCursor (x, y, relative)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  local oldx, oldy = self:getCursor()
  local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
  cursorX = offset.x + x
  cursorY = offset.y - y
  if _round(oldx) ~= _round(cursorX) then self:_writeline("Mx ", _round(x)) end
  if _round(oldy) ~= _round(cursorY) then self:_writeline("My ", _round(y)) end
end

function outputter:setColor (color)
  if color.r then
    self:_writeline("Set color", tostring(color))
  elseif color.c then
    self:_writeline("Set color", tostring(color))
  elseif color.l then
    self:_writeline("Set color", tostring(color))
  end
end

function outputter:pushColor (color)
  if color.r then
    self:_writeline("Push color", tostring(color))
  elseif color.c then
    self:_writeline("Push color (CMYK)", tostring(color))
  elseif color.l then
    self:_writeline("Push color (grayscale)", tostring(color))
  end
end

function outputter:popColor ()
  self:_writeline("Pop color")
end

function outputter:drawHbox (value, width)
  if not value.glyphString then return end
  width = SU.cast("number", width)
  local buf
  if value.complex then
    local cluster = {}
    for i = 1, #value.items do
      local item = value.items[i]
      cluster[#cluster+1] = item.gid
      -- For the sake of terseness we're only dumping non-zero values
      if item.glyphAdvance ~= 0 then cluster[#cluster+1] = "a=".._round(item.glyphAdvance) end
      if item.x_offset then cluster[#cluster+1] = "x=".._round(item.x_offset) end
      if item.y_offset then cluster[#cluster+1] = "y=".._round(item.y_offset) end
      self:setCursor(item.width, 0, true)
    end
    buf = table.concat(cluster, " ")
  else
    buf = table.concat(value.glyphString, " ") .. " w=" .. _round(width)
  end
  self:_writeline("T", buf, "(" .. tostring(value.text) .. ")")
end

function outputter:setFont (options)
  local font = SILE.font._key(options)
  if lastFont ~= font then
    self:_writeline("Set font ", font)
    lastFont = font
  end
end

function outputter:drawImage (src, x, y, width, height)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  width = SU.cast("number", width)
  height = SU.cast("number", height)
  self:_writeline("Draw image", src, _round(x), _round(y), _round(width), _round(height))
end

function outputter.getImageSize (_, src, pageno)
  local pdf = require("justenoughlibtexpdf")
  local llx, lly, urx, ury, xresol, yresol = pdf.imagebbox(src, pageno)
  return (urx-llx), (ury-lly), xresol, yresol
end

function outputter:drawSVG (figure, _, x, y, width, height, scalefactor)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  width = SU.cast("number", width)
  height = SU.cast("number", height)
  self:_writeline("Draw SVG", _round(x), _round(y), _round(width), _round(height), figure, scalefactor)
end

function outputter:drawRule (x, y, width, depth)
  x = SU.cast("number", x)
  y = SU.cast("number", y)
  width = SU.cast("number", width)
  depth = SU.cast("number", depth)
  self:_writeline("Draw line", _round(x), _round(y), _round(width), _round(depth))
end

function outputter:setLinkAnchor (name, x, y)
  self:_writeline("Setting link anchor", name, x, y)
end

function outputter:beginLink (dest, opts)
   self:_writeline("Begining a link", dest, opts)
end

function outputter:endLink(dest, opts, x0, y0, x1, y1)
   self:_writeline("Ending a link", dest, opts, x0, y0, x1, y1)
end

function outputter:setBookmark (dest, title, level)
   self:_writeline("Setting bookmark", dest, title, level)
end

function outputter:setMetadata (key, value)
   self:_writeline("Set metadata", key, value)
end

function outputter:drawRaw (literal)
   self:_writeline("Draw raw", literal)
end

return outputter
