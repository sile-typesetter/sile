-- luacheck: globals setfenv getfenv
-- luacheck: ignore _ENV

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
         local authors = item.author or {}
         if #authors == 0 then
            return ""
         end
         if #authors == 1 then
            return authors[1].ll
         else
            local names = {}
            for i = 1, #authors do
               local author = authors[i]
               names[i] = author.ll .. ", " .. author.f .. "."
            end
            return Bibliography.Style.commafy(names)
         end
      end,

      andSurnames = function (max)
         return function (item)
            local authors = item.author or {}
            if #authors == 0 then
               return ""
            end
            if #authors > max then
               return authors[1].ll .. " " .. fluent:get_message("bibliography-et-al")
            else
               local names = {}
               for i = 1, #authors do
                 names[i] = authors[i].ll
               end
               return Bibliography.Style.commafy(names)
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
            r[#r + 1] = fluent:get_message("bibliography-edited-by")({
               name = Bibliography.Style.firstLastNames(item.editor),
            })
         end
         if item.translator then
            r[#r + 1] = fluent:get_message("bibliography-translated-by")({
               name = Bibliography.Style.firstLastNames(item.translator),
            })
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

      firstLastNames = function (field)
         local namelist = field or {}
         if #namelist == 0 then
            return ""
         end
         local names = {}
         for i = 1, #namelist do
            local author = namelist[i]
            names[i] = author.ff .. " " .. author.ll
         end
         return Bibliography.Style.commafy(names)
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
