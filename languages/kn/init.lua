local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "kn"

function language:declareSettings ()
   -- TODO when our settings are properly scoped to their modules and we can push/pop states, switch this around to use
   -- the setting state interface so that it can undo multiple layers of settings
   local prev_script
   self.settings:registerHook("document.language", function (lang)
      local script = self.settings:get("font.script")
      if lang == "kn" and script ~= "Knda" then
         prev_script = script
         self.settings:set("font.script", "Knda")
      elseif lang ~= "kn" and prev_script ~= "Knda" then
         self.settings:set("font.script", prev_script)
         prev_script = nil
      end
   end)
end

return language
