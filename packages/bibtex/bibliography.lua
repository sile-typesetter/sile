-- luacheck: globals setfenv getfenv
-- luacheck: ignore _ENV

-- The following functions borrowed from Norman Ramsey's nbibtex,
-- with permission.

local function find_outside_braces (str, pat, i)
   -- local len = string.len(str)
   local j, k = string.find(str, pat, i)
   if not j then
      return j, k
   end
   local jb, kb = string.find(str, "%b{}", i)
   while jb and jb < j do -- scan past braces
      -- braces come first, so we search again after close brace
      local i2 = kb + 1
      j, k = string.find(str, pat, i2)
      if not j then
         return j, k
      end
      jb, kb = string.find(str, "%b{}", i2)
   end
   -- either pat precedes braces or there are no braces
   return string.find(str, pat, j) -- 2nd call needed to get captures
end

local function split (str, pat, find) -- return list of substrings separated by pat
   find = find or string.find -- could be find_outside_braces
   -- @Omikhelia: I added this check here to avoid breaking on error,
   -- but probably in could have been done earlier...
   if not str then
      return {}
   end

   local len = string.len(str)
   local t = {}
   local insert = table.insert
   local i, j = 1, true
   local k
   while j and i <= len + 1 do
      j, k = find(str, pat, i)
      if j then
         insert(t, string.sub(str, i, j - 1))
         i = k + 1
      else
         insert(t, string.sub(str, i))
      end
   end
   return t
end

local function splitters (str, pat, find) -- return list of separators
   find = find or string.find -- could be find_outside_braces
   local t = {}
   local insert = table.insert
   local j, k = find(str, pat, 1)
   while j do
      insert(t, string.sub(str, j, k))
      j, k = find(str, pat, k + 1)
   end
   return t
end

local function namesplit (str)
   local t = split(str, "%s+[aA][nN][dD]%s+", find_outside_braces)
   local i = 2
   while i <= #t do
      while string.find(t[i], "^[aA][nN][dD]%s+") do
         t[i] = string.gsub(t[i], "^[aA][nN][dD]%s+", "")
         table.insert(t, i, "")
         i = i + 1
      end
      i = i + 1
   end
   return t
end

local sep_and_not_tie = "%-"
local sep_chars = sep_and_not_tie .. "%~"

local parse_name
do
   local white_sep = "[" .. sep_chars .. "%s]+"
   local white_comma_sep = "[" .. sep_chars .. "%s%,]+"
   local trailing_commas = "(,[" .. sep_chars .. "%s%,]*)$"
   local sep_char = "[" .. sep_chars .. "]"
   local leading_white_sep = "^" .. white_sep

   -- <name-parsing utilities>=
   local function isVon (str)
      local lower = find_outside_braces(str, "%l") -- first nonbrace lowercase
      local letter = find_outside_braces(str, "%a") -- first nonbrace letter
      local bs, _, _ = find_outside_braces(str, "%{%\\(%a+)") -- \xxx
      if lower and lower <= letter and lower <= (bs or lower) then
         return true
      elseif letter and letter <= (bs or letter) then
         return false
      elseif bs then
         -- if upper_specials[command] then
         --   return false
         -- elseif lower_specials[command] then
         --   return true
         -- else
         -- local close_brace = find_outside_braces(str, '%}', ebs+1)
         lower = string.find(str, "%l") -- first nonbrace lowercase
         letter = string.find(str, "%a") -- first nonbrace letter
         return lower and lower <= letter
      -- end
      else
         return false
      end
   end

   function parse_name (str, inter_token)
      if string.find(str, trailing_commas) then
         SU.error("Name '%s' has one or more commas at the end", str)
      end
      str = string.gsub(str, trailing_commas, "")
      str = string.gsub(str, leading_white_sep, "")
      local tokens = split(str, white_comma_sep, find_outside_braces)
      local trailers = splitters(str, white_comma_sep, find_outside_braces)
      -- The string separating tokens is reduced to a single
      -- ``separator character.'' A comma always trumps other
      -- separator characters. Otherwise, if there's no comma,
      -- we take the first character, be it a separator or a
      -- space. (Patashnik considers that multiple such
      -- characters constitute ``silliness'' on the user's
      -- part.)
      -- <rewrite [[trailers]] to hold a single separator character each>=
      for i = 1, #trailers do
         local trailer = trailers[i]
         assert(string.len(trailer) > 0)
         if string.find(trailer, ",") then
            trailers[i] = ","
         else
            trailers[i] = string.sub(trailer, 1, 1)
         end
      end
      local commas = {} -- maps each comma to index of token the follows it
      for i, t in ipairs(trailers) do
         string.gsub(t, ",", function ()
            table.insert(commas, i + 1)
         end)
      end
      local name = {}
      -- A name has up to four parts: the most general form is
      -- either ``First von Last, Junior'' or ``von Last,
      -- First, Junior'', but various vons and Juniors can be
      -- omitted. The name-parsing algorithm is baroque and is
      -- transliterated from the original BibTeX source, but
      -- the principle is clear: assign the full version of
      -- each part to the four fields [[ff]], [[vv]], [[ll]],
      -- and [[jj]]; and assign an abbreviated version of each
      -- part to the fields [[f]], [[v]], [[l]], and [[j]].
      -- <parse the name tokens and set fields of [[name]]>=
      local first_start, first_lim, last_lim, von_start, von_lim, jr_lim
      -- variables mark subsequences; if start == lim, sequence is empty
      local n = #tokens
      -- The von name, if any, goes from the first von token to
      -- the last von token, except the last name is entitled
      -- to at least one token. So to find the limit of the von
      -- name, we start just before the last token and wind
      -- down until we find a von token or we hit the von start
      -- (in which latter case there is no von name).
      -- <local parsing functions>=
      local function divide_von_from_last ()
         von_lim = last_lim - 1
         while von_lim > von_start and not isVon(tokens[von_lim - 1]) do
            von_lim = von_lim - 1
         end
      end

      local commacount = #commas
      if commacount == 0 then -- first von last jr
         von_start, first_start, last_lim, jr_lim = 1, 1, n + 1, n + 1
         -- OK, here's one form.
         --
         -- <parse first von last jr>=
         local got_von = false
         while von_start < last_lim - 1 do
            if isVon(tokens[von_start]) then
               divide_von_from_last()
               got_von = true
               break
            else
               von_start = von_start + 1
            end
         end
         if not got_von then -- there is no von name
            while von_start > 1 and string.find(trailers[von_start - 1], sep_and_not_tie) do
               von_start = von_start - 1
            end
            von_lim = von_start
         end
         first_lim = von_start
      elseif commacount == 1 then -- von last jr, first
         von_start, last_lim, jr_lim, first_start, first_lim = 1, commas[1], commas[1], commas[1], n + 1
         divide_von_from_last()
      elseif commacount == 2 then -- von last, jr, first
         von_start, last_lim, jr_lim, first_start, first_lim = 1, commas[1], commas[2], commas[2], n + 1
         divide_von_from_last()
      else
         SU.error(("Too many commas in name '%s'"):format(str))
      end
      -- <set fields of name based on [[first_start]] and friends>=
      -- We set long and short forms together; [[ss]] is the
      -- long form and [[s]] is the short form.
      -- <definition of function [[set_name]]>=
      local function set_name (start, lim, long, short)
         if start < lim then
            -- string concatenation is quadratic, but names are short
            -- An abbreviated token is the first letter of a token,
            -- except again we have to deal with the damned specials.
            -- <definition of [[abbrev]], for shortening a token>=
            local function abbrev (token)
               local first_alpha, _, alpha = string.find(token, "(%a)")
               local first_brace = string.find(token, "%{%\\")
               if first_alpha and first_alpha <= (first_brace or first_alpha) then
                  return alpha
               elseif first_brace then
                  local i, _, special = string.find(token, "(%b{})", first_brace)
                  if i then
                     return special
                  else -- unbalanced braces
                     return string.sub(token, first_brace)
                  end
               else
                  return ""
               end
            end
            local longname = tokens[start]
            local shortname = abbrev(tokens[start])
            for i = start + 1, lim - 1 do
               if inter_token then
                  longname = longname .. inter_token .. tokens[i]
                  shortname = shortname .. inter_token .. abbrev(tokens[i])
               else
                  local ssep, nnext = trailers[i - 1], tokens[i]
                  local sep, next = ssep, abbrev(nnext)
                  -- Here is the default for a character between tokens:
                  -- a tie is the default space character between the last
                  -- two tokens of the name part, and between the first two
                  -- tokens if the first token is short enough; otherwise,
                  -- a space is the default.
                  -- <possibly adjust [[sep]] and [[ssep]] according to token position and size>=
                  if not string.find(sep, sep_char) then
                     if i == lim - 1 then
                        sep, ssep = "~", "~"
                     elseif i == start + 1 then
                        sep = string.len(shortname) < 3 and "~" or " "
                        ssep = string.len(longname) < 3 and "~" or " "
                     else
                        sep, ssep = " ", " "
                     end
                  end
                  longname = longname .. ssep .. nnext
                  shortname = shortname .. "." .. sep .. next
               end
            end
            name[long] = longname
            name[short] = shortname
         end
      end
      set_name(first_start, first_lim, "ff", "f")
      set_name(von_start, von_lim, "vv", "v")
      set_name(von_lim, last_lim, "ll", "l")
      set_name(last_lim, jr_lim, "jj", "j")
      return name
   end
end

-- Thanks, Norman, for the above functions!

local Bibliography
Bibliography = {
   CitationStyles = {
      -- luacheck: push ignore
      ---@diagnostic disable: undefined-global, unused-local
      AuthorYear = function (_ENV)
         return andSurnames(3), " ", year, optional(", ", cite.page)
      end,
      -- luacheck: pop
      ---@diagnostic enable: undefined-global, unused-local
   },

   produceCitation = function (cite, bib, style)
      local item = bib[cite.key]
      if not item then
         -- Should have been already checked by the caller
         return Bibliography.Errors.UNKNOWN_REFERENCE
      end
      local t = Bibliography.buildEnv(cite, item.attributes, style)
      local func = setfenv and setfenv(style.CitationStyle, t) or style.CitationStyle
      return Bibliography._process(item.attributes, { func(t) })
   end,

   produceReference = function (cite, bib, style)
      local item = bib[cite.key]
      if not item then
         -- Should have been already checked by the caller
         return Bibliography.Errors.UNKNOWN_REFERENCE
      end
      item.type = item.type:gsub("^%l", string.upper)
      if not style[item.type] then
         return Bibliography.Errors.UNKNOWN_TYPE, item.type
      end

      local t = Bibliography.buildEnv(cite, item.attributes, style)
      local func = setfenv and setfenv(style[item.type], t) or style[item.type]
      return Bibliography._process(item.attributes, { func(t) })
   end,

   buildEnv = function (cite, item, style)
      local t = pl.tablex.copy(getfenv and getfenv(1) or _ENV)
      t.cite = cite
      t.item = item
      for k, v in pairs(item) do
         if k:lower() == "type" then
            k = "bibtype"
         end -- HACK: don't override the type() function
         t[k:lower()] = v
      end
      return pl.tablex.update(t, style)
   end,

   _process = function (item, t, dStart, dEnd)
      for i = 1, #t do
         if type(t[i]) == "function" then
            t[i] = t[i](item)
         end
      end
      local res = SU.concat(t, "")
      if dStart or dEnd then
         if res ~= "" then
            return (dStart .. res .. dEnd)
         end
      else
         return res
      end
   end,

   Errors = {
      UNKNOWN_REFERENCE = 1,
      UNKNOWN_TYPE = 2,
   },

   Style = {
      andAuthors = function (item)
         local authors = namesplit(item.author)
         if #authors == 1 then
            return parse_name(authors[1]).ll
         else
            for i = 1, #authors do
               local author = parse_name(authors[i])
               authors[i] = author.ll .. ", " .. author.f .. "."
            end
            return table.concat(authors, " " .. fluent:get_message("bibliography-and") .. " ")
         end
      end,

      andSurnames = function (max)
         return function (item)
            local authors = namesplit(item.author)
            if #authors > max then
               return parse_name(authors[1]).ll .. " " .. fluent:get_message("bibliography-et-al")
            else
               for i = 1, #authors do
                  authors[i] = parse_name(authors[i]).ll
               end
               return Bibliography.Style.commafy(authors)
            end
         end
      end,

      pageRange = function (item)
         if item.pages then
            return item.pages:gsub("%-%-", "–")
         end
      end,

      transEditor = function (item)
         local r = {}
         if item.editor then
            r[#r + 1] = fluent:get_message("bibliography-edited-by")({ name = item.editor })
         end
         if item.translator then
            r[#r + 1] = fluent:get_message("bibliography-translated-by")({ name = item.translator })
         end
         if #r then
            return table.concat(r, ", ")
         end
         return nil
      end,
      quotes = function (...)
         local t = { ... }
         return function (item)
            return Bibliography._process(item, t, "“", "”")
         end
      end,
      italic = function (...)
         local t = { ... }
         return function (item)
            return Bibliography._process(item, t, "<em>", "</em>")
         end
      end,
      parens = function (...)
         local t = { ... }
         return function (item)
            return Bibliography._process(item, t, "(", ")")
         end
      end,
      optional = function (...)
         local t = { n = select("#", ...), ... }
         return function (item)
            for i = 1, t.n do
               if type(t[i]) == "function" then
                  t[i] = t[i](item)
               end
               if not t[i] or t[i] == "" then
                  return ""
               end
            end
            return table.concat(t, "")
         end
      end,

      commafy = function (t, andword) -- also stolen from nbibtex
         andword = andword or fluent:get_message("bibliography-and")
         if #t == 1 then
            return t[1]
         elseif #t == 2 then
            return t[1] .. " " .. andword .. " " .. t[2]
         else
            local last = t[#t]
            t[#t] = andword .. " " .. t[#t]
            local answer = table.concat(t, ", ")
            t[#t] = last
            return answer
         end
      end,
   },
}

return Bibliography
