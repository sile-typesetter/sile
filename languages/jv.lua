local lpeg  = require("lpeg")
local chardata  = characters.data

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

local nonsyll = (1 - jv.syllable)^0
local breakpoint = { node = SILE.nodefactory.newPenalty({ penalty = 0 }) }

local utoke = function(text) -- Yuck
  local chunks = SU.splitUtf8(text)
  local tmp = {}
  for i = 1,#chunks do
    local cp = SU.codepoint(chunks[i])
    if chardata[cp] and chardata[cp].linebreak == "sp" then
      coroutine.yield({ string = table.concat(tmp, "") })
      tmp = {}
      coroutine.yield({ separator = chunks[i]})
    elseif chardata[cp] and (chardata[cp].linebreak == "ba" or  chardata[cp].linebreak == "zw") then
      coroutine.yield({ string = table.concat(tmp, "") })
      tmp = {}
      coroutine.yield({ node = SILE.nodefactory.newPenalty({ penalty = 0 }) })
    else
      tmp[#tmp+1] = chunks[i]
    end
  end
  coroutine.yield({ string = table.concat(tmp, "") })
end

SILE.tokenizers.jv = function(text)
  local chunk = text
  return coroutine.wrap(function()
    while chunk:len() > 0 do
      local end_syll = jv.syllable:match(chunk)
      if end_syll then
        coroutine.yield({ string = string.sub(chunk, 1, end_syll -1 ) })
        chunk = string.sub(chunk, end_syll)
        coroutine.yield(breakpoint)
      else
        local end_nonsyl = nonsyll:match(chunk)
        utoke(string.sub(chunk, 1, end_nonsyl -1 ))
        chunk = string.sub(chunk, end_nonsyl)
      end
    end
  end)
end