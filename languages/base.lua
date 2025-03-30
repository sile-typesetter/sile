--- SILE language class.
-- @interfaces languages

local language = pl.class()
language.type = "language"
language._name = "base"

local loadkit = require("loadkit")
local setenv = require("rusile").setenv

-- Allows loading FTL resources directly with require(). Guesses the locale based on SILE's default resource paths,
-- otherwise if it can't guess it Loads assets directly into the *current* fluent bundle.
local require_ftl = loadkit.make_loader("ftl", function (file)
   local contents = assert(file:read("*a"))
   file:close()
   return assert(fluent:add_messages(contents))
end)

function language:_init (typesetter)
   self.typesetter = typesetter
   self:_declareBaseSettings()
   self:declareSettings()
   self:_registerBaseCommands()
   self:registerCommands()
   self:loadMessages()
   self:setupNodeMaker()
   self:setupHyphenator()
end

function language:_post_init ()
   SILE.settings:registerHook("document.language", function (lang)
      self.typesetter:switchLanguage(lang)
   end)
end

-- TODO: reconsider naming of 'setup' and 'nodemaker'
function language:setupNodeMaker ()
   -- TODO should this be an instance of a constructor? inconsistent with typesetter/language/class/etc.
   self.nodemaker = require("languages.base-nodemaker")
end

function language:setupHyphenator ()
   -- TODO should this be an constructor instead of an instance? inconsistent with typesetter/language/class/etc.
   self.hyphenator = require("languages.base-hyphenator")(self)
end

function language:activate ()
   local lang = self:_getLegacyCode()
   fluent:set_locale(lang)
   os.setlocale(lang)
   setenv("LANG", lang)
end

function language:_getLegacyCode ()
   return self._name
end

function language:loadMessages ()
   local lang = self:_getLegacyCode()
   local ftlresource = string.format("languages.%s.messages", lang)
   SU.debug("fluent", "Loading FTL resource", ftlresource, "into locale", lang)
   -- This needs to be set so that we load localizations into the right bundle,
   -- but this breaks the sync enabled by the hook in the document.language
   -- setting, so we want to set it back when we're done.
   local original_lang = fluent:get_locale()
   fluent:set_locale(lang)
   local gotftl, ftl = pcall(require_ftl, ftlresource)
   if not gotftl then
      SU.warn(
         ("Unable to load localized strings (e.g. table of contents header text) for %s: %s"):format(
            lang,
            ftl:gsub(":.*", "")
         )
      )
   end
   fluent:set_locale(original_lang)
end

function language._declareBaseSettings (_)
   SILE.settings:declare({
      parameter = "document.language",
      type = "string",
      default = "en",
      help = "Locale for localized language support",
   })
   SILE.settings:declare({
      parameter = "languages.fixedNbsp",
      type = "boolean",
      default = false,
      help = "Whether to treat U+00A0 (NO-BREAK SPACE) as a fixed-width space",
   })
end

function language.declareSettings (_) end

function language.registerCommands (_) end

function language:_registerBaseCommands ()
   self:registerCommand("language", function (options, content)
      local main = SU.required(options, "main", "language setting")
      SILE.languageSupport.loadLanguage(main)
      if content[1] then
         SILE.settings:temporarily(function ()
            SILE.settings:set("document.language", main)
            SILE.process(content)
         end)
      else
         SILE.settings:set("document.language", main)
      end
   end, nil, nil, true)

   self:registerCommand("fluent", function (options, content)
      local key = content[1]
      local locale = options.locale or SILE.settings:get("document.language")
      local original_locale = fluent:get_locale()
      fluent:set_locale(locale)
      SU.debug("fluent", "Looking for", key, "in", locale)
      local entry
      if key then
         entry = fluent:get_message(key)
      else
         SU.warn("Fluent localization function called without passing a valid message id")
      end
      local message
      if entry then
         message = entry:format(options)
      else
         SU.warn(string.format("No localized message for %s found in locale %s", key, locale))
         fluent:set_locale("und")
         entry = fluent:get_message(key)
         if entry then
            message = entry:format(options)
         end
      end
      fluent:set_locale(original_locale)
      SILE.processString(("<sile>%s</sile>"):format(message), "xml")
   end, nil, nil, true)

   self:registerCommand("ftl", function (options, content)
      local original_locale = fluent:get_locale()
      local locale = options.locale or SILE.settings:get("document.language")
      SU.debug("fluent", "Loading message(s) into locale", locale)
      fluent:set_locale(locale)
      if options.src then
         fluent:load_file(options.src, locale)
      elseif SU.ast.hasContent(content) then
         local input = content[1]
         fluent:add_messages(input, locale)
      end
      fluent:set_locale(original_locale)
   end, nil, nil, true)
end

function language.registerCommand (_, name, func, help, pack)
   SILE.Commands[name] = func
   if not pack then
      local where = debug.getinfo(2).source
      pack = where:match("(%w+).lua")
   end
   --if not help and not pack:match(".sil") then SU.error("Could not define command '"..name.."' (in package "..pack..") - no help text" ) end
   SILE.Help[name] = {
      description = help,
      where = pack,
   }
end

return language
