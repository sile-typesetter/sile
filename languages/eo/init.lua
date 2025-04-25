-- Verkita originale por Fredrick BRENNAN (copypaste@kittens.ph) 2022-jare
-- Original file by Fredrick R. Brennan (copypaste@kittens.ph) in 2022

local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "eo"

function language:declareSettings ()
   SILE.settings:declare({
      parameter = "languages.eo.ordinal.raisedsuffix",
      type = "boolean",
      default = false,
      help = "Whether to use “ª” or “a” as Esperanto ordinal suffix",
   })
   SILE.settings:declare({
      parameter = "languages.eo.ordinal.hyphenbefore",
      type = "boolean",
      default = false,
      help = "Whether to put a hyphen (-) before Esperanto ordinal suffix",
   })
end

function language:registerCommands ()
   self:registerCommand("book:chapter:post:eo", function ()
      SILE.typesetter:typeset(self:numberToOrdinal())
      SILE.call("medskip", {})
   end, nil, nil, true)
end

function language:numberToOrdinal (num)
   if num == nil then
      num = ""
   end
   local a, h
   h = SILE.settings:get("languages.eo.ordinal.hyphenbefore") and "-" or ""
   a = h .. (SILE.settings:get("languages.eo.ordinal.raisedsuffix") and "ª" or "a")
   return num .. a
end

-- Copied from en.lua
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

-- Rezultas la vorton de la postulata nombra parametro
-- Returns the Esperanto name of the required number argument
function language:numberToString (num)
   -- typos: ignore start
   local words = { "unu", "du", "tri", "kvar", "kvin", "ses", "sep", "ok", "naŭ", [0] = "" }
   local levels = { "mil", "miliono", "miliardo", [0] = "" }
   -- typos: ignore end
   local ten = "dek"
   local hundred = "cent"
   for i = 2, 8, 1 do
      table.insert(levels, 2 + i, words[i] .. "iliono")
      table.insert(levels, 2 + i + 1, words[i] .. "iliardo")
   end

   local level = false
   local function getname (pos, dig) --"stateful, but effective." ~ en_string
      level = level or (pos % 3 == 0)
      if dig == 0 then
         return ""
      end
      local dig_name
      if dig == 1 and pos ~= 0 then
         dig_name = ""
      else
         dig_name = words[dig]
      end
      local name = (pos % 3 == 2 and dig_name .. " " .. hundred .. " " or dig_name .. " ")
         .. (pos % 3 == 1 and ten .. " " or "")
      if level then
         name, level =
            name
               .. levels[math.floor(pos / 3)]
               .. ((dig > 1 and pos > 5) and "j" or "")
               .. (pos > 5 and " kaj" or "")
               .. " ",
            false
      end
      return name
   end

   local vword = ""

   for i, v in digits(num) do
      vword = getname(i, v) .. vword
   end

   vword = vword:gsub(" kaj $", "")
   vword = pl.stringx.strip(vword)

   return num == 0 and "nul" or vword
end

return language
