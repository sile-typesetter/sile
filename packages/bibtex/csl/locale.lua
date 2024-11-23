--- Reader for CSL 1.0.2 locale files
--
-- @copyright License: MIT (c) 2024 Omikhleia
--
-- Public API:
--  - (static method) CslLocale.parse(doc) -> CslLocale
--  - (static method) CslLocale.read(filename) -> CslLocale
--  - CslLocale:date(form) -> table<cs:date-parts>
--  - CslLocale:term(name, form?, plural?) -> string, gender
--  - CslLocale:ordinal(number, form?, gender-form?, plural?) -> string
--  - CslLocale:case(text, textCase) -> string
--

local casing = require("packages.bibtex.csl.utils.casing")
local xmlparser = require("packages.bibtex.csl.utils.xmlparser")

local parse = xmlparser.parse
local rules = {
   prefix = "cs:",
   skipEmptyStrings = true,
   preserveEmptyStrings = {},
   stripSpaces = true,
   preserveSpaces = { text = true, title = true, id = true, term = true },
}

local CslLocale = pl.class()

function CslLocale:_init (tree)
   self.terms = {}
   self.dates = {}
   self.styleOptions = {}
   self:_preprocess(tree)
end

-- Store items from the syntax tree in more convenient structures and maps
function CslLocale:_preprocess (tree)
   self.lang = tree.options["xml:lang"]

   for _, content in ipairs(tree) do
      if content.command == "cs:terms" then
         for _, term in ipairs(content) do
            if term.command == "cs:term" then
               local name = term.options.name
               if not name then
                  SU.error("CSL locale term without name")
               end
               local form = term.options.form or "long"
               -- gender-form is only used for ordinal terms, but it's simpler
               -- to just store it for all terms and have a consistent internal
               -- representation
               local genderf = term.options["gender-form"] or "neuter"

               self.terms[name] = self.terms[name] or {}
               self.terms[name][form] = self.terms[name][form] or {}
               -- Whole term (not sub-content) for its attributes
               self.terms[name][form][genderf] = term
            end
         end
      elseif content.command == "cs:style-options" then
         self.styleOptions = content.options
      elseif content.command == "cs:date" then
         local form = content.options.form
         if not form then
            SU.error("CSL locale date without form")
         end
         -- extract the cs:date-part sub-content
         self.dates[form] = SU.ast.subContent(content)
      end
   end
end

function CslLocale:_termvalue (term) -- luacheck: no unused args
   return term[1]
end

function CslLocale:_lookupTerm (name, form, genderf)
   local t = self.terms[name]
   if not t then
      return nil
   end
   form = form or "long"
   local f = t[form]
   if not f then
      -- If not found, check for form fallbacks
      if form == "long" then
         return nil -- (No fallback)
      end
      if form == "verb-short" then
         form = "verb"
      elseif form == "symbol" then
         form = "short"
      elseif form == "verb" or form == "short" then
         form = "long"
      end
      return self:_lookupTerm(name, form, genderf)
   end
   genderf = genderf or "neuter"
   local g = f[genderf]
   if not g then
      if genderf == "neuter" then
         return nil -- (No fallback)
      end
      return self:_lookupTerm(name, form, "neuter")
   end
   SU.debug("csl", "Lookup term", name, form, genderf)
   return g
end

function CslLocale:_lookupShortOrdinal (number, genderf)
   SU.debug("csl", "Lookup short-ordinal", number, genderf)
   number = tonumber(number)
   if not number then
      SU.error("CSL ordinal term requires a number")
   end

   -- Case 0-9
   if number < 10 then
      local name = ("ordinal-%02d"):format(number)
      local term = self:_lookupTerm(name, "long", genderf)
      if term then -- direct match on 0-9
         return term
      end
      return self:_lookupTerm("ordinal", "long", genderf)
   end
   -- Case 10-99
   if number < 100 then
      local name = ("ordinal-%02d"):format(number)
      local term = self:_lookupTerm(name, "long", genderf)
      if term then
         return term
      end
      -- No direct match, try to match the last digit
      local lastDigit = number % 10
      local nameLastDigit = ("ordinal-%02d"):format(lastDigit)
      local termLastDigit = self:_lookupTerm(nameLastDigit, "long", genderf)
      if termLastDigit and termLastDigit.match ~= "whole-number" then
         return termLastDigit
      end
      return self:_lookupTerm("ordinal", "long", genderf)
   end
   -- TODO FIXME: CSL specs do define rules for larger numbers, but is this really useful?
   -- Not bothering for now!
   SU.error("CSL ordinal beyond currently supported range")
end

-- PUBLIC METHODS

--- Lookup a date format in the locale.
-- @tparam string form The form of the date ('numeric' or 'text')
-- @treturn table The date format as a table of cs:date-parts
function CslLocale:date (form)
   local d = self.dates[form]
   if not d then
      SU.error("CSL locale date format not found: " .. tostring(form))
   end
   return d
end

--- Lookup a term in the locale.
-- Reserved for non-ordinal terms.
-- @tparam string name The name of the term
-- @tparam string form The form of the term (default: "long")
-- @tparam boolean plural Whether to return the plural form (default: false)
-- @treturn string,string The term (or empty string), and the gender or the term (or nil)
function CslLocale:term (name, form, plural)
   local term = self:_lookupTerm(name, form)
   if not term then
      return nil
   end
   if type(term[1]) == "string" then
      return self:_termvalue(term), term.options.gender
   end
   local sgpl = SU.ast.findInTree(term, plural and "cs:multiple" or "cs:single")
   if not sgpl then
      pl.pretty.dump(term)
      return SU.error("CSL term error for singular/multiple: " .. name)
   end
   return self:_termvalue(sgpl), term.options.gender
end

--- Lookup an ordinal term in the locale.
-- Reserved for ordinal terms.
-- @tparam number number The numeric value to be formatted
-- @tparam string name The name of the term
-- @tparam string form The form of the term (default: "short")
-- @tparam string genderf The gender-form of the term (default: "neuter")
-- @tparam boolean plural Whether to return the plural form (default: false)
function CslLocale:ordinal (number, form, genderf, plural)
   if form == "long" then
      -- TODO FIXME: Not sure this is widely used, not bothering for now
      SU.warn("CSL long-ordinal term not implemented, fallback to short ordinals")
   end
   local term = self:_lookupShortOrdinal(number, genderf)
   if not term then
      SU.error("CSL ordinal term not found for ordinal: " .. tostring(number))
   end
   if type(term[1]) == "string" then
      return number .. self:_termvalue(term)
   end
   local sgpl = SU.ast.findInTree(term, plural and "cs:plural" or "cs:single")
   if not sgpl then
      SU.error("CSL ordinal term not found for ordinal: " .. tostring(number))
   end
   return number .. self:_termvalue(sgpl)
end

--- Apply a text case transformation.
-- @tparam string text Text to transform
-- @tparam string textCase CSL case transformation
-- @treturn string The transformed text
function CslLocale:case (text, textCase)
   local lang = self.lang
   if not casing[textCase] then
      SU.warn("CSL locale case not found: " .. textCase)
      return text
   end
   return casing[textCase](text, lang)
end

--- Parse a CSL locale file (static method).
-- @tparam string doc The CSL locale file content
-- @treturn CslLocale The locale object (or nil, error message on failure)
function CslLocale.parse (doc)
   local tree, err = parse(doc, rules)
   if not tree then
      return nil, err
   end
   return CslLocale(tree)
end

--- Read a CSL locale file (static method).
-- @tparam string filename The resolved filename of the locale file
-- @treturn CslLocale The locale object (or nil, error message on failure)
function CslLocale.read (filename)
   local file, err = io.open(filename)
   if not file then
      return nil, err
   end
   local doc = file:read("*a")
   file:close()
   return CslLocale.parse(doc)
end

return CslLocale
