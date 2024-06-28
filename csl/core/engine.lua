--- A rendering engine for CSL 1.0.2
--
-- @copyright License: MIT (c) 2024 Omikhleia
--
-- Public API:
--  - (constructor) CslEngine(style, locale) -> CslEngine
--  - CslEngine:cite(entry) -> string
--  - CslEngine:reference(entry) -> string
--
-- Important: while some consistency checks are performed, this engine is not
-- intended to handle errors in the locale, style or input data. It is assumed
-- that they are all valid.
--
-- THINGS NOT DONE
--  - disambiguation logic (not done at all)
--  - sorting logic (not done at all)
--  - other FIXME/TODOs in the code on specific features
--
-- luacheck: no unused args

local CslLocale = require("csl.core.locale").CslLocale

local endash = luautf8.char(0x2013)

local CslEngine = pl.class()

function CslEngine:_init (style, locale)
   self.locale = locale
   self.style = style

   -- Shortcuts for often used style elements
   self.macros = style.macros or {}
   self.citation = style.citation or {}
   self.locales = style.locales or {}
   self.bibliography = style.bibliography or {}
   self:_preprocess()

   -- Early lookups for often used localized punctuation marks
   self.punctuation = {
      open_quote = self.locale:term("open-quote") or luautf8.char(0x201C), -- 0x201C curly left quote
      close_quote = self.locale:term("close-quote") or luautf8.char(0x201D), -- 0x201D curly right quote
      open_inner_quote = self.locale:term("open-inner-quote") or luautf8.char(0x2018), -- 0x2018 curly left single quote
      close_inner_quote = self.locale:term("close-inner-quote") or luautf8.char(0x2019), -- 0x2019 curly right single quote
      page_range_delimiter = self.locale:term("page-range-delimiter") or endash, -- FIXME: UNUSED AS OF NOW
      [","] = self.locale:term("comma") or ",",
      [";"] = self.locale:term("semicolon") or ";",
      [":"] = self.locale:term("colon") or ":",
   }

   -- Inheritable variables
   -- There's a long list of such variables, but let's be dumb and just merge everything.
   self.inheritable = {
      citation = pl.tablex.union(
         self.style.globalOptions,
         self.style.citation and self.style.citation.options or {}
      ),
      bibliography = pl.tablex.union(
         self.style.globalOptions,
         self.style.bibliography and self.style.bibliography.options or {}
      ),
   }
end

function CslEngine:_prerender (mode)
   -- Stack for processing of cs:group as conditional
   self.groupQueue = {}
   self.groupState = { variables = {}, count = 0 }

   -- Track mode for processing: "citation" or "bibliography"
   -- Needed to use appropriate inheritable options.
   self.mode = mode

   -- Track first name for name-as-sort-order
   self.firstName = true
end

function CslEngine:_merge_locales (locale1, locale2)
   -- FIXME TODO:
   --  - Should we care about date formats and style options?
   --    (PERHAPS, CHECK THE SPEC)
   --  - Should we move this to the CslLocale class?
   --    (LIKELY YES)
   --  - Should we deepcopy the locale1 first, so it can be reused independently?
   --    (LIKELY YES, instantiating a new CslLocale)
   -- Merge terms, overriding existing ones
   for term, forms in pairs(locale2.terms) do
      if not locale1.terms[term] then
         SU.debug("csl", "CSL local merging added:", term)
         locale1.terms[term] = forms
      else
         for form, genderfs in pairs(forms) do
            if not locale1.terms[term][form] then
               SU.debug("csl", "CSL local merging added:", term, form)
               locale1.terms[term][form] = genderfs
            else
               for genderform, value in pairs(genderfs) do
                  local replaced = locale1.terms[term][form][genderform]
                  SU.debug("csl", "CSL local merging", replaced and "replaced" or "added:", term, form, genderform)
                  locale1.terms[term][form][genderform] = value
               end
            end
         end
      end
   end
end

function CslEngine:_preprocess ()
   -- Handle locale overrides
   if self.locales[self.locale.lang] then -- Direct language match
      local override = CslLocale(self.locales[self.locale.lang])
      SU.debug("csl", "Locale override found for " .. self.locale.lang)
      self:_merge_locales(self.locale, override)
   else
      for lang, locale in pairs(self.locales) do -- Fuzzy language matching
         if self.locale.lang:sub(1, #lang) == lang then
            local override = CslLocale(locale)
            SU.debug("csl", "Locale override found for " .. self.locale.lang .. " -> " .. lang)
            self:_merge_locales(self.locale, override)
         end
      end
   end
end

-- GROUP LOGIC (tracking variables in groups, conditional rendering)

function CslEngine:_enterGroup ()
   self.groupState.count = self.groupState.count + 1
   SU.debug("csl", "Enter group", self.groupState.count, "level", #self.groupQueue)

   table.insert(self.groupQueue, self.groupState)
   self.groupState = { variables = {}, count = 0 }
end

function CslEngine:_leaveGroup (rendered)
   -- Groups implicitly act as a conditional: if all variables that are called
   -- are empty, the group is suppressed.
   -- But the group is kept if no variable is called.
   local emptyVariables = true
   local hasVariables = false
   for _, cond in pairs(self.groupState.variables) do
      hasVariables = true
      if cond then -- non-empty variable found
         emptyVariables = false
         break
      end
   end
   local suppressGroup = hasVariables and emptyVariables
   if suppressGroup then
      rendered = nil -- Suppress group
   end
   self.groupState = table.remove(self.groupQueue)
   -- A nested non-empty group is treated as a non-empty variable for the
   -- purposes of determining suppression of the outer group.
   -- So add a pseudo-variable for the inner group to the outer group, to
   -- track this.
   if not suppressGroup then
      local groupCond = "_group_" .. self.groupState.count
      self:_addGroupVariable(groupCond, true)
   end
   SU.debug("csl", "Leave group", self.groupState.count, "level", #self.groupQueue, suppressGroup and "(suppressed)" or "(rendered)")
   return rendered
end

function CslEngine:_addGroupVariable (variable, value)
   SU.debug("csl", "Group variable", variable, value and "true" or "false")
   self.groupState.variables[variable] = value and true or false
end

-- RENDERING ATTRIBUTES (strip-periods, affixes, formatting, text-case, display, quotes)

function CslEngine:_render_stripPeriods (t, options)
   if t and options["strip-periods"] and t:sub(-1) == "." then
      t = t:sub(1, -2)
   end
   return t
end

function CslEngine:_render_affixes (t, options)
   if not t then
      return
   end
   if options.prefix then
      -- replace by localized prefix
      local pref = options.prefix:gsub("[,;:]", function (c) return self.punctuation[c] or c end)
      t = pref .. t
   end
   if options.suffix then
      local suff = options.suffix:gsub("[,;:]", function (c) return self.punctuation[c] or c end)
      t = t .. suff
   end
   return t
end

function CslEngine:_render_formatting (t, options)
   if not t then
      return
   end
   if options["font-style"] == "italic" then -- FIXME: also normal, oblique, and how nesting is supposed to work?
      t = "<em>" .. t .. "</em>"
   end
   if options["font-variant"] == "small-caps" then
      t = "<font features=\"+smcp\">" .. t .. "</font>"
   end
   if options["font-weight"] == "bold" then -- FIXME: also light, normal, and how nesting is supposed to work?
      t = "<strong>" .. t .. "</strong>"
   end
   if options["text-decoration"] == "underline" then
      t = "<underline>" .. t .. "</underline>"
   end
   if options["vertical-align"] == "sup" then
      t = "<textsuperscript>" .. t .. "</textsuperscript>"
   end
   if options["vertical-align"] == "sub" then
      t = "<textsubscript>" .. t .. "</textsubscript>"
   end
   return t
end

function CslEngine:_render_textCase (t, options)
   if not t then
      return
   end
   if options["text-case"] then
      t = self.locale:case(t, options["text-case"])
   end
   return t
end

function CslEngine:_render_display (t, options)
   if not t then
      return
   end
   -- if options.display then
      -- FIXME Add rationale for not supporting it...
      -- Keep silent: it's not a critical feature yet
      -- SU.warn("CSL display not implemented")
   -- end
   return t
end

function CslEngine:_render_quotes (t, options)
   if t and options.quotes then
      -- Smart transform straight quotes in the input to localized inner quotes.
      t = luautf8.gsub(t, "([%s%p])\"", "%1" .. self.punctuation.open_inner_quote)
      t = luautf8.gsub(t, "\"([%s%p])", self.punctuation.close_inner_quote .. "%1")
      -- Wrap the result in localized outer quotes.
      t = self.punctuation.open_quote .. t .. self.punctuation.close_quote
   end
   return t
end

function CslEngine:_render_delimiter(ts, delimiter) -- ts is a table of strings
   local d = delimiter and delimiter:gsub(
      "[,;:]",
      function (punct)
         return self.punctuation[punct]
      end
   )
   return table.concat(ts, d)
end

-- RENDERING ELEMENTS: layout, text, date, number, names, label, group, choose

function CslEngine:_layout (options, content, entry)
   local output = {}
   local entries = type(entry) == "table" and not entry.type and entry or { entry } -- Multiple entries vs. single entry
   for _, ent in ipairs(entries) do
      local elem = self:_render_children(content, ent)
      if elem then
         table.insert(output, elem)
      end
   end
   local t = self:_render_delimiter(output, options.delimiter)
   t = self:_render_formatting(t, options)
   t = self:_render_affixes(t, options)
   return t
end

function CslEngine:_text (options, content, entry)
   local t
   if options.macro then
      if self.macros[options.macro] then
         t = self:_render_children(self.macros[options.macro], entry)
      else
         SU.error("CSL macro " .. options.macro .. " not found")
      end
   elseif options.term then
      t = self.locale:term(options.term, options.form, options.plural)
   elseif options.variable then
      t = entry[options.variable]
      self:_addGroupVariable(options.variable, t)
      -- FIXME NOT IMPLEMENTED SPEC:
      -- "May be accompanied by the form attribute to select the “long”
      -- (default) or “short” form of a variable (e.g. the full or short
      -- title). If the “short” form is selected but unavailable, the
      -- “long” form is rendered instead."
      -- But CSL-JSON etc. do not seem to have standard provision for it.
   elseif options.value then
      t = options.value
   else
      SU.error("CSL text without macro, term, variable or value")
   end
   t = self:_render_stripPeriods(t, options)
   t = self:_render_textCase(t, options)
   t = self:_render_formatting(t, options)
   t = self:_render_quotes(t, options)
   t = self:_render_affixes(t, options)
   t = self:_render_display(t, options)
   return t
end

function CslEngine:_a_day (options, day, month) -- month needed to get gender for ordinal
   local form = options.form
   local t
   if form == "numeric-leading-zeros" then
      t = ("%02d"):format(day)
   elseif form == "ordinal" then
      local genderForm
      if month then
         local monthKey = ("month-%02d"):format(month)
         local _, gender = self.locale:term(monthKey)
         genderForm = gender or "neuter"
      end
      if SU.boolean(self.locale.styleOptions["limit-day-ordinals-to-day-1"], false) then
         t = day == 1 and self.locale:ordinal(day, "short", genderForm) or ("%d"):format(day)
      else
         t = self.locale:ordinal(day, "short", genderForm)
      end
   else -- "numeric" by default
      t = ("%d"):format(day)
   end
   return t
end

function CslEngine:_a_month (options, month)
   local form = options.form
   local t
   if form == "numeric" then
      t = ("%d"):format(month)
   elseif form == "numeric-leading-zeros" then
      t = ("%02d"):format(month)
   else -- short or long (default)
      local monthKey = ("month-%02d"):format(month)
      t = self.locale:term(monthKey, form or "long")
   end
   t = self:_render_stripPeriods(t, options)
   return t
end

function CslEngine:_a_season (options, season)
   local form = options.form
   local t
   if form == "numeric" or form == "numeric-leading-zeros" then
      -- The CSL specification does not seem to forbid it, but a numeric value
      -- for the season is a weird idea, qo we skip it for now.
      SU.warn("CSL season formatting as a number is ignored")
   else
      local seasonKey = ("season-%02d"):format(season)
      t = self.locale:term(seasonKey, form or "long")
   end
   t = self:_render_stripPeriods(t, options)
   return t
end

function CslEngine:_a_year (options, year)
   local form = options.form
   local t
   if form == "numeric-leading-zeros" then
      t = ("%04d"):format(year)
   elseif form == "short" then
      -- The spec gives as example 2005 -> 05
      t = ("%02d"):format(year % 100)
   else -- "long" by default
      t = ("%d"):format(year)
   end
   return t
end

function CslEngine:_a_date_day (options, date)
   local t
   if date.day then
      if type(date.day) == "table" then
         local t1 = self:_a_day(options, date.day[1], date.month)
         local t2 = self:_a_day(options, date.day[2], date.month)
         local sep = options['range-delimiter'] or endash
         t = t1 .. sep .. t2
      else
         t = self:_a_day(options, date.day, date.month)
      end
   end
   return t
end

function CslEngine:_a_date_month (options, date)
   local t
   if date.month then
      if type(date.month) == "table" then
         local t1 = self:_a_month(options, date.month[1])
         local t2 = self:_a_month(options, date.month[2])
         local sep = options['range-delimiter'] or endash
         t = t1 .. sep .. t2
      else
         t = self:_a_month(options, date.month)
      end
   elseif date.season then
      if type(date.season) == "table" then
         local t1 = self:_a_season(options, date.season[1])
         local t2 = self:_a_season(options, date.season[2])
         local sep = options['range-delimiter'] or endash
         t = t1 .. sep .. t2
      else
         t = self:_a_season(options, date.season)
      end
   end
   return t
end

function CslEngine:_a_date_year (options, date)
   local t
   if date.year then
      if type(date.year) == "table" then
         local t1 = self:_a_year(options, date.year[1])
         local t2 = self:_a_year(options, date.year[2])
         local sep = options['range-delimiter'] or endash
         t = t1 .. sep .. t2
      else
         t = self:_a_year(options, date.year)
      end
   end
   return t
end

function CslEngine:_date_part (options, content, date)
   local name = SU.required(options, "name", "cs:date-part")
   -- FIXME TODO full date range are not implemented properly
   -- But we need to decide how to encode them in the pseudo CSL-JSON...
   local t
   local callback = "_a_date_" .. name
   if self[callback] then
      t = self[callback](self, options, date)
   else
      SU.warn("CSL date part " .. name .. " not implemented yet")
   end
   t = self:_render_textCase(t, options)
   t = self:_render_formatting(t, options)
   t = self:_render_affixes(t, options)
   return t
end

function CslEngine:_date_parts (options, content, date)
   local output = {}
   for _, part in ipairs(content) do
      local t = self:_date_part(part.options, part, date)
      if t then
         table.insert(output, t)
      end
   end
   return self:_render_delimiter(output, options.delimiter)
end

function CslEngine:_date (options, content, entry)
   local variable = SU.required(options, "variable", "CSL number")
   local date = entry[variable]
   self:_addGroupVariable(variable, date)
   if date then
      if options.form then
         if content[1] then
            -- NOTE: Seems the case may occcur, to select a specific date part from the date
            -- I'm not sure I read this correctly in the CSL documentation!
            -- That would imply usingg a copied date object, with only the relevant part?
            SU.warn("CSL cs:date-parts in localized date not implemented")
         end
         -- Use locale date format
         content = self.locale:date(options.form)
         options.delimiter = nil -- Not supposed to exist
      end
      local t = self:_date_parts(options, content, date)
      t = self:_render_textCase(t, options)
      t = self:_render_formatting(t, options)
      t = self:_render_affixes(t, options)
      t = self:_render_display(t, options)
      return t
   end
end

function CslEngine:_number (options, content, entry)
   local variable = SU.required(options, "variable", "CSL number")
   local value = entry[variable]
   self:_addGroupVariable(variable, value)
   if value then
      local _, gender = self.locale:term(variable)
      local genderForm = gender or "neuter"

      -- FIXME TODO: Some complex stuff about name ranges, commas, etc. in the spec.
      -- Moreover:
      -- "Numbers with prefixes or suffixes are never ordinalized or rendered in roman numerals"
      -- Interpretation: values that are not numbers are not formatted (?)
      local form = tonumber(value) and options.form or "numeric"
      if form == "ordinal" then
         value = self.locale:ordinal(value, "short", genderForm)
      elseif form == "long-ordinal" then
         value = self.locale:ordinal(value, "long", genderForm)
      elseif form == "roman" then
         value = SU.formatNumber(value, { system = "roman" })
      end
   end
   value = self:_render_textCase(value, options)
   value = self:_render_formatting(value, options)
   value = self:_render_affixes(value, options)
   value = self:_render_display(value, options)
   return value
end

function CslEngine:_enterSubstitute (t)
   SU.debug("csl", "Enter substitute")
   -- Some group and variable cancellation logic applies to substitute.
   -- Wrap it in a pseudo-group to track variables.
   self:_enterGroup()
   return t
end

function CslEngine:_leaveSubstitute (t, entry)
   SU.debug("csl", "Leave substitute")
   local vars = self.groupState.variables
   -- "Substituted variables are considered empty for the purposes of
   -- determining whether to suppress an enclosing cs:group."
   -- So it's as if we hadn't seen any variable in our substitute.
   self.groupState.variables = {}
   -- "Substituted variables are suppressed in the rest of the output
   -- to prevent duplication"
   -- So if the substitution was successful, we remove referenced variables
   -- from the entry.
   if t then
      for field, cond in pairs(vars) do
         if cond then
            entry[field] = nil
         end
      end
   end
   -- Terminate the pseudo-group
   t = self:_leaveGroup(t)
   return t
end

function CslEngine:_substitute (options, content, entry)
   local t
   for _, child in ipairs(content) do
      self:_enterSubstitute()
      if child.command == "cs:names" then
         SU.required(child.options, "variable", "CSL cs:names in cs:substitute")
         local opts = pl.tablex.union(options, child.options)
         t = self:_names_with_resolved_opts(opts, nil, entry)
      else
         t = self:_render_node(child, entry)
      end
      t = self:_leaveSubstitute(t, entry)
      if t then -- First non-empty child is returned
         break
      end
   end
   return t
end

function CslEngine:_name_et_al (options)
   local t = self.locale:term(options.term or "et-al")
   t = self:_render_formatting(t, options)
   return t
end

function CslEngine:_a_name (options, content, entry)
   -- TODO FIXME: content can consists in name-part elements for formatting, text-case, affixes
   -- Chigaco style does not seem to use them, so we keep it simple for now.
   -- TODO FIXME: demote-non-dropping-particle option not implemented, and name particle not implemented at all!
   if options.form == "short" then
      return entry.family
   end
   if options["name-as-sort-order"] ~= "all" and not self.firstName then
      -- Order is: Given Family
      return entry.given and (entry.given .. " " .. entry.family) or entry.family
   end
   -- Order is: Family, Given
   local sep = options["sort-separator"] or (self.punctuation[","] .. " ")
   return entry.given and (entry.family .. sep .. entry.given) or entry.family
end

local function hasField (list, field)
   -- N.B. we want a true boolean here
   if string.match(' ' .. list .. ' ', ' '.. field .. ' ') then
     return true
   end
   return false
end

function CslEngine:_names_with_resolved_opts (options, substitute_node, entry)
   local variable = options.variable
   local et_al_min = options.et_al_min
   local et_al_use_first = options.et_al_use_first
   local and_word = options.and_word
   local name_delimiter = options.name_delimiter
   local is_label_first = options.is_label_first
   local label_opts = options.label_opts
   local et_al_opts = options.et_al_opts
   local name_node = options.name_node
   local names_delimiter = options.names_delimiter

   -- Special case if both editor and translator are wanted and are the same person(s)
   local editortranslator = false
   if hasField(variable, "editor") and hasField(variable, "translator") then
      editortranslator = entry.translator and entry.editor and pl.tablex.deepcompare(entry.translator, entry.editor)
      if editortranslator then
         entry.editortranslator = entry.editor
      end
   end

   -- Process
   local vars = pl.stringx.split(variable, " ")
   local output = {}
   for _, var in ipairs(vars) do
      self:_addGroupVariable(var, entry[var])

      local skip = editortranslator and var == "translator" -- done via the editor
      if not skip and entry[var] then
         local label
         if label_opts then
            local v = var == "editor" and editortranslator and "editortranslator" or var
            local opts = pl.tablex.union(label_opts, { variable = v })
            label = self:_label(opts, nil, entry)
         end
         local needEtAl = false
         local names = type(entry[var]) == "table" and entry[var] or { entry[var] }
         local l = {}
         for i, name in ipairs(names) do
            if #names >= et_al_min and i > et_al_use_first then
               needEtAl = true
               break
            end
            local t = self:_a_name(name_node.options, name_node, name)
            self.firstName = false
            table.insert(l, t)
         end
         local joined
         if needEtAl then
            -- TODO THINGS TO SUPPORT THAT MIGHT REQUIRE A REFACTOR
            -- They are not needed in Chicago style, so let's keep it simple for now.
            --    delimiter-precedes-et-al ("contextual" by default = hard-coded below)
            --    et-al-use-last (default false, if true, the last is rendered as ", ... Name) instead of using et-al.
            local rendered_et_all = self:_name_et_al(et_al_opts)
            local sep_et_al = #l > 1 and name_delimiter or " "
            joined = table.concat(l, name_delimiter) .. sep_et_al .. rendered_et_all
         elseif #l == 1 then
            joined = l[1]
         else
            local last = table.remove(l)
            joined = table.concat(l, name_delimiter) .. " " .. and_word .. " " .. last
         end
         if label then
            joined = is_label_first and (label .. joined) or (joined .. label)
         end

         table.insert(output, joined)
      end
   end

   if #output == 0 and substitute_node then
      return self:_substitute(options, substitute_node, entry)
   end
   if #output == 0 then
      return nil
   end
   local t = self:_render_delimiter(output, names_delimiter)
   t = self:_render_formatting(t, options)
   t = self:_render_affixes(t, options)
   t = self:_render_display(t, options)
   return t
end

function CslEngine:_names (options, content, entry)
   -- Extract needed elements and options from the content
   local name_node = nil
   local label_opts = nil
   local et_al_opts = {}
   local substitute = nil
   local is_label_first = false
   for _, child in ipairs(content) do
      if child.command == "cs:substitute" then
         substitute = child
      elseif child.command == "cs:et-al" then
         et_al_opts = child.options
      elseif child.command == "cs:label" then
         if not name_node then
            is_label_first = true
         end
         label_opts = child.options
      elseif child.command == "cs:name" then
         name_node = child
      end
   end
   if not name_node then
      name_node = { command = "cs:name", options = {} }
   end
   -- Build inherited options
   local inherited_opts = pl.tablex.union(self.inheritable[self.mode], options)
   name_node.options = pl.tablex.union(inherited_opts, name_node.options)
   name_node.options.form = name_node.options.form or inherited_opts["name-form"]
   local et_al_min = tonumber(name_node.options["et-al-min"]) or 4 -- No default in the spec, using Chicago's
   local et_al_use_first = tonumber(name_node.options["et-al-use-first"]) or 1
   local and_opt = name_node.options["and"] or "text"
   local and_word = and_opt == "symbol" and "&" or self.locale:term("and") -- text by default
   local name_delimiter = name_node.options.delimiter or inherited_opts["names-delimiter"]
   -- local delimiter_precedes_et_al = name_node.options["delimiter-precedes-et-al"] -- TODO NOT IMPLEMENTED see below

   local resolved = {
      variable = SU.required(name_node.options, "variable", "CSL names"),
      et_al_min = et_al_min,
      et_al_use_first = et_al_use_first,
      and_word = and_word,
      name_delimiter = name_delimiter,
      is_label_first = is_label_first,
      label_opts = label_opts,
      et_al_opts = et_al_opts,
      name_node = name_node,
      names_delimiter = options.delimiter or inherited_opts["names-delimiter"],
   }
   resolved = pl.tablex.union(options, resolved)

   return self:_names_with_resolved_opts(resolved, substitute, entry)
end

function CslEngine:_label (options, content, entry)
   local variable = SU.required(options, "variable", "CSL label")
   local value = entry[variable]
   self:_addGroupVariable(variable, value)
   if value then
      local plural = options.plural
      if plural == "always" then
         plural = true
      elseif plural == "never" then
         plural = false
      else -- "contextual" by default
         if variable == "number-of-pages" or variable == "number-of-volumes" then
            local  v = tonumber(value)
            plural = v and v > 1 or false
         else
            if type(value) == "table" then
               plural = #value > 1
            else
               local _, count = string.gsub(tostring(value), "%d+", "") -- naive count of numbers
               plural = count > 1
            end
         end
      end
      value = self.locale:term(variable, options.form or "long", plural)
      value = self:_render_stripPeriods(value, options)
      value = self:_render_textCase(value, options)
      value = self:_render_formatting(value, options)
      value = self:_render_affixes(value, options)
      return value
   end
   return value
end

function CslEngine:_group (options, content, entry)
   self:_enterGroup()

   local t = self:_render_children(content, entry, { delimiter = options.delimiter })
   t = self:_render_formatting(t, options)
   t = self:_render_affixes(t, options)
   t = self:_render_display(t, options)

   t = self:_leaveGroup(t) -- Takes care of group suppression
   return t
end

function CslEngine:_if (options, content, entry)
   local match = options.match or "all"
   local conds = {}
   if options.variable then
      local vars = pl.stringx.split(options.variable, " ")
      local cond = false
      for _, var in ipairs(vars) do
         if entry[var] then
            cond = true
            break
         end
      end
      table.insert(conds, cond)
   end
   if options.type then
      local cond = false
      local types = pl.stringx.split(options.type, " ")
      for _, typ in ipairs(types) do
         if entry.type == typ then
            cond = true
            break
         end
      end
      table.insert(conds, cond)
   end
   if options["is-numeric"] then
      local cond = true
      for _, var in ipairs(pl.stringx.split(options["is-numeric"], " ")) do
         -- TODO FIXME NOT IMPLEMENTED FULLY
         -- Content is considered numeric if it solely consists of numbers.
         -- Numbers may have prefixes and suffixes (“D2”, “2b”, “L2d”), and may
         -- be separated by a comma, hyphen, or ampersand, with or without
         -- spaces (“2, 3”, “2-4”, “2 & 4”). For example, “2nd” tests “true” whereas
         -- “second” and “2nd edition” test “false”.
         if not tonumber(entry[var]) then
            cond = false
            break
         end
      end
      table.insert(conds, cond)
   end
   if options["is-uncertain-date"] then
      local cond = true
      for _, var in ipairs(pl.stringx.split(options["is-uncertain-date"], " ")) do
         local d = type(entry[var]) == "table" and entry[var]
         if not (d and d.approximate) then
            cond = false
            break
         end
      end
      table.insert(conds, cond)
   end
   -- FIXME TODO other conditions: locator, position, disambiguate
   for _, v in ipairs({ "locator", "position", "disambiguate" }) do
      if options[v] then
         SU.warn("CSL if condition " .. v .. " not implemented yet")
      end
   end
   -- Apply match
   local matching = match ~= "any"
   for _, cond in ipairs(conds) do
      if match == "all" then
         if not cond then
            matching = false
            break
         end
      elseif match == "any" then
         if cond then
            matching = true
            break
         end
      elseif match == "none" then
         if cond then
            matching = false
            break
         end
      end
   end
   if matching then
      return self:_render_children(content, entry), true
      -- FIXME:
      -- The CSL specification says: "Delimiters from the nearest delimiters
      -- from the nearest ancestor delimiting element are applied within the
      -- output of cs:choose (i.e., the output of the matching cs:if,
      -- cs:else-if, or cs:else; see delimiter).""
      -- Ugh. This is rather obscure and not implemented yet (?)
   end
   return nil, false
end

function CslEngine:_choose (options, content, entry)
   for _, c in ipairs(content) do
      if c.command == "cs:if" or c.command == "cs:else-if" then
         local t, match = self:_if(c.options, c, entry)
         if match then
            return t
         end
      elseif c.command == "cs:else" then
         return self:_render_children(c, entry)
      end
   end
end

function CslEngine:_sort (options, content, entry)
   -- FIXME TODO
   -- Silent for now.
   -- SU.warn("CSL sort not implemented yet")
end

-- PROCESSING

function CslEngine:_render_node (node, entry)
   local callback = node.command:gsub("cs:", "_")
   if self[callback] then
      return self[callback](self, node.options, node, entry)
   else
      SU.warn("Unknown CSL element " .. node.command .. " (" .. callback .. ")")
   end
end

function CslEngine:_render_children (ast, entry, context)
   if not ast then
      return
   end
   local ret = {}
   context = context or {}
   for _, content in ipairs(ast) do
      if type(content) == "table" and content.command then
         local r = self:_render_node(content, entry)
         if r then
            table.insert(ret, r) --.. callback)
         end
      else
         SU.error("CSL unexpected content") -- Should not happen
      end
   end

   return #ret > 0 and self:_render_delimiter(ret, context.delimiter)
end

function CslEngine:_postrender (text)
   local rdquote = self.punctuation.close_quote
   local ldquote = self.punctuation.open_quote
   local rsquote = self.punctuation.close_inner_quote

   -- Typography: Ensure there are no double straight quotes left from the input.
   text = luautf8.gsub(text, "([%s%p])\"", "%1" .. ldquote)
   text = luautf8.gsub(text, "\"([%s%p])", rdquote .. "%1")
   -- HACK: punctuation-in-quote is applied globally, not just to generated quotes.
   -- Not so sure it's the intended behavior from the specification?
   if SU.boolean(self.locale.styleOptions["punctuation-in-quote"], false) then
      text = luautf8.gsub(text, "([" .. rdquote .. rsquote .. "]+)%s*([.,])", "%2%1")
   end
   -- HACK: fix some double punctuation issues.
   -- Maybe some more robust way to handle affixes and delimiters would be better?
   text = luautf8.gsub(text, "%.%.", ".")
   -- Typography: Prefer to have commas and periods inside italics.
   -- (Better looking if italic automated corrections are applied.)
   text = luautf8.gsub(text, "(</em>)([.,])", "%2%1")
   return text
end

function CslEngine:_process (entry, mode)
   if mode ~= "citation" and mode ~= "bibliography" then
      SU.error("CSL processing mode must be 'citation' or 'bibliography'")
   end
   self:_prerender(mode)
   -- Deep copy the entry as cs:substitute may remove fields
   entry = pl.tablex.deepcopy(entry)
   local ast = self[mode]
   if not ast then
      SU.error("CSL style has no " .. mode .. " definition")
   end
   local res = self:_render_children(ast, entry)
   return self:_postrender(res)
end

--- Generate a citation string.
-- @tparam table entry TList of CSL-JSON entries
-- @treturn string The citation string
function CslEngine:cite (entry)
   return self:_process(entry, "citation")
end

--- Generate a reference string.
-- @tparam table entry TList of CSL-JSON entries
-- @treturn string The reference string
function CslEngine:reference (entry)
   return self:_process(entry, "bibliography")
end

return {
   CslEngine = CslEngine,
}
