local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "en"

local function digits (num)
   local i, ret = -1
   return function ()
      i, ret = i + 1, num % 10
      if num > 0 then
         num = math.floor(num / 10)
         return i, ret
      end
   end
end

function language:numberToString (num)
   local words = { "one ", "two ", "three ", "four ", "five ", "six ", "seven ", "eight ", "nine " }
   local levels = {
      "thousand ",
      "million ",
      "billion ",
      "trillion ",
      "quadrillion ",
      "quintillion ",
      "sextillion ",
      "septillion ",
      "octillion ",
      [0] = "",
   }
   local iwords = { "ten ", "twenty ", "thirty ", "forty ", "fifty ", "sixty ", "seventy ", "eighty ", "ninety " }
   local twords =
      { "eleven ", "twelve ", "thirteen ", "fourteen ", "fifteen ", "sixteen ", "seventeen ", "eighteen ", "nineteen " }

   local level = false
   local function getname (pos, dig) --stateful, but effective.
      level = level or pos % 3 == 0
      if dig == 0 then
         return ""
      end
      local name = (pos % 3 == 1 and iwords[dig] or words[dig]) .. (pos % 3 == 2 and "hundred " or "")
      if level then
         name, level = name .. levels[math.floor(pos / 3)], false
      end
      return name
   end

   local vword = ""

   for i, v in digits(num) do
      vword = getname(i, v) .. vword
   end

   for i, v in ipairs(words) do
      vword = vword:gsub("ty " .. v, "ty-" .. v)
      vword = vword:gsub("ten " .. v, twords[i])
   end

   return num == 0 and "zero" or vword:sub(1, -2)
end

return language
