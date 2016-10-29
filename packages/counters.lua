if not SILE.scratch.counters then SILE.scratch.counters = {} end
romans = {
  {1000, "M"},
  {900, "CM"}, {500, "D"}, {400, "CD"}, {100, "C"},
  {90, "XC"}, {50, "L"}, {40, "XL"}, {10, "X"},
  {9, "IX"}, {5, "V"}, {4, "IV"}, {1, "I"}
}

abjads = {
  {1000, "غ"},
  {900, "ظ"}, {800, "ض"}, {700, "ذ"}, {600, "خ"}, {500, "ث"}, {400, "ت"}, {300, "ش"}, {200, "ر"}, {100, "ق"},
  {90, "ص"},  {80, "ف"},  {70, "ع"},  {60, "س"},  {50, "ن"},  {40, "م"},  {30, "ل"},  {20, "ك"},  {10, "ي"},
  {9, "ط"},   {8, "ح"},   {7, "ز"},   {6, "و"},   {5, "ه"},   {4, "د"},   {3, "ج"},   {2, "ب"},   {1, "ا"},
}

local function alphabeticize(k, map)
  str = ""
  k = k + 0
  for _, v in ipairs(map) do
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

local function arabicIndic(n)
  local out,_ = tostring(n):gsub(".", function(d)
    return SILE.utilities.utf8char(tonumber(d) + 0x0660)
  end)
  return out
end

SILE.formatCounter = function(options)
  if (options.display == "roman") then return alphabeticize(options.value, romans):lower() end
  if (options.display == "Roman") then return alphabeticize(options.value, romans) end
  if (options.display == "alpha") then return alpha(options.value) end
  if (options.display == "arabic-indic") then return arabicIndic(options.value) end
  if (options.display == "abjad") then return alphabeticize(options.value, abjads) end
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
      this.value[currentLevel] = 1
      this.display[currentLevel] = this.display[currentLevel -1]
    end
  else -- level < currentLevel
    this.value[level] = this.value[level] + 1
    while currentLevel > level do
      this.value[currentLevel] = nil
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

The available display types are:

• \code{arabic}, the default.

• \code{alpha}, for alphabetic counting.

• \code{roman}, for lower-case Roman numerals, and \code{Roman} for upper-case Roman numerals.

• \code{arabic-indic}, for Arabic-Indic numerals.

• \code{abjad}, for Arabic Abjad numerals.

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
