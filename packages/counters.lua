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
  for _, v in ipairs(romans) do --note that this is -not- ipairs.
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

SILE.formatCounter = function(options)
  if (options.display == "roman") then return romanize(options.value):lower() end
  if (options.display == "Roman") then return romanize(options.value) end
  if (options.display == "alpha") then return alpha(options.value) end
  return tostring(options.value);
end
  
SILE.registerCommand("increment-counter", function (options,content)
  local c = options.id
  if not(SILE.scratch.counters[c]) then
    SILE.scratch.counters[c] = { value= 0, display= "arabic" };
  end
  if (options["set-to"]) then 
    SILE.scratch.counters[c].value = tonumber(options["set-to"])
  else
    SILE.scratch.counters[c].value = SILE.scratch.counters[c].value + 1
  end
  if options.display then SILE.scratch.counters[c].display = options.display end
  -- SILE.typesetter:setpar(SILE.formatCounter(SILE.scratch.counters[c]))
end, "Increments the counter named by the <id> option")

SILE.registerCommand("set-counter", function (options, content) 
  local c = options.id;
  if not(SILE.scratch.counters[c]) then
    SILE.scratch.counters[c] = { value= 0, display= "arabic" };
  end
  if options.value then SILE.scratch.counters[c].value = tonumber(options.value) end
  if options.display then SILE.scratch.counters[c].display = options.display end
end, "Sets the counter named by the <id> option to <value>; sets its display type (roman/Roman/arabic) to type <display>.");


SILE.registerCommand("show-counter", function (options, content)
  local c = options.id;
  if not(SILE.scratch.counters[c]) then
    SILE.scratch.counters[c] = { value= 0, display= "arabic" };
  end    
  if options.display then SILE.scratch.counters[c].display = options.display end
  SILE.typesetter:setpar(SILE.formatCounter(SILE.scratch.counters[c]));
end, "Outputs the value of counter <id>, optionally displaying it with the <display> format.");

return [[\begin{document}

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

The available display types are: \code{arabic}, the default;
\code{alpha}, for alphabetic counting; 
\code{roman}, for lower-case Roman numerals; and \code{Roman} for upper-case
Roman numerals.}

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
\end{document}]]