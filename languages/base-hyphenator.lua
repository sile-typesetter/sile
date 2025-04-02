-- Note: based on Knuth-Liang algorithm, formerly known in the SILE code base as liang-hyphenator

local hyphenator = pl.class()
hyphenator.type = "hyphenator"
hyphenator._name = "base"

function hyphenator:_init (language)
   self._name = language._name
   self.language = language
   self.minWord = 5
   self.leftmin = 2
   self.rightmin = 2
   self.trie = {}
   self.exceptions = {}
   self:registerCommands()
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
end

function hyphenator:registerCommands ()
   -- TODO rewire this so it can add exceptions to languages other than this instance
   self:registerCommand("hyphenator:add-exceptions", function (_options, content)
      -- local lang = options.lang or SILE.settings:get("document.language") or "und"
      -- initHyphenator(lang)
      for token in SU.gtoke(content[1]) do
         if token.string then
            self:registerException(token.string)
         end
      end
   end, nil, nil, true)
end

-- TODO This is duplicated from many module types, should probably be made a utility
function hyphenator.registerCommand (_, name, func, help, pack)
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
      for i = #points - self.rightmin, #points do
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

function hyphenator.hyphenateSegments (_, node, segments, _)
   local hyphen = SILE.shaper:createNnodes(SILE.settings:get("font.hyphenchar"), node.options)
   return SILE.types.node.discretionary({ prebreak = hyphen }), segments
end


function hyphenator:showHyphenationPoints (word, _language)
   -- language = language or "en"
   -- initHyphenator(language)
   -- TODO rewire with language cacher
   return SU.concat(self:_segment(word), SILE.settings:get("font.hyphenchar"))
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
   -- -- TODO figure out what languages used this override and rewire
   -- if (type(SILE.hyphenator.languages[node.language]) == "function") then
   --    return SILE.hyphenator.languages[node.language](node)
   -- end
   -- SU.debug("hyphenation", "Attempting on", tostring(node))
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
