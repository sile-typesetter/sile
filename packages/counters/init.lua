local base = require("packages.base")

local package = pl.class(base)
package._name = "counters"

SILE.formatCounter = function (counter)
  SU.deprecated("SILE.formatCounter", "class:formatCounter", "0.13.0", "0.15.0")
  return package.formatCounter(nil, counter)
end

SILE.formatMultilevelCounter = function (counter, options)
  SU.deprecated("SILE.formatMultilevelCounter", "class:formatMultilevelCounter", "0.13.0", "0.15.0")
  return package.formatMultilevelCounter(nil, counter, options)
end

local function getCounter (_, id)
  local counter = SILE.scratch.counters[id]
  if not counter then
    counter = {
      value = 0,
      display = "arabic",
      format = package.formatCounter
    }
    SILE.scratch.counters[id] = counter
  elseif type(counter.value) ~= "number" then
    SU.error("Counter " .. id .. " is not a single-level counter")
  end
  return counter
end

local function getMultilevelCounter (_, id)
  local counter = SILE.scratch.counters[id]
  if not counter then
    counter = {
      value = { 0 },
      display = { "arabic" },
      format = package.formatMultilevelCounter
    }
    SILE.scratch.counters[id] = counter
  elseif type(counter.value) ~= "table" then
    SU.error("Counter " .. id .. " is not a multi-level counter")
  end
  return counter
end

function package.formatCounter (_, counter)
  return SU.formatNumber(counter.value, counter.display)
end

function package:formatMultilevelCounter (counter, options)
  options = options or {}
  local maxlevel = options.level and SU.min(SU.cast("integer", options.level), #counter.value) or #counter.value
  -- Option minlevel is undocumented and should perhaps be deprecated: is there a real use case for it?
  local minlevel = options.minlevel and SU.min(SU.cast("integer", options.minlevel, #counter.value)) or 1
  local out = {}
  if SU.boolean(options.noleadingzeros, false) then
    while counter.value[minlevel] == 0 do minlevel = minlevel + 1 end -- skip leading zeros
  end
  for x = minlevel, maxlevel do
    out[x - minlevel + 1] = self:formatCounter({ display = counter.display[x], value = counter.value[x] })
  end
  return table.concat(out, ".")
end

function package:_init ()
  base._init(self)
  if not SILE.scratch.counters then
    SILE.scratch.counters = {}
  end
  self:export("getCounter", getCounter)
  self:export("getMultilevelCounter", getMultilevelCounter)
  self:deprecatedExport("formatCounter", self.formatCounter)
  self:deprecatedExport("formatMultilevelCounter", self.formatMultilevelCounter)
end

function package:registerCommands ()

  self:registerCommand("increment-counter", function (options, _)
    local id = SU.required(options, "id", "increment-counter")

    local counter = self.class:getCounter(id)
    if (options["set-to"]) then
      SU.deprecated("\\increment-counter[set-to=...]", '\\set-counter[value=...]', "0.14.4", "0.16.0")
      -- An increment command that does a set is plain weird...
      counter.value = SU.cast("integer", options["set-to"])
    else
      counter.value = counter.value + 1
    end
    if options.display then counter.display = options.display end
  end, "Increments the counter named by the <id> option")

  self:registerCommand("set-counter", function (options, _)
    local id = SU.required(options, "id", "set-counter")

    local counter = self.class:getCounter(id)
    if options.value then counter.value = SU.cast("integer", options.value) end
    if options.display then counter.display = options.display end
  end, "Sets the counter named by the <id> option to <value>; sets its display type (roman/Roman/arabic) to type <display>.")


  self:registerCommand("show-counter", function (options, _)
    local id = SU.required(options, "id", "show-counter")

    local counter = self.class:getCounter(id)
    if options.display then
      SU.deprecated("\\show-counter[display=...]", '\\set-counter[display=...]', "0.14.4", "0.16.0")
      counter.display = options.display
    end
    SILE.typesetter:typeset(self:formatCounter(counter))
  end, "Outputs the value of counter <id>, optionally displaying it with the <display> format.")

  self:registerCommand("increment-multilevel-counter", function (options, _)
    local id = SU.required(options, "id", "increment-multilevel-counter")

    local counter = self.class:getMultilevelCounter(id)
    local currentLevel = #counter.value
    local level = SU.cast("integer", options.level or currentLevel)
    local reset = SU.boolean(options.reset, true)
    -- Option reset=false is undocumented and was previously somewhat broken.
    -- It should perhaps be deprecated: is there a real use case for it?
    if level == currentLevel then
      counter.value[level] = counter.value[level] + 1
    elseif level > currentLevel then
      while level - 1 > currentLevel do
        currentLevel = currentLevel + 1
        counter.value[currentLevel] = 0
        counter.display[currentLevel] = counter.display[currentLevel - 1]
      end
      currentLevel = currentLevel + 1
      counter.value[level] = 1
      counter.display[level] = counter.display[currentLevel - 1]
    else -- level < currentLevel
      counter.value[level] = counter.value[level] + 1
      while currentLevel > level do
        if reset then
          counter.value[currentLevel] = nil
          counter.display[currentLevel] = nil
        end
        currentLevel = currentLevel - 1
      end
    end
    if options.display then counter.display[currentLevel] = options.display end
  end, "Increments the value of the multilevel counter <id> at the given <level> or the current level.")

  self:registerCommand("set-multilevel-counter", function (options, _)
    local level = SU.cast("integer", SU.required(options, "level", "set-multilevel-counter"))
    local id = SU.required(options, "id", "set-multilevel-counter")

    local counter = self.class:getMultilevelCounter(id)
    local currentLevel = #counter.value
    if options.value then
      local value = SU.cast("integer", options.value)
      if level == currentLevel then
        -- e.g. set to x the level 3 of 1.2.3 => 1.2.x
        counter.value[level] = value
      elseif level > currentLevel then
        -- Fill all missing levels in-between, assuming same display format.
        -- e.g. set to x the level 3 of 1 => 1.0.x
        while level - 1 > currentLevel do
          currentLevel = currentLevel + 1
          counter.value[currentLevel] = 0
          counter.display[currentLevel] = counter.display[currentLevel - 1]
        end
        currentLevel = currentLevel + 1
        counter.value[level] = value
        counter.display[level] = counter.display[currentLevel - 1]
      else -- level < currentLevel
        -- Reset all upper levels
        -- e.g. set to x the level 2 of 1.2.3 => 1.x
        counter.value[level] = value
        while currentLevel > level do
          counter.value[currentLevel] = nil
          counter.display[currentLevel] = nil
          currentLevel = currentLevel - 1
        end
      end
    end
    if options.display then
      if level <= #counter.value then
         counter.display[level] = options.display
      else
        SU.warn("Ignoring attempt to set the display of a multilevel counter beyond its level")
      end
     end
  end, "Sets the multilevel counter named by the <id> option to <value> at level <level>; optionally sets its display type at that level to <display>.")

  self:registerCommand("show-multilevel-counter", function (options, _)
    local id = SU.required(options, "id", "show-multilevel-counter")

    local counter = self.class:getMultilevelCounter(id)
    if options.display then
      SU.deprecated("\\show-multilevel-counter[display=...]", '\\set-multilevel-counter[display=...]', "0.14.4", "0.16.0")
      counter.display[#counter.value] = options.display
    end

    SILE.typesetter:typeset(self:formatMultilevelCounter(counter, options))
  end, "Outputs the value of the multilevel counter <id>.")

end

package.documentation = [[
\begin{document}

Various parts of SILE such as the \autodoc:package{footnotes} package and the sectioning commands keep a counter of things going on: the current footnote number, the chapter number, and so on.
The counters package allows you to set up, increment and typeset named counters.
It provides the following commands:

\begin{itemize}
\item{\autodoc:command{\set-counter[id=<counter-name>, value=<value>]} — sets the counter with the specified name to the given value.}
\item{\autodoc:command{\increment-counter[id=<counter-name>]} — does the same as \autodoc:command{\set-counter} except that when no \autodoc:parameter{value} parameter is given, the counter is incremented by one.}
\item{\autodoc:command{\show-counter[id=<counter-name>]} — this typesets the value of the counter according to the counter’s declared display type.}
\end{itemize}

All of the commands in the counters package take an optional \autodoc:parameter{display=<display-type>} parameter to set the \em{display type} of the counter.

The available built-in display types are:

\begin{itemize}
\item{\code{arabic}, the default;}
\item{\code{alpha}, for lower-case alphabetic counting;}
\item{\code{Alpha}, for upper-case alphabetic counting;}
\item{\code{roman}, for lower-case Roman numerals; and,}
\item{\code{Roman} for upper-case Roman numerals.}
\end{itemize}

The ICU library also provides ways of formatting numbers in global (non-Latin) scripts.
You can use any of the display types in this list: \url{http://www.unicode.org/repos/cldr/tags/latest/common/bcp47/number.xml}.
For example, \autodoc:parameter{display=beng} will format your numbers in Bengali digits.

So, for example, the following SILE code:

\begin{verbatim}
\line
\\set-counter[id=mycounter, value=2]
\\show-counter[id=mycounter]

\\increment-counter[id=mycounter]
\\show-counter[id=mycounter, display=roman]
\line
\end{verbatim}

produces:

\line
\examplefont{2

\noindent{}iii}
\line
\end{document}
]]

return package
