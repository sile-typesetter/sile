if (not SILE.outputters) then SILE.outputters = {} end

local cursorX = 0
local cursorY = 0


local lastFont
local outfile
local writeline = function (...)
	local args = table.pack(...)
	for i = 1, #args do
		outfile:write(args[i])
		if i < #args then outfile:write("\t") end
	end
	outfile:write("\n")
end

local _deprecationCheck = function (caller)
  if type(caller) ~= "table" or type(caller.debugHbox) ~= "function" then
    SU.deprecated("SILE.outputter.*", "SILE.outputter:*", "0.10.9", "0.10.10")
  end
end

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

SILE.outputters.debug = {

  init = function (self)
    _deprecationCheck(self)
    outfile = io.open(SILE.outputFilename, "w+")
    writeline("Set paper size ", SILE.documentState.paperSize[1], SILE.documentState.paperSize[2])
    writeline("Begin page")
  end,

  newPage = function (self)
    _deprecationCheck(self)
    writeline("New page")
  end,

  finish = function (self)
    _deprecationCheck(self)
    if SILE.status.unsupported then writeline("UNSUPPORTED") end
    writeline("End page")
    writeline("Finish")
    outfile:close()
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
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    local oldx, oldy = self:getCursor()
    local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
    cursorX = offset.x + x
    cursorY = offset.y - y
    if _round(oldx) ~= _round(cursorX) then writeline("Mx ", _round(x)) end
    if _round(oldy) ~= _round(cursorY) then writeline("My ", _round(y)) end
  end,

  setColor = function (self, color)
    _deprecationCheck(self)
    if color.r then
      writeline("Set color", _round(color.r), _round(color.g), _round(color.b))
    elseif color.c then
      writeline("Set color (CMYK)", _round(color.c), _round(color.m), _round(color.y), _round(color.k))
    elseif color.l then
      writeline("Set color (grayscale)", _round(color.l))
    end
  end,

  pushColor = function (self, color)
    _deprecationCheck(self)
    if color.r then
      writeline("Push color", _round(color.r), _round(color.g), _round(color.b))
    elseif color.c then
      writeline("Push color (CMYK)", _round(color.c), _round(color.m), _round(color.y), _round(color.k))
    elseif color.l then
      writeline("Push color (grayscale)", _round(color.l))
    end
  end,

  popColor = function (self)
    _deprecationCheck(self)
    writeline("Pop color")
  end,

  outputHbox = function (_, _, _)
    SU.deprecated("SILE.outputter:outputHbox", "SILE.outputter:drawHbox", "0.10.10", "0.11.0")
  end,

  drawHbox = function (self, value, width)
    _deprecationCheck(self)
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
    writeline("T", buf, "(" .. tostring(value.text) .. ")")
  end,

  setFont = function (self, options)
    _deprecationCheck(self)
    local font = SILE.font._key(options)
    if lastFont ~= font then
      writeline("Set font ", font)
      lastFont = font
    end
  end,

  drawImage = function (self, src, x, y, width, height)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    height = SU.cast("number", height)
    writeline("Draw image", src, _round(x), _round(y), _round(width), _round(height))
  end,

  imageSize = function (_, _)
    SU.deprecated("SILE.outputter:imageSize", "SILE.outputter:getImageSize", "0.10.10", "0.11.0")
  end,

  getImageSize = function (self, src)
    _deprecationCheck(self)
    local pdf = require("justenoughlibtexpdf")
    local llx, lly, urx, ury = pdf.imagebbox(src)
    return (urx-llx), (ury-lly)
  end,

  drawSVG = function (self, figure, _, x, y, width, height, scalefactor)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    height = SU.cast("number", height)
    writeline("Draw SVG", _round(x), _round(y), _round(width), _round(height), figure, scalefactor)
  end,

  rule = function (_, _, _, _, _)
    SU.deprecated("SILE.outputter:rule", "SILE.outputter:drawRule", "0.10.10", "0.11.0")
  end,

  drawRule = function (self, x, y, width, depth)
    _deprecationCheck(self)
    x = SU.cast("number", x)
    y = SU.cast("number", y)
    width = SU.cast("number", width)
    depth = SU.cast("number", depth)
    writeline("Draw line", _round(x), _round(y), _round(width), _round(depth))
  end,

  debugFrame = function (self, _, _)
    _deprecationCheck(self)
  end,

  debugHbox = function (self, _, _, _)
    _deprecationCheck(self)
  end

}

SILE.outputter = SILE.outputters.debug

if not SILE.outputFilename and SILE.masterFilename then
  SILE.outputFilename = SILE.masterFilename..".debug"
end
