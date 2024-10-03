--- SILE outputter class.
-- @interfaces outputters

local outputter = pl.class()
outputter.type = "outputter"
outputter._name = "base"

function outputter:_init ()
   self.hooks = {}
   return self
end

function outputter:registerHook (category, func)
   if not self.hooks[category] then
      self.hooks[category] = {}
   end
   table.insert(self.hooks[category], func)
end

function outputter:runHooks (category, data)
   if not self.hooks[category] then
      return nil
   end
   for _, func in ipairs(self.hooks[category]) do
      data = func(self, data)
   end
   return data
end

function outputter.preProcess (_, ast)
   return ast
end

function outputter.newPage () end

function outputter:finish ()
   self:runHooks("prefinish")
end

function outputter.getCursor () end

function outputter.setCursor (_, _, _, _) end

function outputter.setColor () end

function outputter.pushColor () end

function outputter.popColor () end

function outputter.drawHbox (_, _, _) end

function outputter.setFont (_, _) end

function outputter.drawImage (_, _, _, _, _, _) end

function outputter.getImageSize (_, _) end

function outputter.drawSVG () end

function outputter.drawRule (_, _, _, _, _) end

function outputter.debugFrame (_, _, _) end

function outputter.debugHbox (_, _, _) end

function outputter.setLinkAnchor (_, _, _) end -- Unstable API

function outputter.beginLink (_, _, _) end -- Unstable API

function outputter.endLink (_, _, _, _, _, _, _) end -- Unstable API

function outputter.setMetadata (_, _, _) end

function outputter.setBookmark (_, _, _) end

function outputter.drawRaw (_) end

function outputter:getOutputFilename ()
   local fname
   if SILE.outputFilename then
      fname = SILE.outputFilename
   elseif SILE.input.filenames[1] then
      fname = pl.path.splitext(SILE.input.filenames[1])
      if self.extension then
         fname = fname .. "." .. self.extension
      end
   end
   if not fname then
      SU.error("Cannot guess output filename without an input name")
   end
   return fname
end

return outputter
