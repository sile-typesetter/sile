local base = require("outputters.base")

local cursorX = 0
local cursorY = 0

local outfile
local started = false

local outputter = pl.class(base)
outputter._name = "text"
outputter.extension = "txt"

-- The outputter init can't actually initialize output (as logical as it might
-- have seemed) because that requires a page size which we don't know yet.
-- function outputter:_init () end

function outputter:_ensureInit ()
   if not started then
      started = true
      local fname = self:getOutputFilename()
      outfile = fname == "-" and io.stdout or io.open(fname, "w+")
   end
end

function outputter:_writeline (...)
   self:_ensureInit()
   local args = pl.utils.pack(...)
   for i = 1, #args do
      outfile:write(args[i])
   end
end

function outputter:newPage ()
   self:_ensureInit()
   outfile:write("")
end

function outputter.abort ()
   if started then
      outfile:close()
      started = false
   end
end
function outputter:finish ()
   self:_ensureInit()
   self:runHooks("prefinish")
   outfile:close()
   started = false
end

function outputter.getCursor (_)
   return cursorX, cursorY
end

function outputter:setCursor (x, y, relative)
   self:_ensureInit()
   local bs = SILE.types.measurement("0.8bs"):tonumber()
   local spc = SILE.types.measurement("0.8spc"):tonumber()
   local offset = relative and { x = cursorX, y = cursorY } or { x = 0, y = 0 }
   local newx, newy = offset.x + x, offset.y - y
   if started then
      if newx < cursorX then
         outfile:write("\n")
      elseif newy > cursorY then
         if newy - cursorY > bs then
            outfile:write("\n")
         else
            outfile:write("\u{202b}")
         end
      elseif newx > cursorX then
         if newx:tonumber() - cursorX:tonumber() > spc then
            outfile:write(" ")
         else
            outfile:write("\u{202b}")
         end
      end
   end
   cursorY = newy
   cursorX = newx
end

function outputter:drawHbox (value, width)
   self:_ensureInit()
   width = SU.cast("number", width)
   if not value.text then
      return
   end
   self:_writeline(value.text)
   if width > 0 then
      cursorX = cursorX + width
   end
end

function outputter:drawRaw (literal)
   self:_ensureInit()
   outfile:write(literal)
end

return outputter
