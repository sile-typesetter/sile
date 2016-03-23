local lpeg  = require("lpeg")

local types = {
  "Bi", "Bi","CSR", "Vs", "VI", "VI", "VI", "VI",
  "VI",  "C",  "C",  "C", "VI", "VI", "VI",  "C",
   "C",  "C",  "C",  "C",  "C",  "C",  "C",  "C",
   "C",  "C",  "C",  "C",  "C",  "C",  "C",  "C",
   "C",  "C",  "C",  "C",  "C",  "C",  "C",  "C",
   "C",  "C",  "C",  "C",  "C",  "C",  "C",  "C",
   "C",  "C",  "C",  "N",  "M",  "M",  "M",  "M",
   "M",  "M",  "M",  "M",  "M", "CS", "CM", "CM",
  "V",  "x",  "x",  "x",  "x",  "x",  "x",  "x",
   "x",  "x",  "x",  "x",  "x",  "x",  "x",  "x",
  "Nd", "Nd", "Nd", "Nd", "Nd", "Nd", "Nd", "Nd",
  "Nd", "Nd",  "x",  "x",  "x",  "x",  "x",  "x"
}
jv = {}
local P8 = function (c) return lpeg.P(SU.utf8char(c)) end

for i = 1, #types do
  local cp = i - 1 + 0xA980
  local match = P8(cp)
  jv[types[i]] = jv[types[i]] and (jv[types[i]]+match) or match
end

jv.medial_ra = P8(0xA9BF)
jv.medial_ya = P8(0xA9BE)
jv.tarung    = P8(0xA9B4)
jv.consonant = ((jv.C * jv.N) + jv.C + jv.VI)
jv.consonant_sign = jv.Bi + jv.CSR + jv.Vs + jv.CM
jv.syllable = (jv.consonant * jv.V)^-1 * jv.consonant *
  ((jv.medial_ra^-1) * jv.medial_ya)^-1 *
  (jv.M * jv.tarung^-1)^-1 *
  jv.consonant_sign^0

SILE.nodeMakers.jv = SILE.nodeMakers.unicode {
  iterator = function (self, items)
    local chunk = ""
    return coroutine.wrap(function()
      self:init()
      for i = 1,#items do item = items[i]
        local char = items[i].text
        local end_syll = (jv.syllable):match(char)
        if end_syll then
          self:addToken(char,item)
          self:makeToken()
          self:makePenalty(0)
        else
          self:addToken(char,item)
        end
      end
      self:makeToken()
    end)
  end
}