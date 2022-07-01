local base = require("outputters.base")

local cursorX = 0
local cursorY = 0

local outfile
local started = false

local text = pl.class(base)
text._name = "text"

-- The outputter init can't actually initialize output (as logical as it might
-- have seemed) because that requires a page size which we don't know yet.
-- function text:_init () end

function text:_ensureInit ()
  if not outfile then
    local fname = self:getOutputFilename("text")
    outfile = fname == "-" and io.stdout or io.open(fname, "w+")
  end
end

function text:_writeline (...)
  self:_ensureInit()
  local args = table.pack(...)
  for i=1, #args do
    outfile:write(args[i])
  end
end

function text:newPage ()
  self:_ensureInit()
  outfile:write("")
end

function text:finish ()
  self:_ensureInit()
  outfile:close()
end

function text.getCursor (_)
  return cursorX, cursorY
end

function text:setCursor (x, y, relative)
  self:_ensureInit()
  local bs = SILE.measurement("0.8bs"):tonumber()
  local spc = SILE.measurement("0.8spc"):tonumber()
  local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
  local newx, newy = offset.x + x, offset.y - y
  if started then
    if newx < cursorX then
        outfile:write("\n")
    elseif newy > cursorY then
      if newy - cursorY > bs then
        outfile:write("\n")
      else
        outfile:write("‫")
      end
    elseif newx > cursorX then
      if newx - cursorX > spc then
        outfile:write(" ")
      else
        outfile:write("‫")
      end
    end
  end
  cursorY = newy
  cursorX = newx
end

function text:drawHbox (value, width)
  self:_ensureInit()
  width = SU.cast("number", width)
  if not value.text then return end
  self:_writeline(value.text)
  if width > 0 then
    started = true
    cursorX = cursorX + width
  end
end

return text
