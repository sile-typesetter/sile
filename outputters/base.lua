--- SILE outputter class.
-- @interfaces outputters

local outputter = pl.class()
outputter.type = "outputter"
outputter._name = "base"

--- Whether this outputter can be used with SyncTeX output.
-- Outputters able to report the geometry of the boxes they output should set
-- this to true. See `SILE.synctex`.
-- @tfield boolean supportsSynctex
outputter.supportsSynctex = false

function outputter:_init ()
   SU._avoid_base_class_use(self)
   self.hooks = {}
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

function outputter:newPage () end

function outputter:abort ()
   return self:finish() -- unless otherwise defined
end

function outputter:finish ()
   self:runHooks("prefinish")
end

function outputter:getCursor () end

function outputter:setCursor (_, _, _) end

function outputter:setColor () end

function outputter:pushColor () end

function outputter:popColor () end

function outputter:drawHbox (_, _) end

function outputter:setFont (_) end

function outputter:drawImage (_, _, _, _, _) end

function outputter:getImageSize (_) end

function outputter:drawSVG () end

function outputter:drawRule (_, _, _, _) end

function outputter:debugFrame (_, _) end

function outputter:debugHbox (_, _) end

function outputter:setLinkAnchor (_, _) end -- Unstable API

function outputter:beginLink (_, _) end -- Unstable API

function outputter:endLink (_, _, _, _, _, _) end -- Unstable API

function outputter:setMetadata (_, _) end

function outputter:setBookmark (_, _) end

function outputter:drawRaw () end

--- Convert a point to the coordinate system used by SyncTeX output.
-- SyncTeX coordinates have their origin at the top left corner of the *sheet*
-- (whereas SILE positions boxes relative to the top left corner of the
-- *paper*, which may differ when the paper is centered on a larger sheet) and
-- are expressed in points.
-- @tparam number x The horizontal position, in points.
-- @tparam number y The vertical position, in points.
-- @treturn number The horizontal position for SyncTeX, in points.
-- @treturn number The vertical position for SyncTeX, in points.
function outputter:synctexCoordinates (x, y)
   return x, y
end

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
