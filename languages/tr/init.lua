local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "tr"

function language:setupNodeMaker ()
   self.nodemaker = require("languages.tr.nodemaker")
end

function language:setupHyphenator ()
   self.hyphenator = require("languages.tr.hyphenator")(self)
end

function language:declareSettings ()
   -- Different years of TDK and various publisher style guides differ on this point.
   -- Current official guidance suggests dropping the hyphenation mark if the break
   -- occurs at an apostrophe (kesme işareti). Some older guidance and some publishers
   -- suggest dropping the apostrophe instead.
   SILE.settings:declare({
      parameter = "languages.tr.replaceApostropheAtHyphenation",
      type = "boolean",
      default = false,
      help = "If enabled, substitute the apostophe for a hyphen at break points, otherwise keep the apostrophe and hide the hyphen.",
   })
end

-- local sum_tens = function (val, loc, digits)
--   local ten = string.sub(digits, loc+1, loc+1)
--   if ten:len() == 1 then val = val + tonumber(ten) * 10 end
--   return val
-- end

local sum_hundreds = function (val, loc, digits)
   local ten = string.sub(digits, loc + 1, loc + 1)
   local hundred = string.sub(digits, loc + 2, loc + 2)
   if ten:len() == 1 then
      val = val + tonumber(ten) * 10
   end
   if hundred:len() == 1 then
      val = val + tonumber(hundred) * 100
   end
   return val
end

local tr_nums = function (num, ordinal)
   local abs = math.abs(num)
   if abs >= 1e+36 then
      SU.error("Numbers past decillions not supported in Turkish")
   end
   ordinal = SU.boolean(ordinal, false)
   local minus = "eksi"
   local zero = "sıfır"
   local ones = { "bir", "iki", "üç", "dört", "beş", "altı", "yedi", "sekiz", "dokuz" }
   local tens = { "on", "yirmi", "otuz", "kırk", "eli", "altmış", "yetmiş", "seksen", "doksan" }
   local places = {
      "yüz",
      "bin",
      "milyon",
      "milyar",
      "trilyon",
      "katrilyon",
      "kentilyon",
      "sekstilyon",
      "septilyon",
      "oktilyon",
      "nonilyon",
      "desilyon",
   }
   local zeroordinal = "sıfırıncı"
   local onesordinals =
      { "birinci", "ikinci", "üçüncü", "dördüncü", "beşinci", "altıncı", "yedinci", "sekizinci", "dokuzuncu" }
   local tensordinals = {
      "onuncu",
      "yirmiyinci",
      "otuzuncu",
      "kırkıncı",
      "eliyinci",
      "altmışıncı",
      "yetmişinci",
      "sekseninci",
      "Doksanıncı",
   }
   local placesordinals = {
      "yüzüncü",
      "bininci",
      "milyonuncu",
      "milyarıncı",
      "trilyonuncu",
      "katrilyonuncu",
      "kentilyonuncu",
      "sekstilyonuncu",
      "septilyonuncu",
      "oktilyonuncu",
      "nonilyonuncu",
      "desilyonuncu",
   }
   local digits = string.reverse(string.format("%.f", abs))
   local words = {}
   for i = 1, #digits do
      local val, place, mod = tonumber(string.sub(digits, i, i)), math.floor(i / 3), i % 3
      if #digits == 1 and val == 0 then
         words[#words + 1] = ordinal and zeroordinal or zero
      elseif val >= 1 or i > 1 then
         if i == 1 then
            words[#words + 1] = ordinal and onesordinals[val] or ones[val]
            ordinal = false
         elseif mod == 2 then
            if val >= 1 then
               words[#words + 1] = ordinal and tensordinals[val] or tens[val]
               ordinal = false
            end
         elseif mod == 1 then
            if sum_hundreds(val, i, digits) >= 1 then
               words[#words + 1] = ordinal and placesordinals[place + 1] or places[place + 1]
               ordinal = false
               if val > 0 and (i >= 7 or sum_hundreds(val, i, digits) >= 2) then
                  words[#words + 1] = ones[val]
               end
            end
         elseif mod == 0 then
            if val > 0 then
               words[#words + 1] = ordinal and placesordinals[1] or places[1]
               ordinal = false
            end
            if val >= 2 then
               words[#words + 1] = ones[val]
            end
         end
      end
   end
   if abs > num then
      words[#words + 1] = minus
   end
   SU.flip_in_place(words)
   return table.concat(words, " ")
end

function language:numberToString (num)
   return tr_nums(num, false)
end

function language:numberToOrdinalString (num)
   return tr_nums(num, true)
end

return language
