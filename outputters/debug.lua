local base = require("outputters.base")

local cursorX = 0
local cursorY = 0

local started = false

local lastFont
local outfile

local function _round (input)
  -- LuaJIT 2.1 betas (and inheritors such as OpenResty and Moonjit) are biased
  -- towards rounding 0.5 up to 1, all other Lua interpreters are biased
  -- towards rounding such floating point numbers down.  This hack shaves off
  -- just enough to fix the bias so our test suite works across interpreters.
  -- Note that even a true rounding function here will fail because the bias is
  -- inherent to the floating point type. Also note we are erroring in favor of
  -- the *less* common option beacuse the LuaJIT VMS are hopelessly broken
  -- whereas normal LUA VMs can be cooerced.
  if input > 0 then input = input + .00000000000001 end
  if input < 0 then input = input - .00000000000001 end
  return string.format("%.4f", input)
end

local outputter = pl.class(base)
outputter._name = "debug"

-- The outputter init can't actually initialize output (as logical as it might
-- have seemed) because that requires a page size which we don't know yet.
-- function outputter:_init () end

function outputter:_ensureInit ()
  if not started then
    started = true -- keep this before self:_writeline or it will be a race condition!
    local fname = self:getOutputFilename("debug")
    outfile = fname == "-" and io.stdout or io.open(fname, "w+")
    self:_writeline("Set paper size ", SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
    self:_writeline("Begin page")
  end
end

function outputter:_writeline (...)
  self:_ensureInit()
	local args = table.pack(...)
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
    self:_writeline("Set color", _round(color.r), _round(color.g), _round(color.b))
  elseif color.c then
    self:_writeline("Set color", _round(color.c), _round(color.m), _round(color.y), _round(color.k))
  elseif color.l then
    self:_writeline("Set color", _round(color.l))
  end
end

function outputter:pushColor (color)
  if color.r then
    self:_writeline("Push color", _round(color.r), _round(color.g), _round(color.b))
  elseif color.c then
    self:_writeline("Push color (CMYK)", _round(color.c), _round(color.m), _round(color.y), _round(color.k))
  elseif color.l then
    self:_writeline("Push color (grayscale)", _round(color.l))
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

function outputter.getImageSize (_, src)
  local pdf = require("justenoughlibtexpdf")
  local llx, lly, urx, ury = pdf.imagebbox(src)
  return (urx-llx), (ury-lly)
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

return outputter
