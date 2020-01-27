local vstruct = require "vstruct"
local hb = require "justenoughharfbuzz"
local zlib = require "zlib"

vstruct.compile("SinglePosFormatOne", "> posFormat:u2 coverageOffset:u2 valueFormat:u2")
vstruct.compile("RangeRecord", "> startGlyphID:u2 endGlyphID:u2 startCoverageIndex:u2")

local function parseValueRecord(fd, valFormat)
  valueRecord = {}
  if (valFormat & 0x001) > 0 then valueRecord.xPlacement  = (vstruct.read("> i2", fd))[1] end
  if (valFormat & 0x002) > 0 then valueRecord.yPlacement  = (vstruct.read("> i2", fd))[1] end
  if (valFormat & 0x004) > 0 then valueRecord.xAdvance    = (vstruct.read("> i2", fd))[1] end
  if (valFormat & 0x008) > 0 then valueRecord.yAdvance    = (vstruct.read("> i2", fd))[1] end
  if (valFormat & 0x010) > 0 then valueRecord.xPlaDevice  = (vstruct.read("> u2", fd))[1] end
  if (valFormat & 0x020) > 0 then valueRecord.yPlaDevice  = (vstruct.read("> u2", fd))[1] end
  if (valFormat & 0x040) > 0 then valueRecord.xAdvDevice  = (vstruct.read("> u2", fd))[1] end
  if (valFormat & 0x080) > 0 then valueRecord.yAdvDevice  = (vstruct.read("> u2", fd))[1] end
  return valueRecord
end

local parseName = function(str)
  if str:len() <= 0 then return end
  local fd = vstruct.cursor(str)

  local names = {}
  local MacintoshLanguages = {
    [0] = 'en', [1] = 'fr', [2] = 'de', [3] = 'it', [4] = 'nl',
    [5] = 'sv', [6] = 'es', [7] = 'da', [8] = 'pt', [9] = 'no',
    [10] = 'he', [11] = 'ja', [12] = 'arb', [13] = 'fi', [14] = 'el',
    [15] = 'is', [16] = 'mt', [17] = 'tr', [18] = 'hr', [19] = 'zh-Hant',
    [20] = 'ur', [21] = 'hi', [22] = 'th', [23] = 'ko', [24] = 'lt',
    [25] = 'pl', [26] = 'hu', [27] = 'et', [28] = 'lv', [29] = 'smi',
    [30] = 'fo', [31] = 'fa', [32] = 'ru', [33] = 'zh-Hans', [34] = 'nl-BE',
    [35] = 'gle', [36] = 'sq', [37] = 'ro', [38] = 'cs', [39] = 'sk',
    [40] = 'sl', [41] = 'yi', [42] = 'sr', [43] = 'mk', [44] = 'bg',
    [45] = 'uk', [46] = 'be', [47] = 'uz', [48] = 'kk', [49] = 'az-Cyrl',
    [50] = 'az-Arab', [51] = 'hy', [52] = 'ka', [53] = 'mo', [54] = 'ky',
    [55] = 'tg', [56] = 'tk', [57] = 'mn-Mong', [58] = 'mn-Cyrl', [59] = 'ps',
    [60] = 'ku', [61] = 'ks', [62] = 'sd', [63] = 'bo', [64] = 'ne',
    [65] = 'sa', [66] = 'mr', [67] = 'bn', [68] = 'as', [69] = 'gu',
    [70] = 'pa', [71] = 'or', [72] = 'ml', [73] = 'kn', [74] = 'ta',
    [75] = 'te', [76] = 'se', [77] = 'my', [78] = 'km', [79] = 'lo',
    [80] = 'vi', [81] = 'id', [82] = 'tl', [83] = 'ms', [84] = 'ms',
    [85] = 'am', [86] = 'ti', [87] = 'gax', [88] = 'so', [89] = 'sw',
    [90] = 'rw', [91] = 'rn', [92] = 'ny', [93] = 'mg', [94] = 'eo',
    [128] = 'cy', [129] = 'eu', [130] = 'ca', [131] = 'la', [132] = 'qu',
    [133] = 'gn', [134] = 'ay', [135] = 'tt', [136] = 'ug', [137] = 'dz',
    [138] = 'jv', [139] = 'su', [140] = 'gl', [141] = 'af', [142] = 'br',
    [143] = 'iu', [144] = 'gd', [145] = 'gv', [146] = 'gle', [147] = 'to',
    [148] = 'el-polyton', [149] = 'kl', [150] = 'az'
  }

  local WindowsLanguages = {
    [4] = "zh-CHS", [1025] = "ar-SA", [1026] = "bg-BG", [1027] = "ca-ES",
    [1028] = "zh-TW", [1029] = "cs-CZ", [1030] = "da-DK", [1031] = "de-DE",
    [1032] = "el-GR", [1033] = "en-US", [1035] = "fi-FI", [1036] = "fr-FR",
    [1037] = "he-IL", [1038] = "hu-HU", [1039] = "is-IS", [1040] = "it-IT",
    [1041] = "ja-JP", [1042] = "ko-KR", [1043] = "nl-NL", [1044] = "nb-NO",
    [1045] = "pl-PL", [1046] = "pt-BR", [1048] = "ro-RO", [1049] = "ru-RU",
    [1050] = "hr-HR", [1051] = "sk-SK", [1052] = "sq-AL", [1053] = "sv-SE",
    [1054] = "th-TH", [1055] = "tr-TR", [1056] = "ur-PK", [1057] = "id-ID",
    [1058] = "uk-UA", [1059] = "be-BY", [1060] = "sl-SI", [1061] = "et-EE",
    [1062] = "lv-LV", [1063] = "lt-LT", [1065] = "fa-IR", [1066] = "vi-VN",
    [1067] = "hy-AM", [1068] = "Lt-az-AZ", [1069] = "eu-ES", [1071] = "mk-MK",
    [1078] = "af-ZA", [1079] = "ka-GE", [1080] = "fo-FO", [1081] = "hi-IN",
    [1086] = "ms-MY", [1087] = "kk-KZ", [1088] = "ky-KZ", [1089] = "sw-KE",
    [1091] = "Lt-uz-UZ", [1092] = "tt-RU", [1094] = "pa-IN", [1095] = "gu-IN",
    [1097] = "ta-IN", [1098] = "te-IN", [1099] = "kn-IN", [1102] = "mr-IN",
    [1103] = "sa-IN", [1104] = "mn-MN", [1110] = "gl-ES", [1111] = "kok-IN",
    [1114] = "syr-SY", [1125] = "div-MV", [2049] = "ar-IQ", [2052] = "zh-CN",
    [2055] = "de-CH", [2057] = "en-GB", [2058] = "es-MX", [2060] = "fr-BE",
    [2064] = "it-CH", [2067] = "nl-BE", [2068] = "nn-NO", [2070] = "pt-PT",
    [2074] = "Lt-sr-SP", [2077] = "sv-FI", [2092] = "Cy-az-AZ", [2110] = "ms-BN",
    [2115] = "Cy-uz-UZ", [3073] = "ar-EG", [3076] = "zh-HK", [3079] = "de-AT",
    [3081] = "en-AU", [3082] = "es-ES", [3084] = "fr-CA", [3098] = "Cy-sr-SP",
    [4097] = "ar-LY", [4100] = "zh-SG", [4103] = "de-LU", [4105] = "en-CA",
    [4106] = "es-GT", [4108] = "fr-CH", [5121] = "ar-DZ", [5124] = "zh-MO",
    [5127] = "de-LI", [5129] = "en-NZ", [5130] = "es-CR", [5132] = "fr-LU",
    [6145] = "ar-MA", [6153] = "en-IE", [6154] = "es-PA", [6156] = "fr-MC",
    [7169] = "ar-TN", [7177] = "en-ZA", [7178] = "es-DO", [8193] = "ar-OM",
    [8201] = "en-JM", [8202] = "es-VE", [9217] = "ar-YE", [9225] = "en-CB",
    [9226] = "es-CO", [10241] = "ar-SY", [10249] = "en-BZ", [10250] = "es-PE",
    [11265] = "ar-JO", [11273] = "en-TT", [11274] = "es-AR", [12289] = "ar-LB",
    [12297] = "en-ZW", [12298] = "es-EC", [13313] = "ar-KW", [13321] = "en-PH",
    [13322] = "es-CL", [14337] = "ar-AE", [14346] = "es-UY", [15361] = "ar-BH",
    [15370] = "es-PY", [16385] = "ar-QA", [16394] = "es-BO", [17418] = "es-SV",
    [18442] = "es-HN", [19466] = "es-NI", [20490] = "es-PR", [31748] = "zh-CHT"
  }
  local name = vstruct.read(">format:u2 count:u2 sOffset:u2", fd)
  name.records = {}
  if name.format == 1 then return end
  for i=1,name.count do
    local record = vstruct.read(">platform:u2 encoding:u2 language:u2 name:u2 length:u2 offset:u2", fd)
    name.records[i] = record
    local language
    if (record.platform == 1 and record.encoding == 0) or
       (record.platform == 3 and record.encoding == 1) then
      if record.language < 0x8000 and record.platform == 1 then
        language = MacintoshLanguages[record.language]
      elseif record.language < 0x8000 and record.platform == 3 then
        language = WindowsLanguages[record.language]
      end
    end
    name.records[i].language = language
  end
  for i=1,name.count do
    local record = name.records[i]
    local language = record.language
    if language then
      if not names[record.name] then names[record.name] = {} end
      names[record.name][language] = vstruct.read(">@"..name.sOffset+record.offset.."s"..record.length, fd)
    end
  end

  return names
end

local parseMaxp = function(str)
  if str:len() <= 0 then return end
  local fd = vstruct.cursor(str)

  return vstruct.read(">version:u4 numGlyphs:u2", fd)
end

local parseHead = function(str)
  if str:len() <= 0 then return end
  local fd = vstruct.cursor(str)

  return vstruct.read(">majorVersion:u2 minorVersion:u2 fontRevisionMajor:u2 fontRevisionMinor:u2 checkSumAdjustment:u4 magicNumber:u4 flags:u2 unitsPerEm:u2 ", fd)
end


local function parseColr(str)
  if str:len() <= 0 then return end
  local fd = vstruct.cursor(str)

  local version = vstruct.readvals(">u2", fd)
  if version ~= 0 then return end

  local colr = {}

  local header = vstruct.read(">nBases:u2 oBases:u4 oLayers:u4 nLayers:u2", fd)
  local bases = vstruct.read(">@" .. header.oBases .. " " .. header.nBases .. "*{gid:u2 firstLayer:u2 nLayers:u2}", fd)
  local layers = vstruct.read(">@" .. header.oLayers .. " " .. header.nLayers .. "*{gid:u2 paletteIndex:u2}", fd)

  for i = 1, #bases do
    local base = bases[i]
    local glyphLayers = {}
    for j = base.firstLayer + 1, base.firstLayer + base.nLayers do
      local layer = layers[j]
      layer.paletteIndex = layer.paletteIndex + 1
      glyphLayers[#glyphLayers+1] = layer
    end
    colr[base.gid] = glyphLayers
  end

  return colr
end

local function parseCpal(str)
  if str:len() <= 0 then return end
  local fd = vstruct.cursor(str)

  local version = vstruct.readvals(">u2", fd)
  if version > 1 then return end

  local cpal = {}

  local header = vstruct.read(">nPalettesEntries:u2 nPalettes:u2 nColors:u2 oFirstColor:u4", fd)
  -- local colorIndices = vstruct.read("> " .. header.nPalettes .. "*u2", fd)
  local colors = vstruct.read(">@" .. header.oFirstColor .. " " .. header.nColors .. "*{b:u1 g:u1 r:u1 a:u1}", fd)

  for _ = 1, header.nPalettes do
    local palette = {}
    for j = 1, header.nPalettesEntries do
      local color = colors[j]
      for k, v in pairs(color) do
        color[k] = v / 255
      end
      palette[#palette+1] = color
    end
    cpal[#cpal+1] = palette
  end

  return cpal
end

local function parseSvg(str)
  if str:len() <= 0 then return end
  local fd = vstruct.cursor(str)

  local offsets = {}
  local header = vstruct.read(">version:u2 oDocIndex:u4", fd)
  if header.version > 0 then return end
  local numEntries = vstruct.read(">@"..header.oDocIndex.." u2", fd)
  local outlines = vstruct.read("> " .. numEntries[1] .. "*{startGlyphID:u2 endGlyphID:u2 svgDocOffset:u4 svgDocLength:u4}", fd)
  for i = 1, numEntries[1] do
    local outline = outlines[i]
    for j = outline.startGlyphID,outline.endGlyphID do
      offsets[j] = {
        svgDocLength = outline.svgDocLength,
        svgDocOffset = outline.svgDocOffset + header.oDocIndex
        -- Note that now we are an offset from the beginning of the table
      }
    end
  end
  return offsets
end

local function parseCoverage(fd, off)
  local header = vstruct.read("> @"..off.." coverageFormat:u2", fd)
  local covered = {}
  if header.coverageFormat == 1 then
    local gcount = vstruct.read("> u2", fd)
    local glyphs = vstruct.read("> "..gcount[1].."*u2", fd)
    for i = 1,#glyphs do covered[glyphs[i]] = true end
    return covered
  end
  if header.coverageFormat == 2 then
    covered = {}
    local rangecount = vstruct.read("> u2", fd)
    for i = 1,rangecount[1] do
      local range = vstruct.read("> { &RangeRecord }",fd)
      range = range[1]
      for j = range.startGlyphID,range.endGlyphID do
        covered[j] = true
      end
    end
    return covered
  end
  SU.error("Coverage table error: type=="..header.coverageFormat)
end

local function parseLookup(fd, off)
  local header = vstruct.read("> @"..off.." lookupType:u2 lookupFlag:u2 subTableCount:u2", fd)
  local subtableOffsets = vstruct.read("> "..header.subTableCount.."*u2",fd)
  for i=1, header.subTableCount do
    local subtableOff = off + subtableOffsets[i]
    if header.lookupType == 1 then
      local posFormat = vstruct.read("> @"..subtableOff.." u2 -2",fd)
      header.subtables = {}
      if posFormat[1] == 1 then
        header.subtables[i] = vstruct.read("> &SinglePosFormatOne", fd)
        header.subtables[i].valueRecord = parseValueRecord(fd, header.subtables[i].valueFormat)
        header.subtables[i].coverage = parseCoverage(fd, subtableOff + header.subtables[i].coverageOffset)
        -- be tidy
        header.subtables[i].valueFormat = nil
        header.subtables[i].coverageOffset = nil
      end
    end
  end
  return header
end

local function parseJstfLangSysTable(fd, off)
  local header = vstruct.read("> @"..off.." jstfPriorityCount:u2", fd)
  local suggestionOffsets = vstruct.read("> "..header.jstfPriorityCount .. "*u2", fd)
  local suggestions = {}
  for i = 1, header.jstfPriorityCount do
      local suggestionOffset = suggestionOffsets[i] + off
      local suggestion = vstruct.read("> @"..suggestionOffset.." shrinkageEnableGSUB:u2 shrinkageDisableGSUB:u2 shrinkageEnableGPOS:u2 shrinkageDisableGPOS:u2 shrinkageJstfMax:u2 extensionEnableGSUB:u2 extensionDisableGSUB:u2 extensionEnableGPOS:u2 extensionDisableGPOS:u2 extensionJstfMax:u2",fd)
      if suggestion.extensionEnableGSUB then
        local tableOffset = suggestionOffset + suggestion.extensionEnableGSUB
        local lookupCount = vstruct.read("> @"..tableOffset.." u2",fd)
        local lookupIndices = vstruct.read("> "..lookupCount[1].."*u2",fd)
        suggestion.extensionEnableGSUB = lookupIndices
      end
      if suggestion.shrinkageEnableGSUB then
        local tableOffset = suggestionOffset + suggestion.shrinkageEnableGSUB
        local lookupCount = vstruct.read("> @"..tableOffset.." u2",fd)
        local lookupIndices = vstruct.read("> "..lookupCount[1].."*u2",fd)
        suggestion.shrinkageEnableGSUB = lookupIndices
      end
      if suggestion.extensionEnableGPOS then
        local tableOffset = suggestionOffset + suggestion.extensionEnableGPOS
        local lookupCount = vstruct.read("> @"..tableOffset.." u2",fd)
        local lookupIndices = vstruct.read("> "..lookupCount[1].."*u2",fd)
        suggestion.extensionEnableGPOS = lookupIndices
      end
      if suggestion.shrinkageEnableGPOS then
        local tableOffset = suggestionOffset + suggestion.shrinkageEnableGPOS
        local lookupCount = vstruct.read("> @"..tableOffset.." u2",fd)
        local lookupIndices = vstruct.read("> "..lookupCount[1].."*u2",fd)
        suggestion.shrinkageEnableGPOS = lookupIndices
      end

      if suggestion.extensionJstfMax then
        local jsftMaxOffset = (suggestionOffset + suggestion.extensionJstfMax)
        local lookupCount = vstruct.read(">@"..jsftMaxOffset.." u2",fd)
        local lookupOffsets = vstruct.read("> "..lookupCount[1].."*u2",fd)
        suggestion.lookupOffsets = lookupOffsets
        suggestion.jsftMaxOffset = suggestion.extensionJstfMax
        suggestion.extensionJstfMax = {}
        for j = 1,lookupCount[1] do
          suggestion.extensionJstfMax[j] = parseLookup(fd,jsftMaxOffset+lookupOffsets[j])
        end
      end
      if suggestion.shrinkageJstfMax then
        local jsftMinOffset = (suggestionOffset + suggestion.shrinkageJstfMax)
        local lookupCount = vstruct.read(">@"..jsftMinOffset.." u2",fd)
        local lookupOffsets = vstruct.read("> "..lookupCount[1].."*u2",fd)
        suggestion.lookupOffsets = lookupOffsets
        suggestion.jsftMinOffset = suggestion.shrinkageJstfMax
        suggestion.shrinkageJstfMax = {}
        for j = 1,lookupCount[1] do
          suggestion.shrinkageJstfMax[j] = parseLookup(fd,jsftMinOffset+lookupOffsets[j])
        end
      end
      suggestions[i] = suggestion
  end
  return suggestions
end

local function parseJstf(str)
  if str:len() <= 0 then return end
  local fd = vstruct.cursor(str)

  local offsets = {}
  local header = vstruct.read(">version:u4 JstfScriptCount:u2", fd)
  if header.JstfScriptCount == 0 then return end

  local su
  local scriptdata = vstruct.read("> " .. header.JstfScriptCount .. "*{tag:s4 scriptOffset:u2}", fd)
  scripts = {}
  for i = 1, header.JstfScriptCount do
    local scriptHead = scriptdata[i].scriptOffset
    local record = vstruct.read("> @"..scriptHead.." extenderGlyphOffset:u2 defJstfLangSysOffset:u2 jstfLangSysCount:u2", fd)

    record.languages = {}
    if record.jstfLangSysCount > 0 then
      local langSysData = vstruct.read("> " .. record.jstfLangSysCount .. "*{tag:s4 langSysOffset:u2}", fd)
      for j = 1, record.jstfLangSysCount do
        record.languages[langSysData[j].tag] = parseJstfLangSysTable(fd, scriptHead + langSysData[j].langSysOffset)
      end
    end

    if record.extenderGlyphOffset then
      local extenderPos = scriptHead + record.extenderGlyphOffset
      local extenderRecord = vstruct.read("> @"..extenderPos.." glyphCount:u2",fd)
      local glyphids = vstruct.read("> "..extenderRecord.glyphCount.."*u2",fd)
      record.extenderGlyphs = glyphids
    end

    if record.defJstfLangSysOffset then
      local defaultLangSysPos = scriptHead + record.defJstfLangSysOffset
      record.defaultJstfLangSysTable = parseJstfLangSysTable(fd, defaultLangSysPos)
    end

    scripts[scriptdata[i].tag] = record
  end
  return scripts
end

local function parseGsub(str)
  if str:len() <= 0 then return end
  local fd = vstruct.cursor(str)

  local offsets = {}
  local header = vstruct.read(">version:u4 ScriptListOffset:u2 FeatureListOffset:u2 LookupListOffset:u2", fd)
  -- for our purposes we just need the lookups (for now)
  local lookupListTable = vstruct.read("> @"..header.LookupListOffset.." lookupCount:u2",fd)
  local lookupOffsets = vstruct.read("> "..lookupListTable.lookupCount.."*u2",fd)
  local lookups = {}
  for i = 1, lookupListTable.lookupCount do
    local lookupTableOffset = header.LookupListOffset+lookupOffsets[i]
    local lookupTable = vstruct.read("> @"..lookupTableOffset.." lookupType:u2 lookupFlag:u2 subTableCount:u2",fd)
    local subTableOffsets = vstruct.read("> "..lookupTable.subTableCount.."*u2", fd)
    lookups[i-1] = {} -- OpenType lookups are zero indexed
    for j = 1, lookupTable.subTableCount do
      local subTableOffset = lookupTableOffset + subTableOffsets[j]
      if lookupTable.lookupType == 1 then
        local subTable = vstruct.read("> @"..subTableOffset.." substFormat:u2 coverageOffset:u2",fd)
        if subTable.substFormat == 1 then
          local deltaGlyphId =  vstruct.read("> u2",fd)[1]
          local inputGlyphs = parseCoverage(fd, subTableOffset+subTable.coverageOffset)
          inputGlyphs = SU.keylist(inputGlyphs)
          for k = 1,#inputGlyphs do
            local inputGlyphID = inputGlyphs[k]
            lookups[i-1][inputGlyphID] = inputGlyphID + deltaGlyphId
          end
        else
          local glyphCount =  vstruct.read("> u2",fd)
          local replacementGlyphs =  vstruct.read("> "..glyphCount[1].."*u2",fd)
          local inputGlyphs = parseCoverage(fd, subTableOffset+subTable.coverageOffset)
          inputGlyphs = SU.keylist(inputGlyphs)
          for k = 1,#inputGlyphs do
            local inputGlyphID = inputGlyphs[k]
            lookups[i-1][inputGlyphID] = replacementGlyphs[k]
          end
        end
      end
    end
  end
  return lookups
end
local parseFont = function(face)
  if not face.font then
    local font = {}

    font.names = parseName(hb.get_table(face.data, face.index, "name"))
    font.head = parseHead(hb.get_table(face.data, face.index, "head"))
    font.maxp = parseMaxp(hb.get_table(face.data, face.index, "maxp"))
    font.colr = parseColr(hb.get_table(face.data, face.index, "COLR"))
    font.cpal = parseCpal(hb.get_table(face.data, face.index, "CPAL"))
    font.svg  = parseSvg(hb.get_table(face.data, face.index, "SVG"))
    font.jstf  = parseJstf(hb.get_table(face.data, face.index, "JSTF"))
    font.gsub  = parseGsub(hb.get_table(face.data, face.index, "GSUB"))
    face.font = font
  end

  return face.font
end

local decompress = function (str)
  local decompressed = {}
  while true do
    local chunk, eof = zlib.inflate(str)
    decompressed[#decompressed+1] = chunk
    if eof then break end
  end
  return table.concat(decompressed, "")
end

local getSVG = function(face, gid)
  if not face.font then parseFont(face) end
  if not face.font.svg then return end
  local item = face.font.svg[gid]
  if not item then return end
  local str = hb.get_table(face.data, face.index, "SVG")
  local start = item.svgDocOffset+1
  local svg = str:sub(start, start + item.svgDocLength-1)
  if svg[1] == "\x1f" and svg[2] == "\x8b" then
    svg = decompress(svg)
  end
  return svg
end

return { parseFont = parseFont, getSVG = getSVG }
