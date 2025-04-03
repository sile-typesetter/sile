-- Verkita originale por Fredrick BRENNAN (copypaste@kittens.ph) 2022-jare
-- Original file by Fredrick R. Brennan (copypaste@kittens.ph) in 2022

local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "eo"

local function eo_ordinal (n, _)
   if n == nil then
      n = ""
   end
   local a, h
   h = SILE.settings:get("languages.eo.ordinal.hyphenbefore") and "-" or ""
   a = h .. (SILE.settings:get("languages.eo.ordinal.raisedsuffix") and "ª" or "a")
   return n .. a
end

-- Copied from en.lua
local function digits (n)
   local i, ret = -1
   return function ()
      i, ret = i + 1, n % 10
      if n > 0 then
         n = math.floor(n / 10)
         return i, ret
      end
   end
end

-- Rezultas la vorton de la postulata nombra parametro
-- Returns the Esperanto name of the required number argument
local eo_string = function (num, _)
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
   vword = vword:match("^%s*(.*%S)") or ""

   return num == 0 and "nul" or vword
end

function language.declareSettings (_)
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
      SILE.typesetter:typeset(eo_ordinal())
      SILE.call("medskip", {})
   end, nil, nil, true)
end

-- TODO refactor
SU.formatNumber.eo = {
   string = eo_string,
   ordinal = eo_ordinal,
}

return language
