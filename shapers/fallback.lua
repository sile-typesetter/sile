local harfbuzz = require("shapers.harfbuzz")

local shaper = pl.class(harfbuzz)
shaper._name = "fallback"

local fallbackQueue = pl.class()

function fallbackQueue:_init (text, fallbacks)
   self.fallbacks = fallbacks
   self.runs = {
      {
         options = self:currentOptions(),
         offset = 0,
         start = 1,
         -- WARNING: shaper index is in bytes, not UTF8 aware character
         -- lengths so do *not* use luautf8.len() here
         stop = text:len(),
      },
   }
   self._fallbacks = fallbacks
   self.text = text
   self.pending = nil
end

function fallbackQueue:popFallback ()
   return table.remove(self.fallbacks, 1)
end

function fallbackQueue:popRun ()
   self:popFallback()
   return table.remove(self.runs, 1)
end

function fallbackQueue:currentOptions ()
   return self.fallbacks[1]
end

function fallbackQueue:nextFallback ()
   return self.fallbacks[2]
end

function fallbackQueue:currentRun ()
   return self.runs[1]
end

function fallbackQueue:currentText ()
   local run = self:currentRun()
   -- WARNING: shaper index is in bytes, not UTF8 aware character
   -- lengths so do *not* use luautf8.sub() here
   return self.text:sub(run.start, run.stop)
end

function fallbackQueue:addRun (offset, start)
   if not self.pending then
      SU.debug("font-fallback", function ()
         return ("New run pending for %s starting byte %s insert at %s"):format(self:currentText(), start, offset)
      end)
      local options = self:nextFallback()
      if not options then
         return false
      end
      options.size = SILE.types.measurement(options.size):tonumber()
      self.pending = {
         options = options,
         offset = offset,
         start = start,
      }
   end
   return true
end

function fallbackQueue:pushNextRun (stop)
   if self.pending then
      SU.debug("font-fallback", function ()
         return ("Push pending run for %s ending at %s"):format(self:currentText(), stop)
      end)
      self.pending.stop = stop
      table.insert(self.runs, self.pending)
      self.pending = nil
   end
end

local activeFallbacks = {}

function shaper:shapeToken (text, options)
   local items = {}
   local fallbackOptions = { options }
   for _, font in ipairs(activeFallbacks) do
      table.insert(fallbackOptions, pl.tablex.merge(options, font, true))
   end
   local shapeQueue = fallbackQueue(text, fallbackOptions)
   repeat -- iterate fallbacks
      SU.debug("font-fallback", function ()
         return ("Start fallback iteration for text '%s'"):format(text)
      end)
      local run = shapeQueue:currentRun()
      local face = run.options.family:len() > 0 and run.options.family or run.options.filename
      local chunk = shapeQueue:currentText()
      SU.debug("font-fallback", function ()
         return ("Try shaping chunk '%s' with '%s'"):format(chunk, face)
      end)
      local candidate_items = self._base.shapeToken(self, chunk, run.options)
      local _index
      for _, item in ipairs(candidate_items) do
         item.fontOptions = run.options
         if item.gid == 0 or item.name == ".null" or item.name == ".notdef" then
            SU.debug("font-fallback", function ()
               return ("Glyph %s not found in %s"):format(item.text, face)
            end)
            local newstart = run.start + item.index
            local pending = shapeQueue:addRun(run.offset, newstart)
            if not pending then
               SU.warn(([[
                  Glyph(s) '%s' not available in any fallback font

                  Run with '-d font-fallback' for more detail.
               ]]):format(item.text))
               run.offset = run.offset + 1
               table.insert(items, run.offset, item) -- output tofu if we're out of fallbacks
            end
         else
            SU.debug("font-fallback", function ()
               return ("Found glyph '%s' in '%s'"):format(item.text, face)
            end)
            shapeQueue:pushNextRun(run.start + item.index - 1) -- if notdef run pending, end it
            if item.index == _index then
               local previous = items[run.offset]
               while previous.next do
                  previous = previous.next
               end
               previous.next = item
            else
               _index = run.index
               run.offset = run.offset + 1
               table.insert(items, run.offset, item)
            end
         end
      end
      shapeQueue:pushNextRun(run.stop) -- if notdef run pending, end it
      shapeQueue:popRun()
   until not shapeQueue:currentRun()
   return items
end

function shaper:createNnodes (token, options)
   options.tracking = SILE.settings:get("shaper.tracking")
   local items, _ = self:shapeToken(token, options)
   if #items < 1 then
      return {}
   end
   -- TODO this shouldn't need a private interface to a different module type
   local language = SILE.typesetter:_cacheLanguage(options.language)
   local run = { [1] = { slice = {}, fontOptions = items[1].fontOptions, chunk = "" } }
   for i = 1, #items do
      if items[i].fontOptions ~= run[#run].fontOptions then
         run[#run + 1] = { slice = {}, chunk = "", fontOptions = items[i].fontOptions }
         if i < #items then
            run[#run].fontOptions = items[i].fontOptions
         end
      end
      run[#run].chunk = run[#run].chunk .. items[i].text
      run[#run].slice[#run[#run].slice + 1] = items[i]
   end
   local nodes = {}
   for i = 1, #run do
      options = run[i].fontOptions
      local nodemaker = language:nodemaker(options)
      SU.debug("font-fallback", "Shaping", run[i].chunk, "in", options.family)
      for node in nodemaker:iterator(run[i].slice, run[i].chunk) do
         nodes[#nodes + 1] = node
      end
   end
   SU.debug("font-fallback", nodes)
   return nodes
end

function shaper.clearFallbacks (_)
   activeFallbacks = {}
end

function shaper.addFallback (_, options)
   table.insert(activeFallbacks, options)
end

function shaper.removeFallback (_)
   table.remove(activeFallbacks)
end

function shaper.dumpFallbacks (_)
   return activeFallbacks
end

return shaper
