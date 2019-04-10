if not SILE.scratch.counters then SILE.scratch.counters = {} end
romans = {
  {1000, "M"},
  {900, "CM"}, {500, "D"}, {400, "CD"}, {100, "C"},
  {90, "XC"}, {50, "L"}, {40, "XL"}, {10, "X"},
  {9, "IX"}, {5, "V"}, {4, "IV"}, {1, "I"}
}

local function romanize(k)
  str = ""
  k = k + 0
  for _, v in ipairs(romans) do
    val, let = unpack(v)
    while k >= val do
      k = k - val
      str = str..let
    end
  end
  return str
end

local function alpha(n)
  local out = ""
  local a = string.byte("a")
  repeat
    n = n - 1
    out = string.char(n%26 + a) .. out
    n = (n - n%26)/26
  until n < 1
  return out
end

local icu
pcall( function () icu = require("justenoughicu") end)

SILE.formatCounter = function(options)
  -- If there is a language-specific formatter, use that.
  local lang = SILE.settings.get("document.language")
  if SILE.languageSupport.languages[lang] and SILE.languageSupport.languages[lang].counter then
    local res = SILE.languageSupport.languages[lang].counter(options)
    if res then return res end -- allow them to pass.
  end

  -- If we have ICU, try that
  if icu then
    local display = options.display

    -- Translate numbering style names which are different in ICU
    if display == "roman" then
      display = "romanlow"
    elseif display == "Roman" then
      display = "roman"
    end

    local ok, res = pcall(function() return icu.format_number(options.value, display) end)
    if ok then return res end
  end

  if (options.display == "roman") then return romanize(options.value):lower() end
  if (options.display == "Roman") then return romanize(options.value) end
  if (options.display == "alpha") then return alpha(options.value) end
  return tostring(options.value)
end

local _init = function (c)
  if not(SILE.scratch.counters[c]) then
    SILE.scratch.counters[c] = { value= 0, display= "arabic" }
  end
end

SILE.registerCommand("increment-counter", function (options,content)
  local c = options.id; _init(c)
  if (options["set-to"]) then
    SILE.scratch.counters[c].value = tonumber(options["set-to"])
  else
    SILE.scratch.counters[c].value = SILE.scratch.counters[c].value + 1
  end
  if options.display then SILE.scratch.counters[c].display = options.display end
end, "Increments the counter named by the <id> option")

SILE.registerCommand("set-counter", function (options, content)
  local c = options.id; _init(c)
  if options.value then SILE.scratch.counters[c].value = tonumber(options.value) end
  if options.display then SILE.scratch.counters[c].display = options.display end
end, "Sets the counter named by the <id> option to <value>; sets its display type (roman/Roman/arabic) to type <display>.")


SILE.registerCommand("show-counter", function (options, content)
  local c = options.id; _init(c)
  if options.display then SILE.scratch.counters[c].display = options.display end
  SILE.typesetter:setpar(SILE.formatCounter(SILE.scratch.counters[c]))
end, "Outputs the value of counter <id>, optionally displaying it with the <display> format.")

local _initml = function (c)
  if not(SILE.scratch.counters[c]) then
    SILE.scratch.counters[c] = { value= {0}, display= {"arabic"} }
  end
end

SILE.registerCommand("increment-multilevel-counter", function (options, content)
  local c = options.id; _initml(c)
  local this = SILE.scratch.counters[c]

  local currentLevel = #this.value
  local level = tonumber(options.level) or currentLevel
  if level == currentLevel then
    this.value[level] = this.value[level] + 1
  elseif level > currentLevel then
    while level > currentLevel do
      currentLevel = currentLevel + 1
      this.value[currentLevel] = (options.reset == false) and this.value[currentLevel -1 ] or 1
      this.display[currentLevel] = this.display[currentLevel - 1]
    end
  else -- level < currentLevel
    this.value[level] = this.value[level] + 1
    while currentLevel > level do
      if not (options.reset == false) then this.value[currentLevel] = nil end
      this.display[currentLevel] = nil
      currentLevel = currentLevel - 1
    end
  end
  if options.display then this.display[currentLevel] = options.display end
end)

SILE.registerCommand("show-multilevel-counter", function (options, content)
  local c = options.id; _initml(c)
  local this = SILE.scratch.counters[c]
  local currentLevel = #this.value
  local maxlevel = options.level or currentLevel
  local minlevel = options.minlevel or 1
  if options.display then this.display[currentLevel] = options.display end
  local out = {}
  for x = minlevel, maxlevel do
    out[x - minlevel + 1] = SILE.formatCounter({ display = this.display[x], value = this.value[x] })
  end
  SILE.typesetter:typeset(table.concat( out, "." ))
end, "Outputs the value of the multilevel counter <id>, optionally displaying it with the <display> format.")

return { documentation = [[\begin{document}

Various parts of SILE such as the \code{footnotes} package and the
sectioning commands keep a counter of things going on: the current
footnote number, the chapter number, and so on. The counters package
allows you to set up, increment and typeset named counters. It
provides the following commands:

• \code{\\set-counter[id=\em{<counter-name>},value=\em{<value}]} — sets
the counter called \code{<counter-name>} to the value given.

• \code{\\increment-counter[id=\em{<counter-name>}]} — does the
same as \code{\\set-counter} except that when no \code{value} parameter
is given, the counter is incremented by one.

• \code{\\show-counter[id=\em{<counter-name>}]} — this typesets the
value of the counter according to the counter’s declared display type.

\note{All of the commands in the counters package take an optional
\code{display=\em{<display-type>}} parameter
to set the \em{display type} of the counter.

The available built-in display types are: \code{arabic}, the default;
\code{alpha}, for alphabetic counting;
\code{roman}, for lower-case Roman numerals; and \code{Roman} for upper-case
Roman numerals.

The ICU library also provides ways of formatting numbers in global (non-Latin)
scripts. You can use any of the display types in this list:
\url{http://www.unicode.org/repos/cldr/tags/latest/common/bcp47/number.xml}.
For example, \code{display=beng} will format your numbers in Bengali digits.
}


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
\end{document}]] }
