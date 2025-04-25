-- Note: based on Knuth-Liang algorithm, formerly known in the SILE code base as liang-hyphenator

local module = require("types.module")
local hyphenator = pl.class(module)
hyphenator.type = "hyphenator"

function hyphenator:_init (language)
   self._name = language._name
   self.language = language
   self.minWord = 5 -- Smallest word length below which hyphenation is not applied
   self.leftmin = 2 -- Minimum number of characters to the left of the hyphen (TeX default)
   self.rightmin = 2 -- Minimum number of characters to the right of the hyphen (TeX default)
   self.trie = {} -- Trie resulting from the patterns
   self.exceptions = {} -- Hyphenation exceptions
   module._init(self)
   self:loadPatterns()
end

function hyphenator:loadPatterns ()
   local code = self.language:_getLegacyCode()
   local status, hyphens = pcall(require, ("languages.%s.hyphens"):format(code))
   if not status then
      status, hyphens = pcall(require, ("languages.%s.hyphens-tex"):format(code))
   end
   if not status then
      SU.warn("No hyphenation patterns for language " .. code)
   else
      for _, pattern in ipairs(hyphens.patterns or {}) do
         self:addPattern(pattern)
      end
      for _, exception in ipairs(hyphens.exceptions or {}) do
         self:registerException(exception)
      end
   end
   local hyphenmins = hyphens.hyphenmins
   -- TODO: We ought to have a way to set these according to users' preferences
   -- For now, we just set them to the conventional values based on the pattern files, or TeX defaults
   -- Yet, if available, we use the typesetting convention.
   -- For the record, the generation miniam are the real minima below which the pattern file is not
   -- applicable. (So even users' preferences should not go below these values.)
   if hyphenmins then
      if hyphenmins.typesetting then
         self.leftmin = hyphenmins.typesetting.left or 2
         self.rightmin = hyphenmins.typesetting.right or 2
         SU.debug("hyphenator", "Setting hyphenation minima for typesetting:", self.leftmin, self.rightmin)
      elseif hyphenmins.generation then
         self.leftmin = hyphenmins.generation.left or 2
         self.rightmin = hyphenmins.generation.right or 2
         SU.debug("hyphenator", "Setting hyphenation minima from generation:", self.leftmin, self.rightmin)
      end
   end
end

local _registered_base_commands = false

function hyphenator:_registerCommands ()
   if _registered_base_commands then
      return
   end
   _registered_base_commands = true
   self:registerCommand("hyphenator:add-exceptions", function (options, content)
      local lang = options.lang or self.settings:get("document.language")
      local language = SILE.typesetter:_cacheLanguage(lang)
      for token in SU.gtoke(content[1]) do
         if token.string then
            language.hyphenator:registerException(token.string)
         end
      end
   end, "Add patterns to the languages hyphenation rules")
end

function hyphenator:registerCommands () end

--- Register a function as a SILE command.
-- Takes any Lua function and registers it for use as a SILE command (which will in turn be used to process any content
-- nodes identified with the command name.
--
-- @tparam string name Name of cammand to register.
-- @tparam function func Callback function to use as command handler.
-- @tparam[opt] nil|string help User friendly short usage string for use in error messages, documentation, etc.
-- @tparam[opt] nil|string pack Information identifying the module registering the command for use in error and usage
-- messages. Usually auto-detected.
function hyphenator:registerCommand (name, func, help, pack, defaults)
   SILE.commands:register(self, name, func, help, pack, defaults)
end

function hyphenator:addPattern (pattern)
   local trie = self.trie
   local bits = SU.splitUtf8(pattern)
   for i = 1, #bits do
      local char = bits[i]
      if not char:find("%d") then
         if not trie[char] then
            trie[char] = {}
         end
         trie = trie[char]
      end
   end
   trie["_"] = {}
   local lastWasDigit = 0
   for i = 1, #bits do
      local char = bits[i]
      if char:find("%d") then
         lastWasDigit = 1
         table.insert(trie["_"], tonumber(char))
      elseif lastWasDigit == 1 then
         lastWasDigit = 0
      else
         table.insert(trie["_"], 0)
      end
   end
end

function hyphenator:registerException (exception)
   local text = exception:gsub("-", "")
   local bits = SU.splitUtf8(exception)
   self.exceptions[text] = {}
   local j = 1
   for _, bit in ipairs(bits) do
      j = j + 1
      if bit == "-" then
         j = j - 1
         self.exceptions[text][j] = 1
      else
         self.exceptions[text][j] = 0
      end
   end
end

function hyphenator:_segment (text)
   if luautf8.len(text) < self.minWord then
      return { text }
   end
   local lowertext = luautf8.lower(text)
   local points = self.exceptions[lowertext]
   local word = SU.splitUtf8(text)
   if not points then
      points = SU.map(function ()
         return 0
      end, word)
      local work = SU.map(luautf8.lower, word)
      table.insert(work, ".")
      table.insert(work, 1, ".")
      table.insert(points, 1, 0)
      for i = 1, #work do
         local trie = self.trie
         for j = i, #work do
            if not trie[work[j]] then
               break
            end
            trie = trie[work[j]]
            local p = trie["_"]
            if p then
               for k = 1, #p do
                  if points[i + k - 2] and points[i + k - 2] < p[k] then
                     points[i + k - 2] = p[k]
                  end
               end
            end
         end
      end
      -- Still inside the no-exceptions case
      for i = 1, self.leftmin do
         points[i] = 0
      end
      for i = #points - self.rightmin + 1, #points do
         points[i] = 0
      end
   end
   local pieces = { "" }
   for i = 1, #word do
      pieces[#pieces] = pieces[#pieces] .. word[i]
      if points[1 + i] and 1 == (points[1 + i] % 2) then
         table.insert(pieces, "")
      end
   end
   return pieces
end

function hyphenator:hyphenateSegments (node, segments, _)
   local hyphen = SILE.shaper:createNnodes(self.settings:get("font.hyphenchar"), node.options)
   return SILE.types.node.discretionary({ prebreak = hyphen }), segments
end

function hyphenator:showHyphenationPoints (word, lang)
   lang = lang or self.settings:get("document.language")
   local language = SILE.typesetter:_cacheLanguage(lang)
   return SU.concat(language.hyphenator:_segment(word), self.settings:get("font.hyphenchar"))
end

function hyphenator:hyphenate (nodelist)
   local newlist = {}
   for _, node in ipairs(nodelist) do
      if node.language then
         local nodes_own_hyphenator = self.language.typesetter:_cacheLanguage(node.language).hyphenator
         local newnodes = nodes_own_hyphenator:hyphenateNode(node)
         for _, n in ipairs(newnodes) do
            table.insert(newlist, n)
         end
      else
         table.insert(newlist, node)
      end
   end
   return newlist
end

function hyphenator:hyphenateNode (node)
   if not node.language or not node.is_nnode or not node.text then
      return node
   end
   local segments = self:_segment(node.text)
   local hyphen
   if #segments > 1 then
      local newnodes = {}
      for j, segment in ipairs(segments) do
         if segment == "" then
            SU.dump({ j, segments })
            SU.error("No hyphenation segment should ever be empty", true)
         end
         hyphen, segments = self:hyphenateSegments(node, segments, j)
         for _, newNode in ipairs(SILE.shaper:createNnodes(segments[j], node.options)) do
            if newNode.is_nnode then
               newNode.parent = node
               table.insert(newnodes, newNode)
            end
         end
         if j < #segments then
            hyphen.parent = node
            table.insert(newnodes, hyphen)
         end
      end
      node.children = newnodes
      node.hyphenated = false
      node.done = false
      return newnodes
   end
   return { node }
end

return hyphenator
