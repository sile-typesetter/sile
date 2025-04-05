--- Globally available Lua loader functions.
-- @module loaders

local loadkit = require("loadkit")

-- Allows loading FTL resources directly with require(). Guesses the locale based on SILE's default resource paths,
-- otherwise if it can't guess it Loads assets directly into the *current* fluent bundle.
loadkit.register("ftl", function (file, spec)
   local contents = assert(file:read("*a"))
   file:close()
   local origLang = fluent:get_locale()
   local lang = spec:match("^languages%.([^%.]+)%.messages$") or SILE.settings:get("document.language")
   fluent:set_locale(lang)
   local loaded = assert(fluent:add_messages(contents))
   fluent:set_locale(origLang)
   return assert(loaded)
end)
