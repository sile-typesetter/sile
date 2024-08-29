-- typos: ignore start
local function charclass (u)
   if (u >= 0x1000 and u <= 0x102A) or u == 0x104E or u == 0x25CC or u == 0x2d then
      return "CI"
   end
   if u == 0x1039 then
      return "VI"
   end
   if u >= 0x103B and u <= 0x103E then
      return "ME"
   end
   if u == 0x1031 then
      return "EV"
   end
   if u == 0x102F or u == 0x1030 then
      return "LV"
   end
   if u == 0x102D or u == 0x102E or u == 0x1032 then
      return "UV"
   end
   if u == 0x102C or u == 0x102B then -- 0x102b added by SC because it was splitting visargas
      return "AV"
   end
   if u == 0x1036 then
      return "AN"
   end
   if u == 0x103A then
      return "KI"
   end
   if u == 0x1037 then
      return "LD"
   end
   if u == 0x1038 then
      return "VG"
   end
   if u >= 0x1040 and u <= 0x1049 then
      return "MD"
   end
   if u == 0x104A or u == 0x104B or u == 0x2c or u == 0x2e or u == 0x3a or u == 0x3b then
      return "SE"
   end
   if u == 0x104C or u == 0x104D or u == 0x104F then
      return "VS"
   end
   if u >= 0x1050 and u <= 0x1055 then
      return "PL"
   end
   if u >= 0x1056 and u <= 0x1059 then
      return "PV"
   end
   if u == 0x20 or (u >= 0x2000 and u <= 0x200b) then
      return "SP"
   end
   if u == 0x28 or u == 0x5b or u == 0x7b or u == 0xab or u == 0x2018 or u == 0x201C or u == 0x2039 then
      return "LQ"
   end
   if u == 0x29 or u == 0x5d or u == 0x7d or u == 0xbb or u == 0x2019 or u == 0x201d or u == 0x203a then
      return "RQ"
   end
   if u == 0x200c then
      return "NJ"
   end
   if u == 0x2060 or u == 0x200d then
      return "WJ"
   end
   return "OT"
end
-- typos: ignore end

-- "Syllable Based Dual Weight Algorithm for Line Breaking in Myanmar Unicode"
-- Keith Stribley, http://thanlwinsoft.github.io/www.thanlwinsoft.org/ThanLwinSoft/MyanmarUnicode/Parsing/my2weightLineBreakAlg1_1.pdf
local p2 = SILE.types.node.penalty({ penalty = -25 })
local p1 = SILE.types.node.penalty({ penalty = -50 })

-- typos: ignore start
local penaltyFor = function (ca, cb)
   if ca == "WJ" or ca == "LQ" then
      return
   end
   if cb == "RQ" or cb == "WJ" then
      return
   end
   if ca == "OT" then
      return p1
   end
   if ca == "RQ" then
      return p2
   end
   if cb == "LQ" then
      return p2
   end
   if cb == "CI" then
      if ca == "AN" or ca == "KI" or ca == "LD" or ca == "VG" or ca == "PL" or ca == "PV" or ca == "RQ" then
         return p2
      end
      if ca == "MD" or ca == "SE" or ca == "VS" or ca == "SP" then
         return p1
      end
      return
   end
   if ca == "MD" and not (cb == "VI" or cb == "MD") then
      return p1
   end
   if cb == "PL" then
      if ca == "VI" then
         return
      end
      if ca == "SE" or ca == "VB" then
         return p1
      end
      return p2
   end
end
-- typos: ignore end

SILE.tokenizers.my = function (string)
   return coroutine.wrap(function ()
      local lastclass = ""
      local collection = ""
      for uchar in string.gmatch(string, "([%z\1-\127\194-\244][\128-\191]*)") do
         local thiscp = SU.codepoint(uchar)
         local thisclass = charclass(thiscp)
         if thisclass == "SP" then
            coroutine.yield({ separator = uchar })
         else
            local pen = penaltyFor(lastclass, thisclass)
            if pen then
               coroutine.yield({ node = pen })
               coroutine.yield({ string = collection })
               collection = ""
            end
            collection = collection .. uchar
         end
         lastclass = thisclass
      end
      coroutine.yield({ string = collection })
   end)
end
