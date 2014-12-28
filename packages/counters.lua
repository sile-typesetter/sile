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