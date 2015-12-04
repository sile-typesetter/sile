local vstruct = require "vstruct"
local hb = require "justenoughharfbuzz"

local parseName = function(s)
  if s:len() <= 0 then return end
  local fd = vstruct.cursor(s)

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
      else
        -- I don't actually care
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

local parseMaxp = function(s)
  if s:len() <= 0 then return end
  local fd = vstruct.cursor(s)

  return vstruct.read(">version:u4 numGlyphs:u2", fd)
end

local parseFont = function(face)
  local font = {}

  font.names = parseName(hb.get_table(face.data, face.index, "name"))
  font.maxp = parseMaxp(hb.get_table(face.data, face.index, "maxp"))

  return font
end

return { parseFont = parseFont }
