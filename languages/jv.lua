local lpeg = require("lpeg")

local types = {
   "Bi",
   "Bi",
   "CSR",
   "Vs",
   "VI",
   "VI",
   "VI",
   "VI",
   "VI",
   "C",
   "C",
   "C",
   "VI",
   "VI",
   "VI",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "C",
   "N",
   "M",
   "M",
   "M",
   "M",
   "M",
   "M",
   "M",
   "M",
   "M",
   "CS",
   "CM",
   "CM",
   "V",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
   "Nd",
   "Nd",
   "Nd",
   "Nd",
   "Nd",
   "Nd",
   "Nd",
   "Nd",
   "Nd",
   "Nd",
   "x",
   "x",
   "x",
   "x",
   "x",
   "x",
}
local jv = {}
local P8 = function (c)
   return lpeg.P(luautf8.char(c))
end

for i = 1, #types do
   local cp = i - 1 + 0xA980
   local match = P8(cp)
   jv[types[i]] = jv[types[i]] and (jv[types[i]] + match) or match
end

jv.medial_ra = P8(0xA9BF)
jv.medial_ya = P8(0xA9BE)
jv.tarung = P8(0xA9B4)
jv.consonant = ((jv.C * jv.N) + jv.C + jv.VI)
jv.consonant_sign = jv.Bi + jv.CSR + jv.Vs + jv.CM
jv.syllable = (jv.consonant * jv.V) ^ -1
   * jv.consonant
   * ((jv.medial_ra ^ -1) * jv.medial_ya) ^ -1
   * (jv.M * jv.tarung ^ -1) ^ -1
   * jv.consonant_sign ^ 0

SILE.nodeMakers.jv = pl.class(SILE.nodeMakers.unicode)
function SILE.nodeMakers.jv:iterator (items)
   return coroutine.wrap(function ()
      local chunk = ""
      for i = 1, #items do
         local char = items[i].text
         chunk = chunk .. char
      end
      local i = 1
      local total = 0
      while total < #chunk do
         local syll = (lpeg.P(total) * lpeg.C(jv.syllable)):match(chunk)
         if syll then
            while i < #items do
               if items[i].index >= total + #syll then
                  break
               end
               self:addToken(items[i].text, items[i])
               i = i + 1
            end
            total = total + #syll
            self:makeToken()
            self:makePenalty(0)
         else
            self:dealWith(items[i])
            i = i + 1
            if i > #items then
               break
            end
            total = items[i].index
         end
      end
      self:makeToken()
   end)
end
