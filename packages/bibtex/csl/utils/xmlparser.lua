--- Modified XML parser
--
-- MOSTLY ADAPTED FROM SILE's XML INPUTTER
-- BUT WITH EXTRA FEATURES FOR NAMESPACING AND SPACES CLEANING.
--
-- It simplifies the processing a lot later...
-- TODO FIXME: This could raise an interesting discussion about the supposedly
-- generic XML support in SILE...

local lxp = require("lxp")

local defaultRules = {
   -- NAMESPACING:
   -- If defined, prefix is prepended to the tag name to create the SILE
   -- command name.
   -- This is a way to avoid conflicts between different XML formats and
   -- sile.commands.
   prefix = nil,
   -- SPACES CLEANING:
   -- Depending on the XML schema, some spaces may be irrelevant.
   -- Some XML nodes are containers for other nodes. They may have spaces
   -- in their content, due to the XML formatting and indentation.
   -- Some XML nodes contain text that should be stripped of trailing and
   -- leading spaces.
   -- It is cumbersome to have to strip spaces in the SILE content later,
   -- so we can define here the nodes for which we want to strip spaces.
   -- skipEmptyStrings is eitheir a boolean or a table with tags to skip
   -- text strings composed only of spaces in elements.
   -- When set to true, all elements are considered by default. In that
   -- case, preserveEmptyStrings is used to keep empty strings in some
   -- elements.
   -- stripSpaces is either a boolean or a table with tags to strip the
   -- leading and trailing spaces in text elements.
   -- When set to true, all elements are considered by default. In that
   -- case, preserveSpaces is used to keep spaces in some tags.
   stripSpaces = false,
   preserveSpaces = {},
   skipEmptyStrings = false,
   preserveEmptyStrings = {},
}

local function isStripSpaces (tag, rules)
   if type(rules.stripSpaces) == "table" then
      return rules.stripSpaces[tag] and not rules.preserveSpaces[tag]
   end
   return rules.stripSpaces and not rules.preserveSpaces[tag]
end

local function isSkipEmptyStrings (tag, rules)
   if type(rules.skipEmptyStrings) == "table" then
      return rules.skipEmptyStrings[tag] and not rules.preserveEmptyStrings[tag]
   end
   return rules.skipEmptyStrings and not rules.preserveEmptyStrings[tag]
end

local function startcommand (parser, command, options)
   local callback = parser:getcallbacks()
   local stack = callback.stack
   local lno, col, pos = parser:pos()
   local position = { lno = lno, col = col, pos = pos }
   -- create an empty command which content will be filled on closing tag
   local element = SU.ast.createCommand(command, options, nil, position)
   table.insert(stack, element)
end

local function endcommand (parser, command)
   local callback = parser:getcallbacks()
   local stack, rules = callback.stack, callback.rules
   local element = table.remove(stack)
   assert(element.command == command)
   element.command = rules.prefix and (rules.prefix .. command) or command

   local level = #stack
   table.insert(stack[level], element)
end

local function text (parser, msg)
   local callback = parser:getcallbacks()
   local stack, rules = callback.stack, callback.rules
   local element = stack[#stack]

   local stripSpaces = isStripSpaces(element.command, rules)
   local skipEmptyStrings = isSkipEmptyStrings(element.command, rules)

   local txt = (stripSpaces or skipEmptyStrings) and msg:gsub("^%s+", ""):gsub("%s+$", "") or msg
   if skipEmptyStrings and txt == "" then
      return
   end
   msg = stripSpaces and txt or msg

   local n = #element
   if type(element[n]) == "string" then
      element[n] = element[n] .. msg
   else
      table.insert(element, msg)
   end
end

local function parse (doc, rules)
   local content = {
      StartElement = startcommand,
      EndElement = endcommand,
      CharacterData = text,
      _nonstrict = true,
      stack = { {} },
      rules = rules or defaultRules,
   }
   local parser = lxp.new(content)
   local status, err
   if type(doc) == "string" then
      status, err = parser:parse(doc)
      if not status then
         return nil, err
      end
   else
      return nil, "Only string input should be supported"
   end
   status, err = parser:parse()
   if not status then
      return nil, err
   end
   parser:close()
   return content.stack[1][1]
end

return {
   parse = parse,
}
