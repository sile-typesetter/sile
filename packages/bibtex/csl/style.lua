--- Reader for CSL 1.0.2 locale files
--
-- @copyright License: MIT (c) 2024 Omikhleia
--
-- Public API:
--  - (static method) CslStyle.parse(doc) -> CslStyle
--  - (static method) CslStyle.read(filename) -> CslStyle
--

local xmlparser = require("packages.bibtex.csl.utils.xmlparser")

local parse = xmlparser.parse
local rules = {
   prefix = "cs:",
   skipEmptyStrings = true,
   preserveEmptyStrings = {},
   stripSpaces = true,
   preserveSpaces = { text = true, title = true, id = true, term = true },
}

local CslStyle = pl.class()

function CslStyle:_init (tree)
   self.macros = {}
   self.locales = {}
   self.bibliography = nil
   self.citation = nil
   self.globalOptions = {}
   self:_preprocess(tree)
end

-- Store items from the syntax tree in more convenient structures and maps
function CslStyle:_preprocess (tree)
   -- Global options and inheritable name options
   self.globalOptions = tree.options

   -- Extract macros, locale overrides, citation and bibliography
   for _, content in ipairs(tree) do
      if content.command == "cs:macro" then
         local name = content.options and content.options.name
         if not name then
            SU.error("CSL macro without name")
         end
         if self.macros[name] then
            SU.warn("CSL macro " .. name .. " has multiple definitions, using the last one")
         end
         self.macros[name] = SU.ast.subContent(content)
      elseif content.command == "cs:locale" then
         local lang = content.options and content.options["xml:lang"]
         if not lang then
            SU.error("CSL locale without xml:lang")
         end
         if self.locales[lang] then
            SU.warn("CSL locale " .. lang .. " has multiple definitions, using the last one")
         end
         -- Don't subcontent, so we have full locales here (overrides)
         self.locales[lang] = content
      elseif content.command == "cs:citation" then
         if self.citation then
            SU.warn("CSL has multiple citation definitions, using the last one")
         end
         -- Don't subContent, we want to keep the whole citation options (attributes)
         self.citation = content
      elseif content.command == "cs:bibliography" then
         if self.bibliography then
            SU.warn("CSL has multiple bibliography definitions, using the last one")
         end
         -- Don't subContent, we want to keep the whole bibliography options (attributes)
         self.bibliography = content
      end
      -- We can ignore cs:info and don't expect other top-level elements
   end
end

--- Parse a CSL style document (static method).
-- @tparam string doc The CSL style document
-- @treturn Csl The parsed CSL style object (or nil, error message on failure)
function CslStyle.parse (doc)
   local tree, err = parse(doc, rules)
   if not tree then
      return nil, err
   end
   return CslStyle(tree)
end

--- Read a CSL style file (static method).
-- @tparam string filename The resolved filename of the CSL style file
-- @treturn Csl The parsed CSL style object (or nil, error message on failure)
function CslStyle.read (filename)
   local file, err = io.open(filename)
   if not file then
      return nil, err
   end
   local doc = file:read("*a")
   file:close()
   return CslStyle.parse(doc)
end

return CslStyle
