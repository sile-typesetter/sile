--
-- EAN-13 barcodes for SILE.
-- Didier Willis, 2022.
-- License: MIT
--
local base = require("packages.base")

local package = pl.class(base)
package._name = "barcodes.ean13"

-- Useful references:
-- GS1 specifications
--   https://www.gs1.org/docs/barcodes/GS1_General_Specifications.pdf
-- TUGBoat article
--   https://tug.org/TUGboat/Articles/tb15-4/tb45olsa.pdf
-- OCR-B font
--   https://tsukurimashou.osdn.jp/ocr.php.en (Matthew Skala, July 1, 2021)

-- Tables for encoding the EAN-13 bars (i.e. number patterns).
local tableNumberBars = {
  A = { "3211", "2221", "2122", "1411", "1132", "1231", "1114", "1312", "1213", "3112" },
  B = { "1123", "1222", "2212", "1141", "2311", "1321", "4111", "2131", "3121", "2113" },
}

-- EAN-13 guard patterns.
local NORMAL_GUARD = "111"
local CENTER_GUARD = "11111"
local ADDON_GUARD = "112"
local ADDON_DELINEATOR = "11"

-- Selection table for encoding the EAN-13 main part.
local tableCode = { "AAAAAA", "AABABB", "AABBAB", "AABBBA", "ABAABB", "ABBAAB", "ABBBAA", "ABABAB", "ABABBA", "ABBABA" }

-- Selection table for encoding the EAN-13 add-on (supplement) part.
local tableAddOn2 = { "AA", "AB", "BA", "BB" }
local tableAddOn5 = { "BBAAA", "BABAA", "BAABA", "BAAAB", "ABBAA", "AABBA", "AAABB", "ABABA", "ABAAB", "AABAB" }

-- Usual module sizes:
-- The SC names are not defined in GS1 but are "quite" standard in the industry.
local SC = {
  SC0 = 0.264, -- SC0 (80%)
  SC1 = 0.297, -- SC1 (90%)
  SC2 = 0.330, -- SC2 (100%) (default, recommended on a "consumer item")
  SC3 = 0.363, -- SC3 (110%)
  SC4 = 0.396, -- SC4 (120%)
  SC5 = 0.445, -- SC5 (135%)
  SC6 = 0.495, -- SC6 (150%) (minimum recommended for an "outer packaging")
  SC7 = 0.544, -- SC7 (165%)
  SC8 = 0.610, -- SC8 (185%)
  SC9 = 0.660, -- SC9 (200%) (recommended on an "outer packaging")
}

-- EAN-13 check and encode functions.

local function verifyEan13 (text)
  local evens = 0
  local odds = 0
  for i = 1, 12, 2 do
    local digit = tonumber(text:sub(i,i))
    if not digit then SU.error("Invalid EAN-13 '"..text.."' (shall contain only digits)") end
    odds = odds + digit
  end
  for i = 2, 12, 2 do
    local digit = tonumber(text:sub(i,i))
    if not digit then SU.error("Invalid EAN-13 '"..text.."' (shall contain only digits)") end
    evens = evens + digit
  end
  local tot = 3 * evens + odds
  local n = math.ceil(tot/10) * 10
  local control = text:sub(13,13)
  if (n - tot) ~= tonumber(control) then SU.error("Invalid EAN-13 check digit (expected "..(n-tot)..", found "..control..")") end
end

local function ean13 (text)
  if type(text) ~= "string" or #text ~= 13 then SU.error("Invalid EAN-13 '"..text.."'") end
  verifyEan13(text)

  local pattern = NORMAL_GUARD
  -- The first digit determines which table (A or B) is picked for the first
  -- half of the code
  local selector = tableCode[tonumber(text:sub(1,1)) + 1]
  for i = 2, 7 do
    local selectedTable = selector:sub(i-1,i-1)
    local digit = tonumber(text:sub(i,i)) + 1
    local pat = tableNumberBars[selectedTable][digit]
    pattern = pattern .. pat
  end
  pattern = pattern .. CENTER_GUARD
  -- The second half of the code always follows table A.
  for i = 8, 13 do
    local digit = tonumber(text:sub(i,i)) + 1
    local pat = tableNumberBars.A[digit]
    pattern = pattern .. pat
  end
  pattern = pattern .. NORMAL_GUARD
  return pattern
end

local function ean13addOn2 (text)
  if type(text) ~= "string" or #text ~= 2 then SU.error("Invalid EAN-13 2-digit add-on '"..text.."'") end

  -- The 4-modulus of the numeric value determines how table A and B are used.
  local V = tonumber(text)
  local selector = tableAddOn2[V % 4 + 1]

  local pattern = ADDON_GUARD
  for i = 1, 2 do
    local selectedTable = selector:sub(i,i)
    local digit = tonumber(text:sub(i,i)) + 1
    local pat = tableNumberBars[selectedTable][digit]
    pattern = pattern .. pat
    if i < 2 then
      pattern = pattern .. ADDON_DELINEATOR
    end
  end
  return pattern
end

local function ean13addOn5 (text)
  if type(text) ~= "string" or #text ~= 5 then SU.error("Invalid EAN-13 5-digit add-on '"..text.."'") end

  -- The unit's position in V dertermines how table A and B are used.
  -- V being defined as 3 times the sum of odd-position chars + 9 times the sum of even-position chars.
  local V = (tonumber(text:sub(1,1)) + tonumber(text:sub(3,3)) + tonumber(text:sub(5,5))) * 3
              + (tonumber(text:sub(2,2)) + tonumber(text:sub(4,4))) * 9
  local VU = V % 10
  local selector = tableAddOn5[VU + 1]

  local pattern = ADDON_GUARD
  for i = 1, 5 do
    local selectedTable = selector:sub(i,i)
    local digit = tonumber(text:sub(i,i)) + 1
    local pat = tableNumberBars[selectedTable][digit]
    pattern = pattern .. pat
    if i < 5 then
      pattern = pattern .. ADDON_DELINEATOR
    end
  end
  return pattern
end

local function setupHumanReadableFont (family)
  SILE.scratch.ean13.font.family = family

  SILE.call("font", { family = SILE.scratch.ean13.font.family, size = 10 }, function ()
    local c = SILE.shaper:measureChar("0") -- Here we assume a monospace font...
    -- The recommended typeface for the human readable interpretation is OCR-B
    -- at a height of 2.75mm at standard X, i.e. approx. 8.3333X.
    -- The minimum space between the top of the digits and the bottom of the bars
    -- SHALL however be 0.5X. We could therefore make the font height 7.8333X, but
    -- that could be too wide, and a digit shall not be wider than 7X...
    -- The size of the human readable interpretation is not that important,
    -- according to the standard... So we just compute a decent ratio based on the
    -- above rules. I just checked it looked "correct" with OCR B, FreeMono, and a
    -- bunch of other monospace fonts.
    local maxHRatio = 7.8333
    local rh = c.height / maxHRatio -- height ratio to 7.8333
    local rw = c.width / 7 -- width ratio to 7
    local ratio = (rh < rw) and maxHRatio * rh / rw or maxHRatio
    SILE.scratch.ean13.font.size = 10 * ratio / c.height
    SILE.scratch.ean13.font.width = c.width / 10 * SILE.scratch.ean13.font.size
  end)
end

if not SILE.scratch.ean13 then
  SILE.scratch.ean13 = { font = {} }
  setupHumanReadableFont("OCR B")
end

function package:_init (_)
  base._init(self)
  self.class:loadPackage("raiselower")
  self.class:loadPackage("rules")
  SILE.call("ean13:font", { family = "OCR B" })
end

function package:registerCommands ()
  self:registerCommand("ean13", function (options, _)
    local code = SU.required(options, "code", "valid EAN-13 code")
    local scale = options.scale or "SC2"
    local corr = SU.boolean(options.correction, true)
    local addon = options.addon

    code = code:gsub("-","")
    if code:match("%D") ~= nil then
      SU.error("Invalid EAN-13 code '"..code.."'")
    end

    local module = SC[scale]
    if not module then SU.error("Invalid EAN scale (SC0 to SC9): "..scale) end

    local X = SILE.length(module.."mm")
    local H = 69.242424242 -- As per the standard, a minimal 22.85mm at standard X
    local offsetcorr = corr and SILE.length("0.020mm") or SILE.length()

    local pattern = ean13(code)

    SILE.call("kern", { width = 11 * X }) -- Left Quiet Zone = minimal 11X

    local hb = SILE.call("hbox", {}, function ()
      for i = 1, #pattern do
        local sz = tonumber(pattern:sub(i,i)) * X
        if i % 2 == 0 then
          -- space
          SILE.call("kern", { width = sz + offsetcorr })
        else
          -- bar
          local numline = (i+1)/2
          local d = 0
          if numline == 1 or numline == 2 or numline == 15 or numline == 16 or numline == 29 or numline == 30 then
            d = 5 -- longer bars are 5X taller (bottom extending) than shorter bars
          end
          SILE.call("hrule", { height = H * X, depth = d * X, width = sz - offsetcorr })
        end
      end
      SILE.call("kern", { width = offsetcorr }) -- Not really requested by the standard but felt preferable,
                                                -- so that whatever the correction is, the look is globally
                                                -- the same.
      if SU.boolean(options.showdigits, true) then
        -- N.B. Option showdigits undocumented (just used for testing)
        local deltaFontWidth = (7 - SILE.scratch.ean13.font.width) * 3 -- 6 digits measuring at most 7X:
                                                                       -- we'll distribute the extra space evenly.
        SILE.call("font", { family = SILE.scratch.ean13.font.family, size = SILE.scratch.ean13.font.size * X }, function ()
          SILE.call("lower", { height = 8.3333 * X }, function ()
          -- 106X = 11X LQZ + 3X guard + 6*7X digits + 5X guard + 6*7X digits + 3X guard
          -- So we get back to the start of the barcode.
            SILE.call("kern", { width = -106 * X })
            -- First digit, at the start of the Left Quiet Zone
            local h = SILE.call("hbox", {}, { code:sub(1,1) })
            h.width = SILE.length()
            -- First 6-digit sequence is at 11X LQZ + 3X guard = 14X
            -- We add a 0.5X displacement from the normal guard (a bar)
            -- while the central bar starts with a space).
            SILE.call("kern", { width = 14.5 * X })
            SILE.call("kern", { width = deltaFontWidth * X })
            h = SILE.call("hbox", {}, { code:sub(2,7) }) -- first sequence
            h.width = SILE.length()
            -- Second 6-digit sequence is further at 6*7X digits + 5X guard = 47X
            -- to which we remove the previous 0.5X displacement.
            -- Substract an additional 0.5X displacement from the central guard
            -- (a space) so as to end at 0.5X from the ending guard (a bar),
            -- hence 46X...
            SILE.call("kern", { width = 46 * X })
            h = SILE.call("hbox", {}, { code:sub(8,13) }) -- last sequence
            h.width = SILE.length()
            SILE.call("kern", { width = -deltaFontWidth * X })
            -- End marker is at 6*7X + 3X guard + 7X RQZ = 52X
            -- Corrected by the above displacement, hence 52.5X
            local l = SILE.length((52.5 - SILE.scratch.ean13.font.width) * X)
            SILE.call("kern", { width = l })
            if not addon then
              h = SILE.call("hbox", {}, { ">" }) -- closing bracket, aligned to the end of the Right Quiet Zone
              h.width = SILE.length()
            end
            SILE.call("kern", { width = (SILE.scratch.ean13.font.width - 7) * X  })
          end)
        end)
      end
    end)
    -- Barcode height (including the number) = according to the standard, 25.93mm at standard X
    -- It means there's 9.3333X below the bars but we already took 5X for the longer bars.
    hb.depth = hb.depth + 4.3333 * X

    SILE.call("kern", { width = 7 * X }) -- Right Quiet Zone = minimal 7X

    if addon then
      SILE.call("ean13:addon", { code = addon, scale = scale, correction = corr, showdigits = options.showdigits })
    end
  end, "Typesets an EAN-13 barcode.")

  -- We split the Add-on code in a separate command for easier reading,
  -- but of course it's kind of internal (and hence not mentioned in the
  -- package documentation, though used in an example).
  self:registerCommand("ean13:addon", function (options, _)
    local code = SU.required(options, "code", "valid EAN-13 add-on code")
    local scale = options.scale or "SC2"
    local corr = SU.boolean(options.correction, true)

    if code:match("%D") ~= nil then
      SU.error("Invalid EAN-13 supplemental code '"..code.."'")
    end

    local module = SC[scale]
    if not module then SU.error("Invalid EAN scale (SC0 to SC9): "..scale) end

    local X = SILE.length(module.."mm")
    local H = 66.363636364 -- As per the standard, a minimal 21.90mm at standard X
    local offsetcorr = corr and SILE.length("0.020mm") or SILE.length()

    local pattern
    if #code == 5 then
      pattern = ean13addOn5(code)
    elseif #code == 2 then
      pattern = ean13addOn2(code)
    else
      SU.error("Invalid EAN-13 add-on length in '"..code.."' (expecting a 2-digit or 5-digit code)")
    end

    SILE.call("kern", { width = 5 * X }) -- Add-ons Left Quiet Zone = optional 5X
    -- N.B. Optional in the standard, so the spacing between the main part and the
    -- addon is specified as 7-12X (i.e. including the main code 7X Right Quiet Zone).
    -- To be safer, we go for the 12X variant. It also looks better, IMHO.

    local hb = SILE.call("hbox", {}, function ()
      for i = 1, #pattern do
        local sz = tonumber(pattern:sub(i,i)) * X
        if i % 2 == 0 then
          -- space
          SILE.call("kern", { width = sz + offsetcorr })
        else
          -- bar
          SILE.call("hrule", { height = (H - 5) * X, depth = 5 * X, width = sz - offsetcorr })
        end
      end
      SILE.call("kern", { width = offsetcorr }) -- Not really requested by the standard but felt preferable,
                                                -- so that whatever the correction is, the look is globally
                                                -- the same.
      if SU.boolean(options.showdigits, true) then
        -- N.B. Option showdigits undocumented (just used for testing)
        SILE.call("font", { family = SILE.scratch.ean13.font.family, size = SILE.scratch.ean13.font.size * X }, function ()
          SILE.call("raise", { height = (H - 4) * X }, function () -- 0.5X minimum between character and bars,
                                                                   -- but it looks much better with a full 1X.
            SILE.call("kern", { width = -9 * #code * X })
            for i = 1, #code do
              local h = SILE.call("hbox", {}, { code:sub(i,i) }) -- Distribute the digits
              h.width = SILE.length()
              SILE.call("kern", { width = 9 * X })
            end
            local l = SILE.length((5 - SILE.scratch.ean13.font.width) * X)
            SILE.call("kern", { width = l })
            local h = SILE.call("hbox", {}, { ">" }) -- closing bracket, aligned to the end of the Add-ons Right Quiet Zone
            h.width = SILE.length()
            SILE.call("kern", { width = (SILE.scratch.ean13.font.width - 5) * X  })
          end)
        end)
      end
    end)
    -- Barcode height fix (including the number).
    -- We just ensure here the whole box is high enough to take into account the
    -- add-on's human representation, since that one goes on top.
    hb.height = hb.height + 8.3333 * X

    SILE.call("kern", { width = 5 * X }) -- Add-ons Right Quiet Zone = minimal 5X
  end, "Typesets an EAN-13 5-digit add-on barcode.")

  self:registerCommand("ean13:font", function (options, _)
    local family = SU.required(options, "family", "Monospace font for EAN barcodes")

    setupHumanReadableFont(family)
  end, "Sets the font for the human readable interpretation in EAN-13 barcode")
end

package.documentation = [[
\begin{document}
\use[module=packages.barcodes.ean13]
\ean13:font[family=Hack]% Not the best effect, but avoids hasardous substitutions when OCR B is not installed
The \autodoc:package{barcodes.ean13} package allows to print out an EAN-13 barcode, suitable
for an ISBN (or ISSN, etc.)

The \autodoc:command{\ean13} command takes a mandatory \autodoc:parameter{code} parameter,
the human representation of the EAN-13 code (including its final control digit).
It checks its consistency and displays the corresponding barcode. By default, it uses the
recommended scale for a “consumer item” (SC2, with a “module” of 0.33mm). The size
can be changed by setting the \autodoc:parameter{scale} option to any of the standard
scales from SC0 to SC9. For the record, SC6 is the minimum recommended scale for an
“outer packaging” (SC9 being the default recommended scale for it).

By default, the bar width is reduced by 0.020mm and the white spaces are enlarged by the
same amount (so as to preserve the global distance between bars.)
The standard indeed recommends making each rule thinner than what is exactly implied
by the multiple of the module, due the ink behavior during the actual printing. The
bar correction value used here is suitable for offset process technology. You can
disable that offset correction by specifying the \autodoc:parameter{correction=false}
option.

The human readable interpretation below the barcode expects the font to be OCR-B. A free
implementation of this font is Matthew Skala’s July 2021 version,
at \url{https://tsukurimashou.osdn.jp/ocr.php.en}, recommended for use with this package.
The \autodoc:command{\ean13:font[family=<family>]} command allows setting the font
family used for the human readable interpretation, would the above be unavalaible to you
or another choice be preferred. Obviously, a monospace font is strongly advised.
The package does its best for decently sizing and positioning the text, but your mileage
may vary depending on the chosen font.

Here is this package in action \ean13[code=9782953989663, scale=SC0] at scale SC0…

…so you can see how it shows up with respect to the current baseline.

Additionally, EAN-13 barcodes may have a 2-digit or 5-digit supplemental “add-on” part,
which can be specified with the \autodoc:parameter{addon} option. The supplemental part
is sometimes used to provide price information or other publisher-specific details,
depending on the type of EAN-13 number and the country where it is registered.

For instance \ean13[code=9782953989663, scale=SC0, addon=12345]
or a 2-digit add-on \ean13:addon[code=24, scale=SC0]
\end{document}]]

return package
