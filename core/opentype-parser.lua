local vstruct = require "vstruct"
local hb = require "justenoughharfbuzz"
local zlib = require "zlib"

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
      if record.length > 0 then
        names[record.name][language] = vstruct.read(">@"..name.sOffset+record.offset.."s"..record.length, fd)
        if record.platform == 3 then
          names[record.name][language] = { SU.utf16be_to_utf8(names[record.name][language][1]) }
        end
      end
    end
  end

  return names
end

local parseMaxp = function(str)
  if str:len() <= 0 then return end
  local fd = vstruct.cursor(str)

  return vstruct.read(">version:u4 numGlyphs:u2", fd)
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

local function parseHead(s)
  if s:len() <= 0 then return end
  local fd = vstruct.cursor(s)
  return vstruct.read(">majorVersion:u2 minorVersion:u2 fontRevision:u4 checkSumAdjustment:u4 magicNumber:u4 flags:u2 unitsPerEm:u2 created:u8 modified:u8 xMin:i2 yMin:i2 xMax:i2 yMax:i2 macStyle:u2 lowestRecPPEM:u2 fontDirectionHint:i2 indexToLocFormat:i2 glyphDataFormat:i2", fd)
end

local parseDeviceTable = function(offset, fd)
  local header = vstruct.read(">@"..offset.." startSize:u2 endSize:u2 deltaFormat:u2", fd)
  local size = header.endSize - header.startSize + 1
  local buf
  if header.deltaFormat == 0x0001 then
    buf = vstruct.read("> "..math.ceil(size+7/8).."*[2| i2 i2 i2 i2 i2 i2 i2 i2 ]", fd)
  elseif header.deltaFormat == 0x0002 then
    buf = vstruct.read("> "..math.ceil(size/4).."*[2| i4 i4 i4 i4 ]", fd)
  elseif header.deltaFormat == 0x0003 then
    buf = vstruct.read("> "..math.ceil(size/2).."*[2| i8 i8 ]", fd)
  else
    SU.warn('DeltaFormat '..header.deltaFormat.." in Device Table is not supported. Ignore the table.")
    return nil
  end
  local deviceTable = {}
  for i = 1, size do
    deviceTable[header.startSize + i - 1] = buf[i]
  end
  return deviceTable
end

local parseCoverage = function (offset, fd)
  local coverageFormat = vstruct.readvals(">@"..offset.." u2", fd)
  if coverageFormat == 1 then
    local glyphCount = vstruct.readvals("> u2", fd)
    return vstruct.read("> "..glyphCount.."*u2", fd)
  elseif coverageFormat == 2 then
    local rangeCount = vstruct.readvals("> u2", fd)
    local ranges = vstruct.read("> "..rangeCount.."*{ &RangeRecord }", fd)
    local coverage = {}
    for i = 1, #(ranges) do
      for glyphID = ranges[i].startGlyphID, ranges[i].endGlyphID do
        local index = ranges[i].startCoverageIndex + glyphID - ranges[i].startGlyphID + 1 -- array in lua is one-based
        if coverage[index] then
          SU.error(glyphID .. " already exist in converage when processing " .. ranges[i])
        end
        coverage[index] = glyphID
      end
    end
    return coverage
  else
    SU.error('Unsupported coverage table format '..coverageFormat)
  end
end

-- Removes the indirection in a MathValueRecord by replacing the
-- deviceTableOffset field by an actual device table in the deviceTable field.
local fetchMathValueRecord = function(record, parent_offset, fd)
  local newRecord = { value = record.value }
  if record.deviceTableOffset ~= 0 then
    newRecord.deviceTable = parseDeviceTable(parent_offset + record.deviceTableOffset, fd)
  end
  return newRecord
end

local parseConstants = function(offset, fd)
  local mathConstantNames = {
    "scriptPercentScaleDown", "scriptScriptPercentScaleDown", "delimitedSubFormulaMinHeight",
    "displayOperatorMinHeight", "mathLeading", "axisHeight",
    "accentBaseHeight", "flattenedAccentBaseHeight", "subscriptShiftDown",
    "subscriptTopMax", "subscriptBaselineDropMin", "superscriptShiftUp",
    "superscriptShiftUpCramped", "superscriptBottomMin", "superscriptBaselineDropMax",
    "subSuperscriptGapMin", "superscriptBottomMaxWithSubscript", "spaceAfterScript",
    "upperLimitGapMin", "upperLimitBaselineRiseMin", "lowerLimitGapMin",
    "lowerLimitBaselineDropMin", "stackTopShiftUp", "stackTopDisplayStyleShiftUp",
    "stackBottomShiftDown", "stackBottomDisplayStyleShiftDown", "stackGapMin",
    "stackDisplayStyleGapMin", "stretchStackTopShiftUp", "stretchStackBottomShiftDown",
    "stretchStackGapAboveMin", "stretchStackGapBelowMin", "fractionNumeratorShiftUp",
    "fractionNumeratorDisplayStyleShiftUp", "fractionDenominatorShiftDown", "fractionDenominatorDisplayStyleShiftDown",
    "fractionNumeratorGapMin", "fractionNumDisplayStyleGapMin", "fractionRuleThickness",
    "fractionDenominatorGapMin", "fractionDenomDisplayStyleGapMin", "skewedFractionHorizontalGap",
    "skewedFractionVerticalGap", "overbarVerticalGap", "overbarRuleThickness",
    "overbarExtraAscender", "underbarVerticalGap", "underbarRuleThickness",
    "underbarExtraDescender", "radicalVerticalGap", "radicalDisplayStyleVerticalGap",
    "radicalRuleThickness", "radicalExtraAscender", "radicalKernBeforeDegree",
    "radicalKernAfterDegree", "radicalDegreeBottomRaisePercent" }
  local mathConstantTypes = { "i2", "i2", "u2",
    "u2", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "{ &MathValueRecord }", "{ &MathValueRecord }",
    "{ &MathValueRecord }", "i2" }
  local mathConstantFormat = ">@"..offset
  for i = 1, #(mathConstantNames) do
    mathConstantFormat = mathConstantFormat.." "..mathConstantNames[i]..":"..mathConstantTypes[i]
  end
  local mathConstants = vstruct.read(mathConstantFormat, fd)
  for k,v in pairs(mathConstants) do
    if v and type(v) == "table" then
      mathConstants[k] = fetchMathValueRecord(v, offset, fd)
    end
  end
  return mathConstants
end

local parseMathKern = function(offset, fd)
  local heightCount	= vstruct.readvals(">@"..offset.." u2", fd)
  local mathKern = vstruct.read("> correctionHeight:{ "..heightCount.."*{ &MathValueRecord } } kernValues:{ "..(heightCount+1).."*{ &MathValueRecord } }", fd)
  for i = 1, #(mathKern.correctionHeight) do
    mathKern.correctionHeight[i] = fetchMathValueRecord(mathKern.correctionHeight[i], offset, fd)
  end
  for i = 1, #(mathKern.kernValues) do
    mathKern.kernValues[i] = fetchMathValueRecord(mathKern.kernValues[i], offset, fd)
  end
  return mathKern
end

local parsePerGlyphTable = function(offset, type, fd)
  local coverageOffset = vstruct.readvals(">@"..offset.." u2", fd)
  local coverageTable = parseCoverage(offset + coverageOffset, fd)
  local count = vstruct.readvals(">@"..(offset+2).." u2", fd)
  if count ~= #(coverageTable) then
    SU.error("Coverage table corrupted")
  end
  local table = vstruct.read("> "..count.."*{ "..type.." }", fd)
  local result = {}
  for i = 1, count do
    if type == "&MathValueRecord" then
      result[coverageTable[i]] = fetchMathValueRecord(table[i], offset, fd)
    elseif type == "&MathKernInfoRecord" then
      result[coverageTable[i]] = {
        topRightMathKern = table[i].topRightMathKernOffset ~= 0 and parseMathKern(offset + table[i].topRightMathKernOffset, fd) or nil,
        topLeftMathKern = table[i].topLeftMathKernOffset ~= 0 and parseMathKern(offset + table[i].topLeftMathKernOffset, fd) or nil,
        bottomRightMathKern =  table[i].bottomRightMathKernOffset ~= 0 and parseMathKern(offset + table[i].bottomRightMathKernOffset, fd) or nil,
        bottomLeftMathKern = table[i].bottomLeftMathKernOffset ~= 0 and parseMathKern(offset + table[i].bottomLeftMathKernOffset, fd) or nil
      }
    else
      result[coverageTable[i]] = table[i]
    end
  end
  return result
end

local parseMathVariants = function(offset, fd)
  local parseGlyphAssembly = function(inner_offset, inner_fd)
    local assembly = vstruct.read(">@"..inner_offset.." italicsCorrection:{ &MathValueRecord } partCount:u2", inner_fd)
    assembly.italicsCorrection = fetchMathValueRecord(assembly.italicsCorrection, inner_offset, inner_fd)
    assembly.partRecords = vstruct.read("> "..assembly.partCount.."*{ &GlyphPartRecord }", inner_fd)
    assembly.partCount = nil
    return assembly
  end
  local parseMathGlyphConstruction = function(inner_offset, inner_fd)
    local construction = vstruct.read(">@"..inner_offset.." glyphAssemblyOffset:u2 variantCount:u2", inner_fd)
    local mathGlyphVariantRecord = vstruct.read("> "..construction.variantCount.."*{ &MathGlyphVariantRecord }", inner_fd)
    return {
      glyphAssembly = construction.glyphAssemblyOffset ~= 0 and parseGlyphAssembly(inner_offset + construction.glyphAssemblyOffset, inner_fd) or nil,
      mathGlyphVariantRecord = mathGlyphVariantRecord
    }
  end
  local variants = vstruct.read(">@"..offset.." minConnectorOverlap:u2 vertGlyphCoverageOffset:u2 horizGlyphCoverageOffset:u2 vertGlyphCount:u2 horizGlyphCount:u2", fd)
  local vertGlyphConstructionOffsets = vstruct.read("> "..variants.vertGlyphCount.."*u2", fd)
  local horizGlyphConstructionOffsets = vstruct.read("> "..variants.horizGlyphCount.."*u2", fd)
  local vertGlyphCoverage = {}
  if variants.vertGlyphCoverageOffset > 0 then
    vertGlyphCoverage = parseCoverage(offset + variants.vertGlyphCoverageOffset, fd)
  end
  local horizGlyphCoverage = {}
  if variants.horizGlyphCoverageOffset > 0 then
    horizGlyphCoverage = parseCoverage(offset + variants.horizGlyphCoverageOffset, fd)
  end
  if variants.vertGlyphCount ~= #(vertGlyphCoverage) or variants.horizGlyphCount ~= #(horizGlyphCoverage) then
    SU.error('MathVariants Table corrupted')
  end
  local vertGlyphConstructions = {}
  local horizGlyphConstructions = {}
  for i = 1, variants.vertGlyphCount do
    vertGlyphConstructions[vertGlyphCoverage[i]] = parseMathGlyphConstruction(offset + vertGlyphConstructionOffsets[i], fd)
  end
  for i = 1, variants.horizGlyphCount do
    horizGlyphConstructions[horizGlyphCoverage[i]] = parseMathGlyphConstruction(offset + horizGlyphConstructionOffsets[i], fd)
  end
  return {
    minConnectorOverlap = variants.minConnectorOverlap,
    vertGlyphConstructions = vertGlyphConstructions,
    horizGlyphConstructions = horizGlyphConstructions
  }
end

local parseIfPresent = function(baseOffset, subtableOffset, f)
  if subtableOffset == 0 then return nil
  else return f(baseOffset + subtableOffset)
  end
end

local function parseMath(s)
  if s:len() <= 0 then return end
  local fd = vstruct.cursor(s)
  local header = vstruct.read(">majorVersion:u2 minorVersion:u2 mathConstantsOffset:u2 mathGlyphInfoOffset:u2 mathVariantsOffset:u2", fd)
  SU.debug("opentype-parser", "header =", header)
  if header.majorVersion > 1 then return end
  vstruct.compile("MathValueRecord", "value:i2 deviceTableOffset:u2")
  vstruct.compile("RangeRecord", "startGlyphID:u2 endGlyphID:u2 startCoverageIndex:u2")
  vstruct.compile("MathKernInfoRecord", "topRightMathKernOffset:u2 topLeftMathKernOffset:u2 bottomRightMathKernOffset:u2 bottomLeftMathKernOffset:u2")
  vstruct.compile("MathGlyphVariantRecord", "variantGlyph:u2 advanceMeasurement:u2")
  vstruct.compile("GlyphPartRecord", "glyphID:u2 startConnectorLength:u2 endConnectorLength:u2 fullAdvance:u2 partFlags:u2")
  local mathConstants = parseConstants(header.mathConstantsOffset, fd)
  local mathGlyphInfo = vstruct.read(">@"..header.mathGlyphInfoOffset..
                                     " mathItalicsCorrectionInfoOffset:u2"..
                                     " mathTopAccentAttachmentOffset:u2"..
                                     " extendedShapeCoverageOffset:u2"..
                                     " mathKernInfoOffset:u2", fd)
  SU.debug("opentype-parser", "mathGlyphInfoOffset =", header.mathGlyphInfoOffset)
  SU.debug("opentype-parser", "mathGlyphInfo =", mathGlyphInfo)
  local mathItalicsCorrection = parseIfPresent(header.mathGlyphInfoOffset, mathGlyphInfo.mathItalicsCorrectionInfoOffset, function(offset)
    return parsePerGlyphTable(offset, "&MathValueRecord", fd)
  end)
  local mathTopAccentAttachment = parseIfPresent(header.mathGlyphInfoOffset, mathGlyphInfo.mathTopAccentAttachmentOffset, function(offset)
    return parsePerGlyphTable(offset, "&MathValueRecord", fd)
  end)
  local extendedShapeCoverage = parseIfPresent(header.mathGlyphInfoOffset, mathGlyphInfo.extendedShapeCoverageOffset, function(offset)
    return parseCoverage(offset, fd)
  end)
  local mathKernInfo = parseIfPresent(header.mathGlyphInfoOffset, mathGlyphInfo.mathKernInfoOffset, function(offset)
    return parsePerGlyphTable(offset, "&MathKernInfoRecord", fd)
  end)
  local mathVariants = parseMathVariants(header.mathVariantsOffset, fd)
  return {
    mathConstants = mathConstants,
    mathItalicsCorrection = mathItalicsCorrection,
    mathTopAccentAttachment = mathTopAccentAttachment,
    extendedShapeCoverage = extendedShapeCoverage,
    mathKernInfo = mathKernInfo,
    mathVariants = mathVariants
  }
end

local function parsePost(s)
  if s:len() <= 0 then return end
  local fd = vstruct.cursor(s)
  local header = vstruct.read(">majorVersion:u2 minorVersion:u2 italicAngle:i4 underlinePosition:i2 underlineThickness:i2 isFixedPitch:u4", fd)
  local italicAngle = header.italicAngle / 65536 -- 1 << 16
  return {
    italicAngle = italicAngle,
    underlinePosition = header.underlinePosition,
    underlineThickness = header.underlineThickness
  }
end

local function parseOs2(s)
  if s:len() <= 0 then return end
  local fd = vstruct.cursor(s)
  local header = vstruct.read(">version:u2 xAvgCharWidth:i2 usWeightClass:u2 usWidthClass:u2 fsType:u2 ySubscriptXSize:i2 ySubscriptYSize:i2 ySubscriptXOffset:i2 ySubscriptYOffset:i2 ySuperscriptXSize:i2 ySuperscriptYSize:i2 ySuperscriptXOffset:i2 ySuperscriptYOffset:i2, yStrikeoutSize:i2 yStrikeoutPosition:i2", fd)
  return {
    yStrikeoutPosition = header.yStrikeoutPosition,
    yStrikeoutSize = header.yStrikeoutSize,
  }
end

local parseFont = function(face)
  if not face.font then
    local font = {}
    font.head = parseHead(hb.get_table(face.data, face.index, "head"))
    font.names = parseName(hb.get_table(face.data, face.index, "name"))
    font.maxp = parseMaxp(hb.get_table(face.data, face.index, "maxp"))
    font.colr = parseColr(hb.get_table(face.data, face.index, "COLR"))
    font.cpal = parseCpal(hb.get_table(face.data, face.index, "CPAL"))
    font.svg  = parseSvg(hb.get_table(face.data, face.index, "SVG"))
    font.math = parseMath(hb.get_table(face.data, face.index, "MATH"))
    font.post = parsePost(hb.get_table(face.data, face.index, "post"))
    font.os2 = parseOs2(hb.get_table(face.data, face.index, "OS/2"))
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

return { parseHead = parseHead, parseMath = parseMath, parseFont = parseFont, getSVG = getSVG }
