--- GENERATED FILE, DO NOT EDIT MANUALLY
--
-- Operator dictionary for unicode characters
--
-- Extracted from https://raw.githubusercontent.com/w3c/xml-entities/gh-pages/unicode.xml
-- (https://github.com/w3c/xml-entities)
--    Copyright David Carlisle 1999-2024
--    Use and distribution of this code are permitted under the terms of the
--    W3C Software Notice and License.
--    http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231.html
--    This file is a collection of information about how to map Unicode entities to LaTeX,
--    and various SGML/XML entity sets (ISO and MathML/HTML).
--    A Unicode character may be mapped to several entities.
--    Originally designed by Sebastian Rahtz in conjunction with Barbara Beeton for the STIX project
--

local atoms = require("packages/math/atoms")
local atomTypeShort = atoms.atomTypeShort

--- Transform a list of codepoints into a string
local function U (...)
  local t = { ... }
  local str = ""
  for i = 1, #t do
    str = str .. luautf8.char(t[i])
  end
  return str
end

local symbols = {}
local operatorDict = {}

--- Register a symbol
-- @tparam string str       String representation of the symbol
-- @tparam string shortatom Short atom type
-- @tparam string mathlatex TeX-like name of the symbol (from unicode-math)
-- @tparam string _         Unicode name of the symbol (informative)
-- @tparam table  ops       List of operator forms and their properties
local function addSymbol (str, shortatom, mathlatex, _, ops)
  if mathlatex then
    SU.debug("math.symbols", "Registering symbol", str, "as", mathlatex)
    symbols[mathlatex] = str
  end
  local op = {}
  op.atom = atomTypeShort[shortatom]
  if ops then
    op.forms = {}
    for _, v in pairs(ops) do
      if v.form then
        -- NOTE: At this point the mu unit is not yet defined, so keep it as a string.
        v.lspace = v.lspace and ("%smu"):format(v.lspace) or "0mu"
        v.rspace = v.rspace and ("%smu"):format(v.rspace) or "0mu"
        op.forms[v.form] = v
      else
        SU.warn("No form for operator " .. str .. " (operator dictionary is probably incomplete)")
      end
    end
  end
  operatorDict[str] = op
end


addSymbol(U(0x00021), "ord", "mathexclam", "EXCLAMATION MARK", {
  { form = "postfix", lspace = 0, priority = 820, rspace = 0 },
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x00021, 0x00021), "ord", nil, "MULTIPLE CHARACTER OPERATOR: !!", {
  { form = "postfix", lspace = 0, priority = 820, rspace = 0 }})
addSymbol(U(0x00021, 0x0003D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: !=", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x00022), "ord", nil, "QUOTATION MARK", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x00023), "ord", "mathoctothorpe", "NUMBER SIGN", nil)
addSymbol(U(0x00024), "ord", "mathdollar", "DOLLAR SIGN", nil)
addSymbol(U(0x00025), "ord", "mathpercent", "PERCENT SIGN", {
  { form = "postfix", lspace = 0, priority = 820, rspace = 0 },
  { form = "infix", lspace = 3, priority = 640, rspace = 3 }})
addSymbol(U(0x00026), "ord", "mathampersand", "AMPERSAND", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x00026, 0x00026), "ord", nil, "MULTIPLE CHARACTER OPERATOR: &&", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x00027), "ord", nil, "APOSTROPHE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x00028), "open", "lparen", "LEFT PARENTHESIS", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x00029), "close", "rparen", "RIGHT PARENTHESIS", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0002A), "ord", nil, "ASTERISK", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x0002A, 0x0002A), "ord", nil, "MULTIPLE CHARACTER OPERATOR: **", {
  { form = "infix", lspace = 3, priority = 760, rspace = 3 }})
addSymbol(U(0x0002A, 0x0003D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: *=", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0002B), "bin", "mathplus", "PLUS SIGN", {
  { form = "prefix", lspace = 0, priority = 720, rspace = 0 },
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x0002B, 0x0002B), "ord", nil, "MULTIPLE CHARACTER OPERATOR: ++", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x0002B, 0x0003D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: +=", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0002C), "punct", "mathcomma", "COMMA", {
  { form = "infix", linebreakstyle = "after", lspace = 0, priority = 160, rspace = 3, separator = true }})
addSymbol(U(0x0002D), "ord", nil, "HYPHEN-MINUS", {
  { form = "prefix", lspace = 0, priority = 720, rspace = 0 },
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x0002D, 0x0002D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: --", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x0002D, 0x0003D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: -=", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0002D, 0x0003E), "ord", nil, "MULTIPLE CHARACTER OPERATOR: ->", {
  { form = "infix", lspace = 5, priority = 220, rspace = 5 }})
addSymbol(U(0x0002E), "punct", "mathperiod", "FULL STOP", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x0002F), "bin", "mathslash", "SOLIDUS", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x0002F, 0x0002F), "ord", nil, "MULTIPLE CHARACTER OPERATOR: //", {
  { form = "infix", lspace = 5, priority = 240, rspace = 5 }})
addSymbol(U(0x0002F, 0x0003D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: /=", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0003A), "punct", "mathcolon", "COLON", {
  { form = "infix", lspace = 0, priority = 180, rspace = 3 }})
addSymbol(U(0x0003A, 0x0003D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: :=", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0003B), "punct", "mathsemicolon", "SEMICOLON", {
  { form = "infix", linebreakstyle = "after", lspace = 0, priority = 140, rspace = 3, separator = true }})
addSymbol(U(0x0003C), "rel", "less", "LESS-THAN SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0003C, 0x0003D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: <=", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0003C, 0x0003E), "ord", nil, "MULTIPLE CHARACTER OPERATOR: <>", {
  { form = "infix", lspace = 3, priority = 800, rspace = 3 }})
addSymbol(U(0x0003D), "rel", "equal", "EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0003D, 0x0003D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: ==", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0003E), "rel", "greater", "GREATER-THAN SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0003E, 0x0003D), "ord", nil, "MULTIPLE CHARACTER OPERATOR: >=", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0003F), "punct", "mathquestion", "QUESTION MARK", {
  { form = "infix", lspace = 3, priority = 840, rspace = 3 }})
addSymbol(U(0x00040), "ord", "mathatsign", "COMMERCIAL AT", {
  { form = "infix", lspace = 3, priority = 560, rspace = 3 }})
addSymbol(U(0x0005B), "open", "lbrack", "LEFT SQUARE BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0005C), "bin", "backslash", "REVERSE SOLIDUS", {
  { form = "infix", lspace = 0, priority = 660, rspace = 0 }})
addSymbol(U(0x0005D), "close", "rbrack", "RIGHT SQUARE BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0005E), "ord", nil, "CIRCUMFLEX ACCENT", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true },
  { form = "infix", lspace = 3, priority = 800, rspace = 3 }})
addSymbol(U(0x0005F), "ord", nil, "LOW LINE", {
  { form = "infix", lspace = 0, priority = 940, rspace = 0 },
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x00060), "ord", nil, "GRAVE ACCENT", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x0007B), "open", "lbrace", "LEFT CURLY BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0007C), "ord", "vert", "VERTICAL LINE", {
  { fence = true, form = "infix", lspace = 5, priority = 320, rspace = 5 },
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true },
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0007C, 0x0007C), "ord", nil, "MULTIPLE CHARACTER OPERATOR: ||", {
  { fence = true, form = "infix", lspace = 5, priority = 320, rspace = 5 },
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0 },
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0 }})
addSymbol(U(0x0007D), "close", "rbrace", "RIGHT CURLY BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0007E), "ord", nil, "TILDE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x000A1), "punct", nil, "INVERTED EXCLAMATION MARK", nil)
addSymbol(U(0x000A3), "ord", "mathsterling", "POUND SIGN", nil)
addSymbol(U(0x000A5), "ord", "mathyen", "YEN SIGN", nil)
addSymbol(U(0x000A7), "ord", "mathsection", "SECTION SIGN", nil)
addSymbol(U(0x000A8), "ord", nil, "DIAERESIS", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x000AC), "ord", "neg", "NOT SIGN", {
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x000AF), "ord", nil, "MACRON", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x000B0), "ord", nil, "DEGREE SIGN", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x000B1), "bin", "pm", "PLUS-MINUS SIGN", {
  { form = "prefix", lspace = 0, priority = 720, rspace = 0 },
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x000B2), "ord", nil, "SUPERSCRIPT TWO", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x000B3), "ord", nil, "SUPERSCRIPT THREE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x000B4), "ord", nil, "ACUTE ACCENT", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x000B6), "ord", "mathparagraph", "PILCROW SIGN", nil)
addSymbol(U(0x000B7), "bin", "cdotp", "MIDDLE DOT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x000B8), "ord", nil, "CEDILLA", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x000B9), "ord", nil, "SUPERSCRIPT ONE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x000BF), "punct", nil, "INVERTED QUESTION MARK", nil)
addSymbol(U(0x000D7), "bin", "times", "MULTIPLICATION SIGN", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x000F0), "ord", "matheth", "LATIN SMALL LETTER ETH", nil)
addSymbol(U(0x000F7), "bin", "div", "DIVISION SIGN", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x001B5), "ord", "Zbar", "LATIN CAPITAL LETTER Z WITH STROKE", nil)
addSymbol(U(0x002C6), "ord", nil, "MODIFIER LETTER CIRCUMFLEX ACCENT", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x002C7), "ord", nil, "CARON", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x002C9), "ord", nil, "MODIFIER LETTER MACRON", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x002CA), "ord", nil, "MODIFIER LETTER ACUTE ACCENT", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x002CB), "ord", nil, "MODIFIER LETTER GRAVE ACCENT", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x002CD), "ord", nil, "MODIFIER LETTER LOW MACRON", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x002D8), "ord", nil, "BREVE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x002D9), "ord", nil, "DOT ABOVE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x002DA), "ord", nil, "RING ABOVE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x002DC), "ord", nil, "SMALL TILDE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x002DD), "ord", nil, "DOUBLE ACUTE ACCENT", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x002F7), "ord", nil, "MODIFIER LETTER LOW TILDE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x00300), "accent", "grave", "COMBINING GRAVE ACCENT", nil)
addSymbol(U(0x00301), "accent", "acute", "COMBINING ACUTE ACCENT", nil)
addSymbol(U(0x00302), "accent", "hat", "COMBINING CIRCUMFLEX ACCENT", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x00303), "accent", "tilde", "COMBINING TILDE", nil)
addSymbol(U(0x00304), "accent", "bar", "COMBINING MACRON", nil)
addSymbol(U(0x00305), "accent", "overbar", "COMBINING OVERLINE", nil)
addSymbol(U(0x00306), "accent", "breve", "COMBINING BREVE", nil)
addSymbol(U(0x00307), "accent", "dot", "COMBINING DOT ABOVE", nil)
addSymbol(U(0x00308), "accent", "ddot", "COMBINING DIAERESIS", nil)
addSymbol(U(0x00309), "ord", "ovhook", "COMBINING HOOK ABOVE", nil)
addSymbol(U(0x0030A), "accent", "ocirc", "COMBINING RING ABOVE", nil)
addSymbol(U(0x0030C), "accent", "check", "COMBINING CARON", nil)
addSymbol(U(0x00310), "ord", "candra", "COMBINING CANDRABINDU", nil)
addSymbol(U(0x00311), "accent", nil, "COMBINING INVERTED BREVE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x00312), "ord", "oturnedcomma", "COMBINING TURNED COMMA ABOVE", nil)
addSymbol(U(0x00315), "ord", "ocommatopright", "COMBINING COMMA ABOVE RIGHT", nil)
addSymbol(U(0x0031A), "ord", "droang", "COMBINING LEFT ANGLE ABOVE", nil)
addSymbol(U(0x00323), "botaccent", nil, "COMBINING DOT BELOW", nil)
addSymbol(U(0x0032C), "botaccent", nil, "COMBINING CARON BELOW", nil)
addSymbol(U(0x0032D), "botaccent", nil, "COMBINING CIRCUMFLEX ACCENT BELOW", nil)
addSymbol(U(0x0032E), "botaccent", nil, "COMBINING BREVE BELOW", nil)
addSymbol(U(0x0032F), "botaccent", nil, "COMBINING INVERTED BREVE BELOW", nil)
addSymbol(U(0x00330), "botaccent", "wideutilde", "COMBINING TILDE BELOW", nil)
addSymbol(U(0x00331), "botaccent", nil, "COMBINING MACRON BELOW", nil)
addSymbol(U(0x00332), "botaccent", "mathunderbar", "COMBINING LOW LINE", nil)
addSymbol(U(0x00333), "botaccent", nil, "COMBINING DOUBLE LOW LINE", nil)
addSymbol(U(0x00338), "ord", "notaccent", "COMBINING LONG SOLIDUS OVERLAY", nil)
addSymbol(U(0x0033A), "botaccent", nil, "COMBINING INVERTED BRIDGE BELOW", nil)
addSymbol(U(0x0033F), "accent", nil, "COMBINING DOUBLE OVERLINE", nil)
addSymbol(U(0x00346), "accent", nil, "COMBINING BRIDGE ABOVE", nil)
addSymbol(U(0x0034D), "ord", "underleftrightarrow", "COMBINING LEFT RIGHT ARROW BELOW", nil)
addSymbol(U(0x00391), "ord", "mupAlpha", "GREEK CAPITAL LETTER ALPHA", nil)
addSymbol(U(0x00392), "ord", "mupBeta", "GREEK CAPITAL LETTER BETA", nil)
addSymbol(U(0x00393), "ord", "mupGamma", "GREEK CAPITAL LETTER GAMMA", nil)
addSymbol(U(0x00394), "ord", "mupDelta", "GREEK CAPITAL LETTER DELTA", nil)
addSymbol(U(0x00395), "ord", "mupEpsilon", "GREEK CAPITAL LETTER EPSILON", nil)
addSymbol(U(0x00396), "ord", "mupZeta", "GREEK CAPITAL LETTER ZETA", nil)
addSymbol(U(0x00397), "ord", "mupEta", "GREEK CAPITAL LETTER ETA", nil)
addSymbol(U(0x00398), "ord", "mupTheta", "GREEK CAPITAL LETTER THETA", nil)
addSymbol(U(0x00399), "ord", "mupIota", "GREEK CAPITAL LETTER IOTA", nil)
addSymbol(U(0x0039A), "ord", "mupKappa", "GREEK CAPITAL LETTER KAPPA", nil)
addSymbol(U(0x0039B), "ord", "mupLambda", "GREEK CAPITAL LETTER LAMDA", nil)
addSymbol(U(0x0039C), "ord", "mupMu", "GREEK CAPITAL LETTER MU", nil)
addSymbol(U(0x0039D), "ord", "mupNu", "GREEK CAPITAL LETTER NU", nil)
addSymbol(U(0x0039E), "ord", "mupXi", "GREEK CAPITAL LETTER XI", nil)
addSymbol(U(0x0039F), "ord", "mupOmicron", "GREEK CAPITAL LETTER OMICRON", nil)
addSymbol(U(0x003A0), "ord", "mupPi", "GREEK CAPITAL LETTER PI", nil)
addSymbol(U(0x003A1), "ord", "mupRho", "GREEK CAPITAL LETTER RHO", nil)
addSymbol(U(0x003A3), "ord", "mupSigma", "GREEK CAPITAL LETTER SIGMA", nil)
addSymbol(U(0x003A4), "ord", "mupTau", "GREEK CAPITAL LETTER TAU", nil)
addSymbol(U(0x003A5), "ord", "mupUpsilon", "GREEK CAPITAL LETTER UPSILON", nil)
addSymbol(U(0x003A6), "ord", "mupPhi", "GREEK CAPITAL LETTER PHI", nil)
addSymbol(U(0x003A7), "ord", "mupChi", "GREEK CAPITAL LETTER CHI", nil)
addSymbol(U(0x003A8), "ord", "mupPsi", "GREEK CAPITAL LETTER PSI", nil)
addSymbol(U(0x003A9), "ord", "mupOmega", "GREEK CAPITAL LETTER OMEGA", nil)
addSymbol(U(0x003B1), "ord", "mupalpha", "GREEK SMALL LETTER ALPHA", nil)
addSymbol(U(0x003B2), "ord", "mupbeta", "GREEK SMALL LETTER BETA", nil)
addSymbol(U(0x003B3), "ord", "mupgamma", "GREEK SMALL LETTER GAMMA", nil)
addSymbol(U(0x003B4), "ord", "mupdelta", "GREEK SMALL LETTER DELTA", nil)
addSymbol(U(0x003B5), "ord", "mupvarepsilon", "GREEK SMALL LETTER EPSILON", nil)
addSymbol(U(0x003B6), "ord", "mupzeta", "GREEK SMALL LETTER ZETA", nil)
addSymbol(U(0x003B7), "ord", "mupeta", "GREEK SMALL LETTER ETA", nil)
addSymbol(U(0x003B8), "ord", "muptheta", "GREEK SMALL LETTER THETA", nil)
addSymbol(U(0x003B9), "ord", "mupiota", "GREEK SMALL LETTER IOTA", nil)
addSymbol(U(0x003BA), "ord", "mupkappa", "GREEK SMALL LETTER KAPPA", nil)
addSymbol(U(0x003BB), "ord", "muplambda", "GREEK SMALL LETTER LAMDA", nil)
addSymbol(U(0x003BC), "ord", "mupmu", "GREEK SMALL LETTER MU", nil)
addSymbol(U(0x003BD), "ord", "mupnu", "GREEK SMALL LETTER NU", nil)
addSymbol(U(0x003BE), "ord", "mupxi", "GREEK SMALL LETTER XI", nil)
addSymbol(U(0x003BF), "ord", "mupomicron", "GREEK SMALL LETTER OMICRON", nil)
addSymbol(U(0x003C0), "ord", "muppi", "GREEK SMALL LETTER PI", nil)
addSymbol(U(0x003C1), "ord", "muprho", "GREEK SMALL LETTER RHO", nil)
addSymbol(U(0x003C2), "ord", "mupvarsigma", "GREEK SMALL LETTER FINAL SIGMA", nil)
addSymbol(U(0x003C3), "ord", "mupsigma", "GREEK SMALL LETTER SIGMA", nil)
addSymbol(U(0x003C4), "ord", "muptau", "GREEK SMALL LETTER TAU", nil)
addSymbol(U(0x003C5), "ord", "mupupsilon", "GREEK SMALL LETTER UPSILON", nil)
addSymbol(U(0x003C6), "ord", "mupvarphi", "GREEK SMALL LETTER PHI", nil)
addSymbol(U(0x003C7), "ord", "mupchi", "GREEK SMALL LETTER CHI", nil)
addSymbol(U(0x003C8), "ord", "muppsi", "GREEK SMALL LETTER PSI", nil)
addSymbol(U(0x003C9), "ord", "mupomega", "GREEK SMALL LETTER OMEGA", nil)
addSymbol(U(0x003D1), "ord", "mupvartheta", "GREEK THETA SYMBOL", nil)
addSymbol(U(0x003D5), "ord", "mupphi", "GREEK PHI SYMBOL", nil)
addSymbol(U(0x003D6), "ord", "mupvarpi", "GREEK PI SYMBOL", nil)
addSymbol(U(0x003DC), "ord", "upDigamma", "GREEK LETTER DIGAMMA", nil)
addSymbol(U(0x003DD), "ord", "updigamma", "GREEK SMALL LETTER DIGAMMA", nil)
addSymbol(U(0x003F0), "ord", "mupvarkappa", "GREEK KAPPA SYMBOL", nil)
addSymbol(U(0x003F1), "ord", "mupvarrho", "GREEK RHO SYMBOL", nil)
addSymbol(U(0x003F4), "ord", "mupvarTheta", "GREEK CAPITAL THETA SYMBOL", nil)
addSymbol(U(0x003F5), "ord", "mupepsilon", "GREEK LUNATE EPSILON SYMBOL", nil)
addSymbol(U(0x003F6), "ord", "upbackepsilon", "GREEK REVERSED LUNATE EPSILON SYMBOL", nil)
addSymbol(U(0x00606), "op", nil, "ARABIC-INDIC CUBE ROOT", nil)
addSymbol(U(0x00607), "op", nil, "ARABIC-INDIC FOURTH ROOT", nil)
addSymbol(U(0x02010), "punct", "mathhyphen", "HYPHEN", nil)
addSymbol(U(0x02012), "punct", nil, "FIGURE DASH", nil)
addSymbol(U(0x02013), "punct", nil, "EN DASH", nil)
addSymbol(U(0x02014), "punct", nil, "EM DASH", nil)
addSymbol(U(0x02015), "ord", "horizbar", "HORIZONTAL BAR", nil)
addSymbol(U(0x02016), "ord", "Vert", "DOUBLE VERTICAL LINE", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true },
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02017), "ord", "twolowline", "DOUBLE LOW LINE", nil)
addSymbol(U(0x02018), "ord", nil, "LEFT SINGLE QUOTATION MARK", {
  { fence = true, form = "prefix", lspace = 0, priority = 100, rspace = 0 }})
addSymbol(U(0x02019), "ord", nil, "RIGHT SINGLE QUOTATION MARK", {
  { fence = true, form = "postfix", lspace = 0, priority = 100, rspace = 0 }})
addSymbol(U(0x0201A), "ord", nil, "SINGLE LOW-9 QUOTATION MARK", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x0201B), "ord", nil, "SINGLE HIGH-REVERSED-9 QUOTATION MARK", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x0201C), "ord", nil, "LEFT DOUBLE QUOTATION MARK", {
  { fence = true, form = "prefix", lspace = 0, priority = 100, rspace = 0 }})
addSymbol(U(0x0201D), "ord", nil, "RIGHT DOUBLE QUOTATION MARK", {
  { fence = true, form = "postfix", lspace = 0, priority = 100, rspace = 0 }})
addSymbol(U(0x0201E), "ord", nil, "DOUBLE LOW-9 QUOTATION MARK", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x0201F), "ord", nil, "DOUBLE HIGH-REVERSED-9 QUOTATION MARK", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x02020), "rel", "dagger", "DAGGER", nil)
addSymbol(U(0x02021), "rel", "ddagger", "DOUBLE DAGGER", nil)
addSymbol(U(0x02022), "bin", "smblkcircle", "BULLET", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02025), "ord", "enleadertwodots", "TWO DOT LEADER", nil)
addSymbol(U(0x02026), "ord", "unicodeellipsis", "HORIZONTAL ELLIPSIS", nil)
addSymbol(U(0x02032), "ord", "prime", "PRIME", {
  { form = "postfix", lspace = 0, priority = 820, rspace = 0 }})
addSymbol(U(0x02033), "ord", "dprime", "DOUBLE PRIME", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x02034), "ord", "trprime", "TRIPLE PRIME", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x02035), "ord", "backprime", "REVERSED PRIME", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x02036), "ord", "backdprime", "REVERSED DOUBLE PRIME", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x02037), "ord", "backtrprime", "REVERSED TRIPLE PRIME", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x02038), "ord", "caretinsert", "CARET", nil)
addSymbol(U(0x0203C), "ord", "Exclam", "DOUBLE EXCLAMATION MARK", nil)
addSymbol(U(0x0203E), "ord", nil, "OVERLINE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x02040), "bin", "tieconcat", "CHARACTER TIE", nil)
addSymbol(U(0x02043), "ord", "hyphenbullet", "HYPHEN BULLET", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02044), "bin", "fracslash", "FRACTION SLASH", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x02047), "ord", "Question", "DOUBLE QUESTION MARK", nil)
addSymbol(U(0x0204E), "bin", nil, "LOW ASTERISK", nil)
addSymbol(U(0x0204F), "rel", nil, "REVERSED SEMICOLON", nil)
addSymbol(U(0x02050), "rel", "closure", "CLOSE UP", nil)
addSymbol(U(0x02057), "ord", "qprime", "QUADRUPLE PRIME", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x02061), "bin", nil, "FUNCTION APPLICATION", {
  { form = "infix", lspace = 0, priority = 880, rspace = 0 }})
addSymbol(U(0x02062), "bin", nil, "INVISIBLE TIMES", {
  { form = "infix", lspace = 0, priority = 620, rspace = 0 }})
addSymbol(U(0x02063), "punct", nil, "INVISIBLE SEPARATOR", {
  { form = "infix", linebreakstyle = "after", lspace = 0, priority = 160, rspace = 0, separator = true }})
addSymbol(U(0x02064), "ord", nil, "INVISIBLE PLUS", {
  { form = "infix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x020AC), "ord", "euro", "EURO SIGN", nil)
addSymbol(U(0x020D0), "accent", "leftharpoonaccent", "COMBINING LEFT HARPOON ABOVE", nil)
addSymbol(U(0x020D1), "accent", "rightharpoonaccent", "COMBINING RIGHT HARPOON ABOVE", nil)
addSymbol(U(0x020D2), "ord", "vertoverlay", "COMBINING LONG VERTICAL LINE OVERLAY", nil)
addSymbol(U(0x020D4), "accent", nil, "COMBINING ANTICLOCKWISE ARROW ABOVE", nil)
addSymbol(U(0x020D5), "accent", nil, "COMBINING CLOCKWISE ARROW ABOVE", nil)
addSymbol(U(0x020D6), "accent", "overleftarrow", "COMBINING LEFT ARROW ABOVE", nil)
addSymbol(U(0x020D7), "accent", "overrightarrow", "COMBINING RIGHT ARROW ABOVE", nil)
addSymbol(U(0x020DB), "accent", "dddot", "COMBINING THREE DOTS ABOVE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x020DC), "accent", "ddddot", "COMBINING FOUR DOTS ABOVE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x020DD), "ord", "enclosecircle", "COMBINING ENCLOSING CIRCLE", nil)
addSymbol(U(0x020DE), "ord", "enclosesquare", "COMBINING ENCLOSING SQUARE", nil)
addSymbol(U(0x020DF), "ord", "enclosediamond", "COMBINING ENCLOSING DIAMOND", nil)
addSymbol(U(0x020E1), "accent", "overleftrightarrow", "COMBINING LEFT RIGHT ARROW ABOVE", nil)
addSymbol(U(0x020E4), "ord", "enclosetriangle", "COMBINING ENCLOSING UPWARD POINTING TRIANGLE", nil)
addSymbol(U(0x020E7), "accent", "annuity", "COMBINING ANNUITY SYMBOL", nil)
addSymbol(U(0x020E8), "botaccent", "threeunderdot", "COMBINING TRIPLE UNDERDOT", nil)
addSymbol(U(0x020E9), "accent", "widebridgeabove", "COMBINING WIDE BRIDGE ABOVE", nil)
addSymbol(U(0x020EC), "botaccent", "underrightharpoondown", "COMBINING RIGHTWARDS HARPOON WITH BARB DOWNWARDS", nil)
addSymbol(U(0x020ED), "botaccent", "underleftharpoondown", "COMBINING LEFTWARDS HARPOON WITH BARB DOWNWARDS", nil)
addSymbol(U(0x020EE), "botaccent", "underleftarrow", "COMBINING LEFT ARROW BELOW", nil)
addSymbol(U(0x020EF), "botaccent", "underrightarrow", "COMBINING RIGHT ARROW BELOW", nil)
addSymbol(U(0x020F0), "ord", "asteraccent", "COMBINING ASTERISK ABOVE", nil)
addSymbol(U(0x02102), "ord", "BbbC", "DOUBLE-STRUCK CAPITAL C", nil)
addSymbol(U(0x02107), "ord", "Eulerconst", "EULER CONSTANT", nil)
addSymbol(U(0x0210A), "ord", "mscrg", "SCRIPT SMALL G", nil)
addSymbol(U(0x0210B), "ord", "mscrH", "SCRIPT CAPITAL H", nil)
addSymbol(U(0x0210C), "ord", "mfrakH", "BLACK-LETTER CAPITAL H", nil)
addSymbol(U(0x0210D), "ord", "BbbH", "DOUBLE-STRUCK CAPITAL H", nil)
addSymbol(U(0x0210E), "ord", "Planckconst", "PLANCK CONSTANT", nil)
addSymbol(U(0x0210F), "ord", "hslash", "PLANCK CONSTANT OVER TWO PI", nil)
addSymbol(U(0x02110), "ord", "mscrI", "SCRIPT CAPITAL I", nil)
addSymbol(U(0x02111), "ord", "Im", "BLACK-LETTER CAPITAL I", nil)
addSymbol(U(0x02112), "ord", "mscrL", "SCRIPT CAPITAL L", nil)
addSymbol(U(0x02113), "ord", "ell", "SCRIPT SMALL L", nil)
addSymbol(U(0x02115), "ord", "BbbN", "DOUBLE-STRUCK CAPITAL N", nil)
addSymbol(U(0x02118), "ord", "wp", "SCRIPT CAPITAL P", nil)
addSymbol(U(0x02119), "ord", "BbbP", "DOUBLE-STRUCK CAPITAL P", nil)
addSymbol(U(0x0211A), "ord", "BbbQ", "DOUBLE-STRUCK CAPITAL Q", nil)
addSymbol(U(0x0211B), "ord", "mscrR", "SCRIPT CAPITAL R", nil)
addSymbol(U(0x0211C), "ord", "Re", "BLACK-LETTER CAPITAL R", nil)
addSymbol(U(0x0211D), "ord", "BbbR", "DOUBLE-STRUCK CAPITAL R", nil)
addSymbol(U(0x02124), "ord", "BbbZ", "DOUBLE-STRUCK CAPITAL Z", nil)
addSymbol(U(0x02127), "ord", "mho", "INVERTED OHM SIGN", nil)
addSymbol(U(0x02128), "ord", "mfrakZ", "BLACK-LETTER CAPITAL Z", nil)
addSymbol(U(0x02129), "ord", "turnediota", "TURNED GREEK SMALL LETTER IOTA", nil)
addSymbol(U(0x0212B), "ord", "Angstrom", "ANGSTROM SIGN", nil)
addSymbol(U(0x0212C), "ord", "mscrB", "SCRIPT CAPITAL B", nil)
addSymbol(U(0x0212D), "ord", "mfrakC", "BLACK-LETTER CAPITAL C", nil)
addSymbol(U(0x0212F), "ord", "mscre", "SCRIPT SMALL E", nil)
addSymbol(U(0x02130), "ord", "mscrE", "SCRIPT CAPITAL E", nil)
addSymbol(U(0x02131), "ord", "mscrF", "SCRIPT CAPITAL F", nil)
addSymbol(U(0x02132), "ord", "Finv", "TURNED CAPITAL F", nil)
addSymbol(U(0x02133), "ord", "mscrM", "SCRIPT CAPITAL M", nil)
addSymbol(U(0x02134), "ord", "mscro", "SCRIPT SMALL O", nil)
addSymbol(U(0x02135), "ord", "aleph", "ALEF SYMBOL", nil)
addSymbol(U(0x02136), "ord", "beth", "BET SYMBOL", nil)
addSymbol(U(0x02137), "ord", "gimel", "GIMEL SYMBOL", nil)
addSymbol(U(0x02138), "ord", "daleth", "DALET SYMBOL", nil)
addSymbol(U(0x0213C), "ord", "Bbbpi", "DOUBLE-STRUCK SMALL PI", nil)
addSymbol(U(0x0213D), "ord", "Bbbgamma", "DOUBLE-STRUCK SMALL GAMMA", nil)
addSymbol(U(0x0213E), "ord", "BbbGamma", "DOUBLE-STRUCK CAPITAL GAMMA", nil)
addSymbol(U(0x0213F), "ord", "BbbPi", "DOUBLE-STRUCK CAPITAL PI", nil)
addSymbol(U(0x02140), "op", "Bbbsum", "DOUBLE-STRUCK N-ARY SUMMATION", nil)
addSymbol(U(0x02141), "ord", "Game", "TURNED SANS-SERIF CAPITAL G", nil)
addSymbol(U(0x02142), "ord", "sansLturned", "TURNED SANS-SERIF CAPITAL L", nil)
addSymbol(U(0x02143), "ord", "sansLmirrored", "REVERSED SANS-SERIF CAPITAL L", nil)
addSymbol(U(0x02144), "ord", "Yup", "TURNED SANS-SERIF CAPITAL Y", nil)
addSymbol(U(0x02145), "ord", "mitBbbD", "DOUBLE-STRUCK ITALIC CAPITAL D", {
  { form = "prefix", lspace = 3, priority = 780, rspace = 0 }})
addSymbol(U(0x02146), "ord", "mitBbbd", "DOUBLE-STRUCK ITALIC SMALL D", {
  { form = "prefix", lspace = 3, priority = 780, rspace = 0 }})
addSymbol(U(0x02147), "ord", "mitBbbe", "DOUBLE-STRUCK ITALIC SMALL E", nil)
addSymbol(U(0x02148), "ord", "mitBbbi", "DOUBLE-STRUCK ITALIC SMALL I", nil)
addSymbol(U(0x02149), "ord", "mitBbbj", "DOUBLE-STRUCK ITALIC SMALL J", nil)
addSymbol(U(0x0214A), "ord", "PropertyLine", "PROPERTY LINE", nil)
addSymbol(U(0x0214B), "ord", "upand", "TURNED AMPERSAND", nil)
addSymbol(U(0x02190), "rel", "leftarrow", "LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02191), "rel", "uparrow", "UPWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02192), "rel", "rightarrow", "RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02193), "rel", "downarrow", "DOWNWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02194), "rel", "leftrightarrow", "LEFT RIGHT ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02195), "rel", "updownarrow", "UP DOWN ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02196), "rel", "nwarrow", "NORTH WEST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02197), "rel", "nearrow", "NORTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02198), "rel", "searrow", "SOUTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02199), "rel", "swarrow", "SOUTH WEST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0219A), "rel", "nleftarrow", "LEFTWARDS ARROW WITH STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0219B), "rel", "nrightarrow", "RIGHTWARDS ARROW WITH STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0219C), "rel", "leftwavearrow", "LEFTWARDS WAVE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0219D), "rel", "rightwavearrow", "RIGHTWARDS WAVE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0219E), "rel", "twoheadleftarrow", "LEFTWARDS TWO HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0219F), "rel", "twoheaduparrow", "UPWARDS TWO HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A0), "rel", "twoheadrightarrow", "RIGHTWARDS TWO HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A1), "rel", "twoheaddownarrow", "DOWNWARDS TWO HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A2), "rel", "leftarrowtail", "LEFTWARDS ARROW WITH TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A3), "rel", "rightarrowtail", "RIGHTWARDS ARROW WITH TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A4), "rel", "mapsfrom", "LEFTWARDS ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A5), "rel", "mapsup", "UPWARDS ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A6), "rel", "mapsto", "RIGHTWARDS ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A7), "rel", "mapsdown", "DOWNWARDS ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A8), "rel", "updownarrowbar", "UP DOWN ARROW WITH BASE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021A9), "rel", "hookleftarrow", "LEFTWARDS ARROW WITH HOOK", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021AA), "rel", "hookrightarrow", "RIGHTWARDS ARROW WITH HOOK", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021AB), "rel", "looparrowleft", "LEFTWARDS ARROW WITH LOOP", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021AC), "rel", "looparrowright", "RIGHTWARDS ARROW WITH LOOP", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021AD), "rel", "leftrightsquigarrow", "LEFT RIGHT WAVE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021AE), "rel", "nleftrightarrow", "LEFT RIGHT ARROW WITH STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021AF), "rel", "downzigzagarrow", "DOWNWARDS ZIGZAG ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021B0), "rel", "Lsh", "UPWARDS ARROW WITH TIP LEFTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021B1), "rel", "Rsh", "UPWARDS ARROW WITH TIP RIGHTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021B2), "rel", "Ldsh", "DOWNWARDS ARROW WITH TIP LEFTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021B3), "rel", "Rdsh", "DOWNWARDS ARROW WITH TIP RIGHTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021B4), "ord", "linefeed", "RIGHTWARDS ARROW WITH CORNER DOWNWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021B5), "ord", "carriagereturn", "DOWNWARDS ARROW WITH CORNER LEFTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021B6), "rel", "curvearrowleft", "ANTICLOCKWISE TOP SEMICIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021B7), "rel", "curvearrowright", "CLOCKWISE TOP SEMICIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021B8), "ord", "barovernorthwestarrow", "NORTH WEST ARROW TO LONG BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021B9), "ord", "barleftarrowrightarrowbar", "LEFTWARDS ARROW TO BAR OVER RIGHTWARDS ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021BA), "rel", "acwopencirclearrow", "ANTICLOCKWISE OPEN CIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021BB), "rel", "cwopencirclearrow", "CLOCKWISE OPEN CIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021BC), "rel", "leftharpoonup", "LEFTWARDS HARPOON WITH BARB UPWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021BD), "rel", "leftharpoondown", "LEFTWARDS HARPOON WITH BARB DOWNWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021BE), "rel", "upharpoonright", "UPWARDS HARPOON WITH BARB RIGHTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021BF), "rel", "upharpoonleft", "UPWARDS HARPOON WITH BARB LEFTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C0), "rel", "rightharpoonup", "RIGHTWARDS HARPOON WITH BARB UPWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C1), "rel", "rightharpoondown", "RIGHTWARDS HARPOON WITH BARB DOWNWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C2), "rel", "downharpoonright", "DOWNWARDS HARPOON WITH BARB RIGHTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C3), "rel", "downharpoonleft", "DOWNWARDS HARPOON WITH BARB LEFTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C4), "rel", "rightleftarrows", "RIGHTWARDS ARROW OVER LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C5), "rel", "updownarrows", "UPWARDS ARROW LEFTWARDS OF DOWNWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C6), "rel", "leftrightarrows", "LEFTWARDS ARROW OVER RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C7), "rel", "leftleftarrows", "LEFTWARDS PAIRED ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C8), "rel", "upuparrows", "UPWARDS PAIRED ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021C9), "rel", "rightrightarrows", "RIGHTWARDS PAIRED ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021CA), "rel", "downdownarrows", "DOWNWARDS PAIRED ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021CB), "rel", "leftrightharpoons", "LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021CC), "rel", "rightleftharpoons", "RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021CD), "rel", "nLeftarrow", "LEFTWARDS DOUBLE ARROW WITH STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021CE), "rel", "nLeftrightarrow", "LEFT RIGHT DOUBLE ARROW WITH STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021CF), "rel", "nRightarrow", "RIGHTWARDS DOUBLE ARROW WITH STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021D0), "rel", "Leftarrow", "LEFTWARDS DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021D1), "rel", "Uparrow", "UPWARDS DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021D2), "rel", "Rightarrow", "RIGHTWARDS DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021D3), "rel", "Downarrow", "DOWNWARDS DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021D4), "rel", "Leftrightarrow", "LEFT RIGHT DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021D5), "rel", "Updownarrow", "UP DOWN DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021D6), "rel", "Nwarrow", "NORTH WEST DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021D7), "rel", "Nearrow", "NORTH EAST DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021D8), "rel", "Searrow", "SOUTH EAST DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021D9), "rel", "Swarrow", "SOUTH WEST DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021DA), "rel", "Lleftarrow", "LEFTWARDS TRIPLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021DB), "rel", "Rrightarrow", "RIGHTWARDS TRIPLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021DC), "rel", "leftsquigarrow", "LEFTWARDS SQUIGGLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021DD), "rel", "rightsquigarrow", "RIGHTWARDS SQUIGGLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021DE), "rel", "nHuparrow", "UPWARDS ARROW WITH DOUBLE STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021DF), "rel", "nHdownarrow", "DOWNWARDS ARROW WITH DOUBLE STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E0), "rel", "leftdasharrow", "LEFTWARDS DASHED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E1), "rel", "updasharrow", "UPWARDS DASHED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E2), "rel", "rightdasharrow", "RIGHTWARDS DASHED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E3), "rel", "downdasharrow", "DOWNWARDS DASHED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E4), "rel", "barleftarrow", "LEFTWARDS ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E5), "rel", "rightarrowbar", "RIGHTWARDS ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E6), "rel", "leftwhitearrow", "LEFTWARDS WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E7), "rel", "upwhitearrow", "UPWARDS WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E8), "rel", "rightwhitearrow", "RIGHTWARDS WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021E9), "rel", "downwhitearrow", "DOWNWARDS WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021EA), "rel", "whitearrowupfrombar", "UPWARDS WHITE ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021EB), "rel", nil, "UPWARDS WHITE ARROW ON PEDESTAL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021EC), "rel", nil, "UPWARDS WHITE ARROW ON PEDESTAL WITH HORIZONTAL BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021ED), "rel", nil, "UPWARDS WHITE ARROW ON PEDESTAL WITH VERTICAL BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021EE), "rel", nil, "UPWARDS WHITE DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021EF), "rel", nil, "UPWARDS WHITE DOUBLE ARROW ON PEDESTAL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021F0), "rel", nil, "RIGHTWARDS WHITE ARROW FROM WALL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021F1), "rel", nil, "NORTH WEST ARROW TO CORNER", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021F2), "rel", nil, "SOUTH EAST ARROW TO CORNER", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x021F3), "rel", nil, "UP DOWN WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021F4), "rel", "circleonrightarrow", "RIGHT ARROW WITH SMALL CIRCLE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021F5), "rel", "downuparrows", "DOWNWARDS ARROW LEFTWARDS OF UPWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021F6), "rel", "rightthreearrows", "THREE RIGHTWARDS ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021F7), "rel", "nvleftarrow", "LEFTWARDS ARROW WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021F8), "rel", "nvrightarrow", "RIGHTWARDS ARROW WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021F9), "rel", "nvleftrightarrow", "LEFT RIGHT ARROW WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021FA), "rel", "nVleftarrow", "LEFTWARDS ARROW WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021FB), "rel", "nVrightarrow", "RIGHTWARDS ARROW WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021FC), "rel", "nVleftrightarrow", "LEFT RIGHT ARROW WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021FD), "rel", "leftarrowtriangle", "LEFTWARDS OPEN-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021FE), "rel", "rightarrowtriangle", "RIGHTWARDS OPEN-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x021FF), "rel", "leftrightarrowtriangle", "LEFT RIGHT OPEN-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02200), "ord", "forall", "FOR ALL", {
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x02201), "ord", "complement", "COMPLEMENT", {
  { form = "prefix", lspace = 0, priority = 720, rspace = 0 }})
addSymbol(U(0x02202), "ord", "partial", "PARTIAL DIFFERENTIAL", {
  { form = "prefix", lspace = 3, priority = 780, rspace = 0 }})
addSymbol(U(0x02203), "ord", "exists", "THERE EXISTS", {
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x02204), "ord", "nexists", "THERE DOES NOT EXIST", {
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x02205), "ord", "varnothing", "EMPTY SET", nil)
addSymbol(U(0x02206), "ord", "increment", "INCREMENT", {
  { form = "infix", lspace = 0, priority = 720, rspace = 0 }})
addSymbol(U(0x02207), "ord", "nabla", "NABLA", {
  { form = "prefix", lspace = 0, priority = 780, rspace = 0 }})
addSymbol(U(0x02208), "rel", "in", "ELEMENT OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02209), "rel", "notin", "NOT AN ELEMENT OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0220A), "rel", "smallin", "SMALL ELEMENT OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0220B), "rel", "ni", "CONTAINS AS MEMBER", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0220C), "rel", "nni", "DOES NOT CONTAIN AS MEMBER", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0220D), "rel", "smallni", "SMALL CONTAINS AS MEMBER", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0220E), "ord", "QED", "END OF PROOF", nil)
addSymbol(U(0x0220F), "op", "prod", "N-ARY PRODUCT", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 540, rspace = 3, symmetric = true }})
addSymbol(U(0x02210), "op", "coprod", "N-ARY COPRODUCT", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 540, rspace = 3, symmetric = true }})
addSymbol(U(0x02211), "op", "sum", "N-ARY SUMMATION", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 440, rspace = 3, symmetric = true }})
addSymbol(U(0x02212), "bin", "minus", "MINUS SIGN", {
  { form = "prefix", lspace = 0, priority = 720, rspace = 0 },
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02213), "bin", "mp", "MINUS-OR-PLUS SIGN", {
  { form = "prefix", lspace = 0, priority = 720, rspace = 0 },
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02214), "bin", "dotplus", "DOT PLUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02215), "bin", "divslash", "DIVISION SLASH", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x02216), "bin", "setminus", "SET MINUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02217), "bin", "ast", "ASTERISK OPERATOR", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02218), "bin", "vysmwhtcircle", "RING OPERATOR", {
  { form = "infix", lspace = 3, priority = 900, rspace = 3 }})
addSymbol(U(0x02219), "bin", "vysmblkcircle", "BULLET OPERATOR", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x0221A), "op", "sqrt", "SQUARE ROOT", {
  { form = "prefix", lspace = 3, priority = 860, rspace = 0 }})
addSymbol(U(0x0221B), "op", "cuberoot", "CUBE ROOT", {
  { form = "prefix", lspace = 3, priority = 860, rspace = 0 }})
addSymbol(U(0x0221C), "op", "fourthroot", "FOURTH ROOT", {
  { form = "prefix", lspace = 3, priority = 860, rspace = 0 }})
addSymbol(U(0x0221D), "rel", "propto", "PROPORTIONAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0221E), "ord", "infty", "INFINITY", nil)
addSymbol(U(0x0221F), "ord", "rightangle", "RIGHT ANGLE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x02220), "ord", "angle", "ANGLE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x02221), "ord", "measuredangle", "MEASURED ANGLE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x02222), "ord", "sphericalangle", "SPHERICAL ANGLE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x02223), "rel", "mid", "DIVIDES", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02224), "rel", "nmid", "DOES NOT DIVIDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02225), "rel", "parallel", "PARALLEL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02226), "rel", "nparallel", "NOT PARALLEL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02227), "bin", "wedge", "LOGICAL AND", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02228), "bin", "vee", "LOGICAL OR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02229), "bin", "cap", "INTERSECTION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x0222A), "bin", "cup", "UNION", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x0222B), "ord", "int", "INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x0222C), "ord", "iint", "DOUBLE INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x0222D), "ord", "iiint", "TRIPLE INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x0222E), "ord", "oint", "CONTOUR INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x0222F), "ord", "oiint", "SURFACE INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02230), "ord", "oiiint", "VOLUME INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02231), "ord", "intclockwise", "CLOCKWISE INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02232), "ord", "varointclockwise", "CLOCKWISE CONTOUR INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02233), "ord", "ointctrclockwise", "ANTICLOCKWISE CONTOUR INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02234), "rel", "therefore", "THEREFORE", {
  { form = "prefix", lspace = 0, priority = 200, rspace = 0 }})
addSymbol(U(0x02235), "rel", "because", "BECAUSE", {
  { form = "prefix", lspace = 0, priority = 200, rspace = 0 }})
addSymbol(U(0x02236), "rel", "mathratio", "RATIO", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x02237), "rel", "Colon", "PROPORTION", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02238), "bin", "dotminus", "DOT MINUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02239), "rel", "dashcolon", "EXCESS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0223A), "rel", "dotsminusdots", "GEOMETRIC PROPORTION", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0223B), "rel", "kernelcontraction", "HOMOTHETIC", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0223C), "rel", "sim", "TILDE OPERATOR", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 },
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x0223D), "rel", "backsim", "REVERSED TILDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0223E), "bin", "invlazys", "INVERTED LAZY S", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0223F), "ord", "sinewave", "SINE WAVE", nil)
addSymbol(U(0x02240), "bin", "wr", "WREATH PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02241), "rel", "nsim", "NOT TILDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02242), "rel", "eqsim", "MINUS TILDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02243), "rel", "simeq", "ASYMPTOTICALLY EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02244), "rel", "nsime", "NOT ASYMPTOTICALLY EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02245), "rel", "cong", "APPROXIMATELY EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02246), "rel", "simneqq", "APPROXIMATELY BUT NOT ACTUALLY EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02247), "rel", "ncong", "NEITHER APPROXIMATELY NOR ACTUALLY EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02248), "rel", "approx", "ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02249), "rel", "napprox", "NOT ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0224A), "rel", "approxeq", "ALMOST EQUAL OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0224B), "rel", "approxident", "TRIPLE TILDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0224C), "rel", "backcong", "ALL EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0224D), "rel", "asymp", "EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0224E), "rel", "Bumpeq", "GEOMETRICALLY EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0224F), "rel", "bumpeq", "DIFFERENCE BETWEEN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02250), "rel", "doteq", "APPROACHES THE LIMIT", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02251), "rel", "Doteq", "GEOMETRICALLY EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02252), "rel", "fallingdotseq", "APPROXIMATELY EQUAL TO OR THE IMAGE OF", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02253), "rel", "risingdotseq", "IMAGE OF OR APPROXIMATELY EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02254), "rel", "coloneq", "COLON EQUALS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02255), "rel", "eqcolon", "EQUALS COLON", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02256), "rel", "eqcirc", "RING IN EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02257), "rel", "circeq", "RING EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02258), "rel", "arceq", "CORRESPONDS TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02259), "rel", "wedgeq", "ESTIMATES", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0225A), "rel", "veeeq", "EQUIANGULAR TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0225B), "rel", "stareq", "STAR EQUALS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0225C), "rel", "triangleq", "DELTA EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0225D), "rel", "eqdef", "EQUAL TO BY DEFINITION", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0225E), "rel", "measeq", "MEASURED BY", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0225F), "rel", "questeq", "QUESTIONED EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02260), "rel", "ne", "NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02261), "rel", "equiv", "IDENTICAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02262), "rel", "nequiv", "NOT IDENTICAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02263), "rel", "Equiv", "STRICTLY EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02264), "rel", "leq", "LESS-THAN OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02265), "rel", "geq", "GREATER-THAN OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02266), "rel", "leqq", "LESS-THAN OVER EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02267), "rel", "geqq", "GREATER-THAN OVER EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02268), "rel", "lneqq", "LESS-THAN BUT NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02269), "rel", "gneqq", "GREATER-THAN BUT NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0226A), "rel", "ll", "MUCH LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0226B), "rel", "gg", "MUCH GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0226C), "rel", "between", "BETWEEN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0226D), "rel", "nasymp", "NOT EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0226E), "rel", "nless", "NOT LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0226F), "rel", "ngtr", "NOT GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02270), "rel", "nleq", "NEITHER LESS-THAN NOR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02271), "rel", "ngeq", "NEITHER GREATER-THAN NOR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02272), "rel", "lesssim", "LESS-THAN OR EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02273), "rel", "gtrsim", "GREATER-THAN OR EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02274), "rel", "nlesssim", "NEITHER LESS-THAN NOR EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02275), "rel", "ngtrsim", "NEITHER GREATER-THAN NOR EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02276), "rel", "lessgtr", "LESS-THAN OR GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02277), "rel", "gtrless", "GREATER-THAN OR LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02278), "rel", "nlessgtr", "NEITHER LESS-THAN NOR GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02279), "rel", "ngtrless", "NEITHER GREATER-THAN NOR LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0227A), "rel", "prec", "PRECEDES", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0227B), "rel", "succ", "SUCCEEDS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0227C), "rel", "preccurlyeq", "PRECEDES OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0227D), "rel", "succcurlyeq", "SUCCEEDS OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0227E), "rel", "precsim", "PRECEDES OR EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0227F), "rel", "succsim", "SUCCEEDS OR EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02280), "rel", "nprec", "DOES NOT PRECEDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02281), "rel", "nsucc", "DOES NOT SUCCEED", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02282), "rel", "subset", "SUBSET OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02283), "rel", "supset", "SUPERSET OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02284), "rel", "nsubset", "NOT A SUBSET OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02285), "rel", "nsupset", "NOT A SUPERSET OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02286), "rel", "subseteq", "SUBSET OF OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02287), "rel", "supseteq", "SUPERSET OF OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02288), "rel", "nsubseteq", "NEITHER A SUBSET OF NOR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02289), "rel", "nsupseteq", "NEITHER A SUPERSET OF NOR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0228A), "rel", "subsetneq", "SUBSET OF WITH NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0228B), "rel", "supsetneq", "SUPERSET OF WITH NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0228C), "bin", "cupleftarrow", "MULTISET", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x0228D), "bin", "cupdot", "MULTISET MULTIPLICATION", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x0228E), "bin", "uplus", "MULTISET UNION", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x0228F), "rel", "sqsubset", "SQUARE IMAGE OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02290), "rel", "sqsupset", "SQUARE ORIGINAL OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02291), "rel", "sqsubseteq", "SQUARE IMAGE OF OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02292), "rel", "sqsupseteq", "SQUARE ORIGINAL OF OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02293), "bin", "sqcap", "SQUARE CAP", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02294), "bin", "sqcup", "SQUARE CUP", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x02295), "bin", "oplus", "CIRCLED PLUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02296), "bin", "ominus", "CIRCLED MINUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02297), "bin", "otimes", "CIRCLED TIMES", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02298), "bin", "oslash", "CIRCLED DIVISION SLASH", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x02299), "bin", "odot", "CIRCLED DOT OPERATOR", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x0229A), "bin", "circledcirc", "CIRCLED RING OPERATOR", {
  { form = "infix", lspace = 3, priority = 900, rspace = 3 }})
addSymbol(U(0x0229B), "bin", "circledast", "CIRCLED ASTERISK OPERATOR", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x0229C), "bin", "circledequal", "CIRCLED EQUALS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x0229D), "bin", "circleddash", "CIRCLED DASH", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x0229E), "bin", "boxplus", "SQUARED PLUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x0229F), "bin", "boxminus", "SQUARED MINUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x022A0), "bin", "boxtimes", "SQUARED TIMES", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022A1), "bin", "boxdot", "SQUARED DOT OPERATOR", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022A2), "rel", "vdash", "RIGHT TACK", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022A3), "rel", "dashv", "LEFT TACK", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022A4), "ord", "top", "DOWN TACK", nil)
addSymbol(U(0x022A5), "rel", "bot", "UP TACK", nil)
addSymbol(U(0x022A6), "rel", "assert", "ASSERTION", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022A7), "rel", "models", "MODELS", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022A8), "rel", "vDash", "TRUE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022A9), "rel", "Vdash", "FORCES", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022AA), "rel", "Vvdash", "TRIPLE VERTICAL BAR RIGHT TURNSTILE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022AB), "rel", "VDash", "DOUBLE VERTICAL BAR DOUBLE RIGHT TURNSTILE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022AC), "rel", "nvdash", "DOES NOT PROVE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022AD), "rel", "nvDash", "NOT TRUE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022AE), "rel", "nVdash", "DOES NOT FORCE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022AF), "rel", "nVDash", "NEGATED DOUBLE VERTICAL BAR DOUBLE RIGHT TURNSTILE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x022B0), "rel", "prurel", "PRECEDES UNDER RELATION", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022B1), "rel", "scurel", "SUCCEEDS UNDER RELATION", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022B2), "rel", "vartriangleleft", "NORMAL SUBGROUP OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022B3), "rel", "vartriangleright", "CONTAINS AS NORMAL SUBGROUP", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022B4), "rel", "trianglelefteq", "NORMAL SUBGROUP OF OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022B5), "rel", "trianglerighteq", "CONTAINS AS NORMAL SUBGROUP OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022B6), "rel", "origof", "ORIGINAL OF", {
  { form = "infix", lspace = 5, priority = 220, rspace = 5 }})
addSymbol(U(0x022B7), "rel", "imageof", "IMAGE OF", {
  { form = "infix", lspace = 5, priority = 220, rspace = 5 }})
addSymbol(U(0x022B8), "rel", "multimap", "MULTIMAP", {
  { form = "infix", lspace = 5, priority = 220, rspace = 5 }})
addSymbol(U(0x022B9), "bin", "hermitmatrix", "HERMITIAN CONJUGATE MATRIX", nil)
addSymbol(U(0x022BA), "bin", "intercal", "INTERCALATE", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022BB), "bin", "veebar", "XOR", {
  { form = "infix", lspace = 4, priority = 420, rspace = 4 }})
addSymbol(U(0x022BC), "bin", "barwedge", "NAND", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x022BD), "bin", "barvee", "NOR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x022BE), "ord", "measuredrightangle", "RIGHT ANGLE WITH ARC", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x022BF), "ord", "varlrtriangle", "RIGHT TRIANGLE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x022C0), "op", "bigwedge", "N-ARY LOGICAL AND", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x022C1), "op", "bigvee", "N-ARY LOGICAL OR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x022C2), "op", "bigcap", "N-ARY INTERSECTION", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x022C3), "op", "bigcup", "N-ARY UNION", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 500, rspace = 3, symmetric = true }})
addSymbol(U(0x022C4), "bin", "smwhtdiamond", "DIAMOND OPERATOR", {
  { form = "infix", lspace = 3, priority = 900, rspace = 3 }})
addSymbol(U(0x022C5), "bin", "cdot", "DOT OPERATOR", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022C6), "bin", "star", "STAR OPERATOR", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022C7), "bin", "divideontimes", "DIVISION TIMES", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022C8), "rel", "bowtie", "BOWTIE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022C9), "bin", "ltimes", "LEFT NORMAL FACTOR SEMIDIRECT PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022CA), "bin", "rtimes", "RIGHT NORMAL FACTOR SEMIDIRECT PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022CB), "bin", "leftthreetimes", "LEFT SEMIDIRECT PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022CC), "bin", "rightthreetimes", "RIGHT SEMIDIRECT PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x022CD), "rel", "backsimeq", "REVERSED TILDE EQUALS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022CE), "bin", "curlyvee", "CURLY LOGICAL OR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x022CF), "bin", "curlywedge", "CURLY LOGICAL AND", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x022D0), "rel", "Subset", "DOUBLE SUBSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022D1), "rel", "Supset", "DOUBLE SUPERSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022D2), "bin", "Cap", "DOUBLE INTERSECTION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x022D3), "bin", "Cup", "DOUBLE UNION", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x022D4), "rel", "pitchfork", "PITCHFORK", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022D5), "rel", "equalparallel", "EQUAL AND PARALLEL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022D6), "rel", "lessdot", "LESS-THAN WITH DOT", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022D7), "rel", "gtrdot", "GREATER-THAN WITH DOT", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022D8), "rel", "lll", "VERY MUCH LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022D9), "rel", "ggg", "VERY MUCH GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022DA), "rel", "lesseqgtr", "LESS-THAN EQUAL TO OR GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022DB), "rel", "gtreqless", "GREATER-THAN EQUAL TO OR LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022DC), "rel", "eqless", "EQUAL TO OR LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022DD), "rel", "eqgtr", "EQUAL TO OR GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022DE), "rel", "curlyeqprec", "EQUAL TO OR PRECEDES", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022DF), "rel", "curlyeqsucc", "EQUAL TO OR SUCCEEDS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022E0), "rel", "npreccurlyeq", "DOES NOT PRECEDE OR EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022E1), "rel", "nsucccurlyeq", "DOES NOT SUCCEED OR EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022E2), "rel", "nsqsubseteq", "NOT SQUARE IMAGE OF OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022E3), "rel", "nsqsupseteq", "NOT SQUARE ORIGINAL OF OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022E4), "rel", "sqsubsetneq", "SQUARE IMAGE OF OR NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022E5), "rel", "sqsupsetneq", "SQUARE ORIGINAL OF OR NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022E6), "rel", "lnsim", "LESS-THAN BUT NOT EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022E7), "rel", "gnsim", "GREATER-THAN BUT NOT EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022E8), "rel", "precnsim", "PRECEDES BUT NOT EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022E9), "rel", "succnsim", "SUCCEEDS BUT NOT EQUIVALENT TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x022EA), "rel", "nvartriangleleft", "NOT NORMAL SUBGROUP OF", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022EB), "rel", "nvartriangleright", "DOES NOT CONTAIN AS NORMAL SUBGROUP", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022EC), "rel", "ntrianglelefteq", "NOT NORMAL SUBGROUP OF OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022ED), "rel", "ntrianglerighteq", "DOES NOT CONTAIN AS NORMAL SUBGROUP OR EQUAL", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022EE), "rel", "vdots", "VERTICAL ELLIPSIS", nil)
addSymbol(U(0x022EF), "rel", "unicodecdots", "MIDLINE HORIZONTAL ELLIPSIS", nil)
addSymbol(U(0x022F0), "rel", "adots", "UP RIGHT DIAGONAL ELLIPSIS", nil)
addSymbol(U(0x022F1), "rel", "ddots", "DOWN RIGHT DIAGONAL ELLIPSIS", nil)
addSymbol(U(0x022F2), "rel", "disin", "ELEMENT OF WITH LONG HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022F3), "rel", "varisins", "ELEMENT OF WITH VERTICAL BAR AT END OF HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022F4), "rel", "isins", "SMALL ELEMENT OF WITH VERTICAL BAR AT END OF HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022F5), "rel", "isindot", "ELEMENT OF WITH DOT ABOVE", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022F6), "rel", "varisinobar", "ELEMENT OF WITH OVERBAR", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022F7), "rel", "isinobar", "SMALL ELEMENT OF WITH OVERBAR", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022F8), "rel", "isinvb", "ELEMENT OF WITH UNDERBAR", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022F9), "rel", "isinE", "ELEMENT OF WITH TWO HORIZONTAL STROKES", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022FA), "rel", "nisd", "CONTAINS WITH LONG HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022FB), "rel", "varnis", "CONTAINS WITH VERTICAL BAR AT END OF HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022FC), "rel", "nis", "SMALL CONTAINS WITH VERTICAL BAR AT END OF HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022FD), "rel", "varniobar", "CONTAINS WITH OVERBAR", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022FE), "rel", "niobar", "SMALL CONTAINS WITH OVERBAR", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x022FF), "rel", "bagmember", "Z NOTATION BAG MEMBERSHIP", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02300), "ord", "diameter", "DIAMETER SIGN", nil)
addSymbol(U(0x02301), "ord", nil, "ELECTRIC ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02302), "ord", "house", "HOUSE", nil)
addSymbol(U(0x02305), "bin", "varbarwedge", "PROJECTIVE", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02306), "bin", "vardoublebarwedge", "PERSPECTIVE", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02308), "open", "lceil", "LEFT CEILING", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02309), "close", "rceil", "RIGHT CEILING", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0230A), "open", "lfloor", "LEFT FLOOR", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0230B), "close", "rfloor", "RIGHT FLOOR", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02310), "ord", "invnot", "REVERSED NOT SIGN", {
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x02311), "ord", "sqlozenge", "SQUARE LOZENGE", nil)
addSymbol(U(0x02312), "ord", "profline", "ARC", nil)
addSymbol(U(0x02313), "ord", "profsurf", "SEGMENT", nil)
addSymbol(U(0x02317), "ord", "viewdata", "VIEWDATA SQUARE", nil)
addSymbol(U(0x02319), "ord", "turnednot", "TURNED NOT SIGN", {
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x0231C), "open", "ulcorner", "TOP LEFT CORNER", nil)
addSymbol(U(0x0231D), "close", "urcorner", "TOP RIGHT CORNER", nil)
addSymbol(U(0x0231E), "open", "llcorner", "BOTTOM LEFT CORNER", nil)
addSymbol(U(0x0231F), "close", "lrcorner", "BOTTOM RIGHT CORNER", nil)
addSymbol(U(0x02320), "ord", "inttop", "TOP HALF INTEGRAL", nil)
addSymbol(U(0x02321), "ord", "intbottom", "BOTTOM HALF INTEGRAL", nil)
addSymbol(U(0x02322), "rel", "frown", "FROWN", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x02323), "rel", "smile", "SMILE", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x02329), "ord", nil, "LEFT-POINTING ANGLE BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0232A), "ord", nil, "RIGHT-POINTING ANGLE BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0232C), "ord", "varhexagonlrbonds", "BENZENE RING", nil)
addSymbol(U(0x02332), "ord", "conictaper", "CONICAL TAPER", nil)
addSymbol(U(0x02336), "ord", "topbot", "APL FUNCTIONAL SYMBOL I-BEAM", nil)
addSymbol(U(0x0233D), "bin", "obar", "APL FUNCTIONAL SYMBOL CIRCLE STILE", nil)
addSymbol(U(0x0233F), "rel", "APLnotslash", "APL FUNCTIONAL SYMBOL SLASH BAR", nil)
addSymbol(U(0x02340), "ord", "APLnotbackslash", "APL FUNCTIONAL SYMBOL BACKSLASH BAR", nil)
addSymbol(U(0x02353), "ord", "APLboxupcaret", "APL FUNCTIONAL SYMBOL QUAD UP CARET", nil)
addSymbol(U(0x02370), "ord", "APLboxquestion", "APL FUNCTIONAL SYMBOL QUAD QUESTION", nil)
addSymbol(U(0x0237C), "rel", "rangledownzigzagarrow", "RIGHT ANGLE WITH DOWNWARDS ZIGZAG ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0238B), "ord", nil, "BROKEN CIRCLE WITH NORTHWEST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02394), "ord", "hexagon", "SOFTWARE-FUNCTION SYMBOL", nil)
addSymbol(U(0x0239B), "ord", "lparenuend", "LEFT PARENTHESIS UPPER HOOK", nil)
addSymbol(U(0x0239C), "ord", "lparenextender", "LEFT PARENTHESIS EXTENSION", nil)
addSymbol(U(0x0239D), "ord", "lparenlend", "LEFT PARENTHESIS LOWER HOOK", nil)
addSymbol(U(0x0239E), "ord", "rparenuend", "RIGHT PARENTHESIS UPPER HOOK", nil)
addSymbol(U(0x0239F), "ord", "rparenextender", "RIGHT PARENTHESIS EXTENSION", nil)
addSymbol(U(0x023A0), "ord", "rparenlend", "RIGHT PARENTHESIS LOWER HOOK", nil)
addSymbol(U(0x023A1), "ord", "lbrackuend", "LEFT SQUARE BRACKET UPPER CORNER", nil)
addSymbol(U(0x023A2), "ord", "lbrackextender", "LEFT SQUARE BRACKET EXTENSION", nil)
addSymbol(U(0x023A3), "ord", "lbracklend", "LEFT SQUARE BRACKET LOWER CORNER", nil)
addSymbol(U(0x023A4), "ord", "rbrackuend", "RIGHT SQUARE BRACKET UPPER CORNER", nil)
addSymbol(U(0x023A5), "ord", "rbrackextender", "RIGHT SQUARE BRACKET EXTENSION", nil)
addSymbol(U(0x023A6), "ord", "rbracklend", "RIGHT SQUARE BRACKET LOWER CORNER", nil)
addSymbol(U(0x023A7), "ord", "lbraceuend", "LEFT CURLY BRACKET UPPER HOOK", nil)
addSymbol(U(0x023A8), "ord", "lbracemid", "LEFT CURLY BRACKET MIDDLE PIECE", nil)
addSymbol(U(0x023A9), "ord", "lbracelend", "LEFT CURLY BRACKET LOWER HOOK", nil)
addSymbol(U(0x023AA), "ord", "vbraceextender", "CURLY BRACKET EXTENSION", nil)
addSymbol(U(0x023AB), "ord", "rbraceuend", "RIGHT CURLY BRACKET UPPER HOOK", nil)
addSymbol(U(0x023AC), "ord", "rbracemid", "RIGHT CURLY BRACKET MIDDLE PIECE", nil)
addSymbol(U(0x023AD), "ord", "rbracelend", "RIGHT CURLY BRACKET LOWER HOOK", nil)
addSymbol(U(0x023AE), "ord", "intextender", "INTEGRAL EXTENSION", nil)
addSymbol(U(0x023AF), "ord", "harrowextender", "HORIZONTAL LINE EXTENSION", nil)
addSymbol(U(0x023B0), "rel", "lmoustache", "UPPER LEFT OR LOWER RIGHT CURLY BRACKET SECTION", nil)
addSymbol(U(0x023B1), "rel", "rmoustache", "UPPER RIGHT OR LOWER LEFT CURLY BRACKET SECTION", nil)
addSymbol(U(0x023B2), "ord", "sumtop", "SUMMATION TOP", nil)
addSymbol(U(0x023B3), "ord", "sumbottom", "SUMMATION BOTTOM", nil)
addSymbol(U(0x023B4), "ord", "overbracket", "TOP SQUARE BRACKET", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x023B5), "ord", "underbracket", "BOTTOM SQUARE BRACKET", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x023B6), "ord", "bbrktbrk", "BOTTOM SQUARE BRACKET OVER TOP SQUARE BRACKET", nil)
addSymbol(U(0x023B7), "ord", "sqrtbottom", "RADICAL SYMBOL BOTTOM", nil)
addSymbol(U(0x023B8), "ord", "lvboxline", "LEFT VERTICAL BOX LINE", nil)
addSymbol(U(0x023B9), "ord", "rvboxline", "RIGHT VERTICAL BOX LINE", nil)
addSymbol(U(0x023CD), "ord", nil, "SQUARE FOOT", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0 }})
addSymbol(U(0x023CE), "ord", "varcarriagereturn", "RETURN SYMBOL", nil)
addSymbol(U(0x023DC), "ord", "overparen", "TOP PARENTHESIS", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x023DD), "ord", "underparen", "BOTTOM PARENTHESIS", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x023DE), "ord", "overbrace", "TOP CURLY BRACKET", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x023DF), "ord", "underbrace", "BOTTOM CURLY BRACKET", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x023E0), "ord", "obrbrak", "TOP TORTOISE SHELL BRACKET", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x023E1), "ord", "ubrbrak", "BOTTOM TORTOISE SHELL BRACKET", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x023E2), "ord", "trapezium", "WHITE TRAPEZIUM", nil)
addSymbol(U(0x023E3), "ord", "benzenr", "BENZENE RING WITH CIRCLE", nil)
addSymbol(U(0x023E4), "ord", "strns", "STRAIGHTNESS", nil)
addSymbol(U(0x023E5), "ord", "fltns", "FLATNESS", nil)
addSymbol(U(0x023E6), "ord", "accurrent", "AC CURRENT", nil)
addSymbol(U(0x023E7), "ord", "elinters", "ELECTRICAL INTERSECTION", nil)
addSymbol(U(0x02422), "ord", "blanksymbol", "BLANK SYMBOL", nil)
addSymbol(U(0x02423), "ord", "mathvisiblespace", "OPEN BOX", nil)
addSymbol(U(0x02506), "ord", "bdtriplevdash", "BOX DRAWINGS LIGHT TRIPLE DASH VERTICAL", nil)
addSymbol(U(0x02580), "ord", "blockuphalf", "UPPER HALF BLOCK", nil)
addSymbol(U(0x02584), "ord", "blocklowhalf", "LOWER HALF BLOCK", nil)
addSymbol(U(0x02588), "ord", "blockfull", "FULL BLOCK", nil)
addSymbol(U(0x0258C), "ord", "blocklefthalf", "LEFT HALF BLOCK", nil)
addSymbol(U(0x02590), "ord", "blockrighthalf", "RIGHT HALF BLOCK", nil)
addSymbol(U(0x02591), "ord", "blockqtrshaded", "LIGHT SHADE", nil)
addSymbol(U(0x02592), "ord", "blockhalfshaded", "MEDIUM SHADE", nil)
addSymbol(U(0x02593), "ord", "blockthreeqtrshaded", "DARK SHADE", nil)
addSymbol(U(0x025A0), "ord", "mdlgblksquare", "BLACK SQUARE", nil)
addSymbol(U(0x025A1), "ord", "mdlgwhtsquare", "WHITE SQUARE", nil)
addSymbol(U(0x025A2), "ord", "squoval", "WHITE SQUARE WITH ROUNDED CORNERS", nil)
addSymbol(U(0x025A3), "ord", "blackinwhitesquare", "WHITE SQUARE CONTAINING BLACK SMALL SQUARE", nil)
addSymbol(U(0x025A4), "ord", "squarehfill", "SQUARE WITH HORIZONTAL FILL", nil)
addSymbol(U(0x025A5), "ord", "squarevfill", "SQUARE WITH VERTICAL FILL", nil)
addSymbol(U(0x025A6), "ord", "squarehvfill", "SQUARE WITH ORTHOGONAL CROSSHATCH FILL", nil)
addSymbol(U(0x025A7), "ord", "squarenwsefill", "SQUARE WITH UPPER LEFT TO LOWER RIGHT FILL", nil)
addSymbol(U(0x025A8), "ord", "squareneswfill", "SQUARE WITH UPPER RIGHT TO LOWER LEFT FILL", nil)
addSymbol(U(0x025A9), "ord", "squarecrossfill", "SQUARE WITH DIAGONAL CROSSHATCH FILL", nil)
addSymbol(U(0x025AA), "ord", "smblksquare", "BLACK SMALL SQUARE", nil)
addSymbol(U(0x025AB), "ord", "smwhtsquare", "WHITE SMALL SQUARE", nil)
addSymbol(U(0x025AC), "ord", "hrectangleblack", "BLACK RECTANGLE", nil)
addSymbol(U(0x025AD), "ord", "hrectangle", "WHITE RECTANGLE", nil)
addSymbol(U(0x025AE), "ord", "vrectangleblack", "BLACK VERTICAL RECTANGLE", nil)
addSymbol(U(0x025AF), "ord", "vrectangle", "WHITE VERTICAL RECTANGLE", nil)
addSymbol(U(0x025B0), "ord", "parallelogramblack", "BLACK PARALLELOGRAM", nil)
addSymbol(U(0x025B1), "ord", "parallelogram", "WHITE PARALLELOGRAM", nil)
addSymbol(U(0x025B2), "bin", "bigblacktriangleup", "BLACK UP-POINTING TRIANGLE", nil)
addSymbol(U(0x025B3), "bin", "bigtriangleup", "WHITE UP-POINTING TRIANGLE", nil)
addSymbol(U(0x025B4), "bin", "blacktriangle", "BLACK UP-POINTING SMALL TRIANGLE", nil)
addSymbol(U(0x025B5), "bin", "vartriangle", "WHITE UP-POINTING SMALL TRIANGLE", nil)
addSymbol(U(0x025B6), "bin", "blacktriangleright", "BLACK RIGHT-POINTING TRIANGLE", nil)
addSymbol(U(0x025B7), "bin", "triangleright", "WHITE RIGHT-POINTING TRIANGLE", nil)
addSymbol(U(0x025B8), "bin", "smallblacktriangleright", "BLACK RIGHT-POINTING SMALL TRIANGLE", nil)
addSymbol(U(0x025B9), "bin", "smalltriangleright", "WHITE RIGHT-POINTING SMALL TRIANGLE", nil)
addSymbol(U(0x025BA), "ord", "blackpointerright", "BLACK RIGHT-POINTING POINTER", nil)
addSymbol(U(0x025BB), "ord", "whitepointerright", "WHITE RIGHT-POINTING POINTER", nil)
addSymbol(U(0x025BC), "bin", "bigblacktriangledown", "BLACK DOWN-POINTING TRIANGLE", nil)
addSymbol(U(0x025BD), "bin", "bigtriangledown", "WHITE DOWN-POINTING TRIANGLE", nil)
addSymbol(U(0x025BE), "bin", "blacktriangledown", "BLACK DOWN-POINTING SMALL TRIANGLE", nil)
addSymbol(U(0x025BF), "bin", "triangledown", "WHITE DOWN-POINTING SMALL TRIANGLE", nil)
addSymbol(U(0x025C0), "bin", "blacktriangleleft", "BLACK LEFT-POINTING TRIANGLE", nil)
addSymbol(U(0x025C1), "bin", "triangleleft", "WHITE LEFT-POINTING TRIANGLE", nil)
addSymbol(U(0x025C2), "bin", "smallblacktriangleleft", "BLACK LEFT-POINTING SMALL TRIANGLE", nil)
addSymbol(U(0x025C3), "bin", "smalltriangleleft", "WHITE LEFT-POINTING SMALL TRIANGLE", nil)
addSymbol(U(0x025C4), "bin", "blackpointerleft", "BLACK LEFT-POINTING POINTER", nil)
addSymbol(U(0x025C5), "bin", "whitepointerleft", "WHITE LEFT-POINTING POINTER", nil)
addSymbol(U(0x025C6), "ord", "mdlgblkdiamond", "BLACK DIAMOND", nil)
addSymbol(U(0x025C7), "ord", "mdlgwhtdiamond", "WHITE DIAMOND", nil)
addSymbol(U(0x025C8), "ord", "blackinwhitediamond", "WHITE DIAMOND CONTAINING BLACK SMALL DIAMOND", nil)
addSymbol(U(0x025C9), "ord", "fisheye", "FISHEYE", nil)
addSymbol(U(0x025CA), "bin", "mdlgwhtlozenge", "LOZENGE", nil)
addSymbol(U(0x025CB), "bin", "mdlgwhtcircle", "WHITE CIRCLE", nil)
addSymbol(U(0x025CC), "ord", "dottedcircle", "DOTTED CIRCLE", nil)
addSymbol(U(0x025CD), "ord", "circlevertfill", "CIRCLE WITH VERTICAL FILL", nil)
addSymbol(U(0x025CE), "ord", "bullseye", "BULLSEYE", nil)
addSymbol(U(0x025CF), "ord", "mdlgblkcircle", "BLACK CIRCLE", nil)
addSymbol(U(0x025D0), "ord", "circlelefthalfblack", "CIRCLE WITH LEFT HALF BLACK", nil)
addSymbol(U(0x025D1), "ord", "circlerighthalfblack", "CIRCLE WITH RIGHT HALF BLACK", nil)
addSymbol(U(0x025D2), "ord", "circlebottomhalfblack", "CIRCLE WITH LOWER HALF BLACK", nil)
addSymbol(U(0x025D3), "ord", "circletophalfblack", "CIRCLE WITH UPPER HALF BLACK", nil)
addSymbol(U(0x025D4), "ord", "circleurquadblack", "CIRCLE WITH UPPER RIGHT QUADRANT BLACK", nil)
addSymbol(U(0x025D5), "ord", "blackcircleulquadwhite", "CIRCLE WITH ALL BUT UPPER LEFT QUADRANT BLACK", nil)
addSymbol(U(0x025D6), "ord", "blacklefthalfcircle", "LEFT HALF BLACK CIRCLE", nil)
addSymbol(U(0x025D7), "ord", "blackrighthalfcircle", "RIGHT HALF BLACK CIRCLE", nil)
addSymbol(U(0x025D8), "ord", "inversebullet", "INVERSE BULLET", nil)
addSymbol(U(0x025D9), "ord", "inversewhitecircle", "INVERSE WHITE CIRCLE", nil)
addSymbol(U(0x025DA), "ord", "invwhiteupperhalfcircle", "UPPER HALF INVERSE WHITE CIRCLE", nil)
addSymbol(U(0x025DB), "ord", "invwhitelowerhalfcircle", "LOWER HALF INVERSE WHITE CIRCLE", nil)
addSymbol(U(0x025DC), "ord", "ularc", "UPPER LEFT QUADRANT CIRCULAR ARC", nil)
addSymbol(U(0x025DD), "ord", "urarc", "UPPER RIGHT QUADRANT CIRCULAR ARC", nil)
addSymbol(U(0x025DE), "ord", "lrarc", "LOWER RIGHT QUADRANT CIRCULAR ARC", nil)
addSymbol(U(0x025DF), "ord", "llarc", "LOWER LEFT QUADRANT CIRCULAR ARC", nil)
addSymbol(U(0x025E0), "ord", "topsemicircle", "UPPER HALF CIRCLE", nil)
addSymbol(U(0x025E1), "ord", "botsemicircle", "LOWER HALF CIRCLE", nil)
addSymbol(U(0x025E2), "ord", "lrblacktriangle", "BLACK LOWER RIGHT TRIANGLE", nil)
addSymbol(U(0x025E3), "ord", "llblacktriangle", "BLACK LOWER LEFT TRIANGLE", nil)
addSymbol(U(0x025E4), "ord", "ulblacktriangle", "BLACK UPPER LEFT TRIANGLE", nil)
addSymbol(U(0x025E5), "ord", "urblacktriangle", "BLACK UPPER RIGHT TRIANGLE", nil)
addSymbol(U(0x025E6), "bin", "smwhtcircle", "WHITE BULLET", nil)
addSymbol(U(0x025E7), "ord", "squareleftblack", "SQUARE WITH LEFT HALF BLACK", nil)
addSymbol(U(0x025E8), "ord", "squarerightblack", "SQUARE WITH RIGHT HALF BLACK", nil)
addSymbol(U(0x025E9), "ord", "squareulblack", "SQUARE WITH UPPER LEFT DIAGONAL HALF BLACK", nil)
addSymbol(U(0x025EA), "ord", "squarelrblack", "SQUARE WITH LOWER RIGHT DIAGONAL HALF BLACK", nil)
addSymbol(U(0x025EB), "bin", "boxbar", "WHITE SQUARE WITH VERTICAL BISECTING LINE", nil)
addSymbol(U(0x025EC), "bin", "trianglecdot", "WHITE UP-POINTING TRIANGLE WITH DOT", nil)
addSymbol(U(0x025ED), "ord", "triangleleftblack", "UP-POINTING TRIANGLE WITH LEFT HALF BLACK", nil)
addSymbol(U(0x025EE), "ord", "trianglerightblack", "UP-POINTING TRIANGLE WITH RIGHT HALF BLACK", nil)
addSymbol(U(0x025EF), "ord", "lgwhtcircle", "LARGE CIRCLE", nil)
addSymbol(U(0x025F0), "ord", "squareulquad", "WHITE SQUARE WITH UPPER LEFT QUADRANT", nil)
addSymbol(U(0x025F1), "ord", "squarellquad", "WHITE SQUARE WITH LOWER LEFT QUADRANT", nil)
addSymbol(U(0x025F2), "ord", "squarelrquad", "WHITE SQUARE WITH LOWER RIGHT QUADRANT", nil)
addSymbol(U(0x025F3), "ord", "squareurquad", "WHITE SQUARE WITH UPPER RIGHT QUADRANT", nil)
addSymbol(U(0x025F4), "ord", "circleulquad", "WHITE CIRCLE WITH UPPER LEFT QUADRANT", nil)
addSymbol(U(0x025F5), "ord", "circlellquad", "WHITE CIRCLE WITH LOWER LEFT QUADRANT", nil)
addSymbol(U(0x025F6), "ord", "circlelrquad", "WHITE CIRCLE WITH LOWER RIGHT QUADRANT", nil)
addSymbol(U(0x025F7), "ord", "circleurquad", "WHITE CIRCLE WITH UPPER RIGHT QUADRANT", nil)
addSymbol(U(0x025F8), "bin", "ultriangle", "UPPER LEFT TRIANGLE", nil)
addSymbol(U(0x025F9), "bin", "urtriangle", "UPPER RIGHT TRIANGLE", nil)
addSymbol(U(0x025FA), "bin", "lltriangle", "LOWER LEFT TRIANGLE", nil)
addSymbol(U(0x025FB), "bin", "mdwhtsquare", "WHITE MEDIUM SQUARE", nil)
addSymbol(U(0x025FC), "bin", "mdblksquare", "BLACK MEDIUM SQUARE", nil)
addSymbol(U(0x025FD), "bin", "mdsmwhtsquare", "WHITE MEDIUM SMALL SQUARE", nil)
addSymbol(U(0x025FE), "bin", "mdsmblksquare", "BLACK MEDIUM SMALL SQUARE", nil)
addSymbol(U(0x025FF), "bin", "lrtriangle", "LOWER RIGHT TRIANGLE", nil)
addSymbol(U(0x02605), "bin", "bigstar", "BLACK STAR", nil)
addSymbol(U(0x02606), "bin", "bigwhitestar", "WHITE STAR", nil)
addSymbol(U(0x02609), "ord", "astrosun", "SUN", nil)
addSymbol(U(0x02621), "ord", "danger", "CAUTION SIGN", nil)
addSymbol(U(0x0263B), "ord", "blacksmiley", "BLACK SMILING FACE", nil)
addSymbol(U(0x0263C), "ord", "sun", "WHITE SUN WITH RAYS", nil)
addSymbol(U(0x0263D), "ord", "rightmoon", "FIRST QUARTER MOON", nil)
addSymbol(U(0x0263E), "ord", "leftmoon", "LAST QUARTER MOON", nil)
addSymbol(U(0x02640), "ord", "female", "FEMALE SIGN", nil)
addSymbol(U(0x02642), "ord", "male", "MALE SIGN", nil)
addSymbol(U(0x02660), "ord", "spadesuit", "BLACK SPADE SUIT", nil)
addSymbol(U(0x02661), "ord", "heartsuit", "WHITE HEART SUIT", nil)
addSymbol(U(0x02662), "ord", "diamondsuit", "WHITE DIAMOND SUIT", nil)
addSymbol(U(0x02663), "ord", "clubsuit", "BLACK CLUB SUIT", nil)
addSymbol(U(0x02664), "ord", "varspadesuit", "WHITE SPADE SUIT", nil)
addSymbol(U(0x02665), "ord", "varheartsuit", "BLACK HEART SUIT", nil)
addSymbol(U(0x02666), "ord", "vardiamondsuit", "BLACK DIAMOND SUIT", nil)
addSymbol(U(0x02667), "ord", "varclubsuit", "WHITE CLUB SUIT", nil)
addSymbol(U(0x02669), "ord", "quarternote", "QUARTER NOTE", nil)
addSymbol(U(0x0266A), "ord", "eighthnote", "EIGHTH NOTE", nil)
addSymbol(U(0x0266B), "ord", "twonotes", "BEAMED EIGHTH NOTES", nil)
addSymbol(U(0x0266D), "ord", "flat", "MUSIC FLAT SIGN", nil)
addSymbol(U(0x0266E), "ord", "natural", "MUSIC NATURAL SIGN", nil)
addSymbol(U(0x0266F), "ord", "sharp", "MUSIC SHARP SIGN", nil)
addSymbol(U(0x0267E), "ord", "acidfree", "PERMANENT PAPER SIGN", nil)
addSymbol(U(0x02680), "ord", "dicei", "DIE FACE-1", nil)
addSymbol(U(0x02681), "ord", "diceii", "DIE FACE-2", nil)
addSymbol(U(0x02682), "ord", "diceiii", "DIE FACE-3", nil)
addSymbol(U(0x02683), "ord", "diceiv", "DIE FACE-4", nil)
addSymbol(U(0x02684), "ord", "dicev", "DIE FACE-5", nil)
addSymbol(U(0x02685), "ord", "dicevi", "DIE FACE-6", nil)
addSymbol(U(0x02686), "ord", "circledrightdot", "WHITE CIRCLE WITH DOT RIGHT", nil)
addSymbol(U(0x02687), "ord", "circledtwodots", "WHITE CIRCLE WITH TWO DOTS", nil)
addSymbol(U(0x02688), "ord", "blackcircledrightdot", "BLACK CIRCLE WITH WHITE DOT RIGHT", nil)
addSymbol(U(0x02689), "ord", "blackcircledtwodots", "BLACK CIRCLE WITH TWO WHITE DOTS", nil)
addSymbol(U(0x026A5), "ord", "Hermaphrodite", "MALE AND FEMALE SIGN", nil)
addSymbol(U(0x026AA), "ord", "mdwhtcircle", "MEDIUM WHITE CIRCLE", nil)
addSymbol(U(0x026AB), "ord", "mdblkcircle", "MEDIUM BLACK CIRCLE", nil)
addSymbol(U(0x026AC), "ord", "mdsmwhtcircle", "MEDIUM SMALL WHITE CIRCLE", nil)
addSymbol(U(0x026B2), "ord", "neuter", "NEUTER", nil)
addSymbol(U(0x02713), "ord", "checkmark", "CHECK MARK", nil)
addSymbol(U(0x02720), "ord", "maltese", "MALTESE CROSS", nil)
addSymbol(U(0x0272A), "ord", "circledstar", "CIRCLED WHITE STAR", nil)
addSymbol(U(0x02736), "ord", "varstar", "SIX POINTED BLACK STAR", nil)
addSymbol(U(0x0273D), "ord", "dingasterisk", "HEAVY TEARDROP-SPOKED ASTERISK", nil)
addSymbol(U(0x02772), "open", "lbrbrak", "LIGHT LEFT TORTOISE SHELL BRACKET ORNAMENT", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02773), "close", "rbrbrak", "LIGHT RIGHT TORTOISE SHELL BRACKET ORNAMENT", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02794), "ord", nil, "HEAVY WIDE-HEADED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02795), "ord", nil, "HEAVY PLUS SIGN", {
  { form = "prefix", lspace = 0, priority = 720, rspace = 0 },
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02796), "ord", nil, "HEAVY MINUS SIGN", {
  { form = "prefix", lspace = 0, priority = 720, rspace = 0 },
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02797), "ord", nil, "HEAVY DIVISION SIGN", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x02798), "ord", nil, "HEAVY SOUTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02799), "ord", nil, "HEAVY RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0279A), "ord", nil, "HEAVY NORTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0279B), "ord", "draftingarrow", "DRAFTING POINT RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0279C), "ord", nil, "HEAVY ROUND-TIPPED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0279D), "ord", nil, "TRIANGLE-HEADED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0279E), "ord", nil, "HEAVY TRIANGLE-HEADED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0279F), "ord", nil, "DASHED TRIANGLE-HEADED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027A0), "ord", nil, "HEAVY DASHED TRIANGLE-HEADED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027A1), "ord", nil, "BLACK RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027A5), "ord", nil, "HEAVY BLACK CURVED DOWNWARDS AND RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027A6), "ord", nil, "HEAVY BLACK CURVED UPWARDS AND RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027A7), "ord", nil, "SQUAT BLACK RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x027A8), "ord", nil, "HEAVY CONCAVE-POINTED BLACK RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027A9), "ord", nil, "RIGHT-SHADED WHITE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027AA), "ord", nil, "LEFT-SHADED WHITE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027AB), "ord", nil, "BACK-TILTED SHADOWED WHITE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027AC), "ord", nil, "FRONT-TILTED SHADOWED WHITE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027AD), "ord", nil, "HEAVY LOWER RIGHT-SHADOWED WHITE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027AE), "ord", nil, "HEAVY UPPER RIGHT-SHADOWED WHITE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027AF), "ord", nil, "NOTCHED LOWER RIGHT-SHADOWED WHITE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027B1), "ord", nil, "NOTCHED UPPER RIGHT-SHADOWED WHITE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027B2), "ord", nil, "CIRCLED HEAVY WHITE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x027B3), "ord", nil, "WHITE-FEATHERED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027B4), "ord", nil, "BLACK-FEATHERED SOUTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x027B5), "ord", nil, "BLACK-FEATHERED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027B6), "ord", nil, "BLACK-FEATHERED NORTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x027B7), "ord", nil, "HEAVY BLACK-FEATHERED SOUTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x027B8), "ord", nil, "HEAVY BLACK-FEATHERED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027B9), "ord", nil, "HEAVY BLACK-FEATHERED NORTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x027BA), "ord", nil, "TEARDROP-BARBED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027BB), "ord", nil, "HEAVY TEARDROP-SHANKED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027BC), "ord", nil, "WEDGE-TAILED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027BD), "ord", nil, "HEAVY WEDGE-TAILED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027BE), "ord", nil, "OPEN-OUTLINED RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027C0), "ord", "threedangle", "THREE DIMENSIONAL ANGLE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x027C1), "ord", "whiteinwhitetriangle", "WHITE TRIANGLE CONTAINING SMALL WHITE TRIANGLE", nil)
addSymbol(U(0x027C2), "rel", "perp", "PERPENDICULAR", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x027C3), "rel", "subsetcirc", "OPEN SUBSET", nil)
addSymbol(U(0x027C4), "rel", "supsetcirc", "OPEN SUPERSET", nil)
addSymbol(U(0x027C5), "rel", "lbag", "LEFT S-SHAPED BAG DELIMITER", nil)
addSymbol(U(0x027C6), "rel", "rbag", "RIGHT S-SHAPED BAG DELIMITER", nil)
addSymbol(U(0x027C7), "rel", "veedot", "OR WITH DOT INSIDE", nil)
addSymbol(U(0x027C8), "rel", "bsolhsub", "REVERSE SOLIDUS PRECEDING SUBSET", nil)
addSymbol(U(0x027C9), "rel", "suphsol", "SUPERSET PRECEDING SOLIDUS", nil)
addSymbol(U(0x027CA), "rel", nil, "VERTICAL BAR WITH HORIZONTAL STROKE", nil)
addSymbol(U(0x027CB), "rel", "diagup", "MATHEMATICAL RISING DIAGONAL", {
  { form = "infix", lspace = 3, priority = 680, rspace = 3 }})
addSymbol(U(0x027CC), "op", "longdivision", "LONG DIVISION", nil)
addSymbol(U(0x027CD), "rel", "diagdown", "MATHEMATICAL FALLING DIAGONAL", {
  { form = "infix", lspace = 3, priority = 680, rspace = 3 }})
addSymbol(U(0x027CE), "bin", nil, "SQUARED LOGICAL AND", nil)
addSymbol(U(0x027CF), "bin", nil, "SQUARED LOGICAL OR", nil)
addSymbol(U(0x027D0), "ord", "diamondcdot", "WHITE DIAMOND WITH CENTRED DOT", nil)
addSymbol(U(0x027D1), "bin", "wedgedot", "AND WITH DOT", nil)
addSymbol(U(0x027D2), "rel", "upin", "ELEMENT OF OPENING UPWARDS", nil)
addSymbol(U(0x027D3), "rel", "pullback", "LOWER RIGHT CORNER WITH DOT", nil)
addSymbol(U(0x027D4), "rel", "pushout", "UPPER LEFT CORNER WITH DOT", nil)
addSymbol(U(0x027D5), "op", "leftouterjoin", "LEFT OUTER JOIN", nil)
addSymbol(U(0x027D6), "op", "rightouterjoin", "RIGHT OUTER JOIN", nil)
addSymbol(U(0x027D7), "op", "fullouterjoin", "FULL OUTER JOIN", nil)
addSymbol(U(0x027D8), "op", "bigbot", "LARGE UP TACK", nil)
addSymbol(U(0x027D9), "op", "bigtop", "LARGE DOWN TACK", nil)
addSymbol(U(0x027DA), "rel", "DashVDash", "LEFT AND RIGHT DOUBLE TURNSTILE", nil)
addSymbol(U(0x027DB), "rel", "dashVdash", "LEFT AND RIGHT TACK", nil)
addSymbol(U(0x027DC), "rel", "multimapinv", "LEFT MULTIMAP", nil)
addSymbol(U(0x027DD), "rel", "vlongdash", "LONG RIGHT TACK", nil)
addSymbol(U(0x027DE), "rel", "longdashv", "LONG LEFT TACK", nil)
addSymbol(U(0x027DF), "rel", "cirbot", "UP TACK WITH CIRCLE ABOVE", nil)
addSymbol(U(0x027E0), "bin", "lozengeminus", "LOZENGE DIVIDED BY HORIZONTAL RULE", nil)
addSymbol(U(0x027E1), "bin", "concavediamond", "WHITE CONCAVE-SIDED DIAMOND", nil)
addSymbol(U(0x027E2), "bin", "concavediamondtickleft", "WHITE CONCAVE-SIDED DIAMOND WITH LEFTWARDS TICK", nil)
addSymbol(U(0x027E3), "bin", "concavediamondtickright", "WHITE CONCAVE-SIDED DIAMOND WITH RIGHTWARDS TICK", nil)
addSymbol(U(0x027E4), "bin", "whitesquaretickleft", "WHITE SQUARE WITH LEFTWARDS TICK", nil)
addSymbol(U(0x027E5), "bin", "whitesquaretickright", "WHITE SQUARE WITH RIGHTWARDS TICK", nil)
addSymbol(U(0x027E6), "open", "lBrack", "MATHEMATICAL LEFT WHITE SQUARE BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027E7), "close", "rBrack", "MATHEMATICAL RIGHT WHITE SQUARE BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027E8), "open", "langle", "MATHEMATICAL LEFT ANGLE BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027E9), "close", "rangle", "MATHEMATICAL RIGHT ANGLE BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027EA), "open", "lAngle", "MATHEMATICAL LEFT DOUBLE ANGLE BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027EB), "close", "rAngle", "MATHEMATICAL RIGHT DOUBLE ANGLE BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027EC), "open", "Lbrbrak", "MATHEMATICAL LEFT WHITE TORTOISE SHELL BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027ED), "close", "Rbrbrak", "MATHEMATICAL RIGHT WHITE TORTOISE SHELL BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027EE), "open", "lgroup", "MATHEMATICAL LEFT FLATTENED PARENTHESIS", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027EF), "close", "rgroup", "MATHEMATICAL RIGHT FLATTENED PARENTHESIS", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x027F0), "rel", "UUparrow", "UPWARDS QUADRUPLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027F1), "rel", "DDownarrow", "DOWNWARDS QUADRUPLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027F2), "rel", "acwgapcirclearrow", "ANTICLOCKWISE GAPPED CIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x027F3), "rel", "cwgapcirclearrow", "CLOCKWISE GAPPED CIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x027F4), "rel", "rightarrowonoplus", "RIGHT ARROW WITH CIRCLED PLUS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027F5), "rel", "longleftarrow", "LONG LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027F6), "rel", "longrightarrow", "LONG RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027F7), "rel", "longleftrightarrow", "LONG LEFT RIGHT ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027F8), "rel", "Longleftarrow", "LONG LEFTWARDS DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027F9), "rel", "Longrightarrow", "LONG RIGHTWARDS DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027FA), "rel", "Longleftrightarrow", "LONG LEFT RIGHT DOUBLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027FB), "rel", "longmapsfrom", "LONG LEFTWARDS ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027FC), "rel", "longmapsto", "LONG RIGHTWARDS ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027FD), "rel", "Longmapsfrom", "LONG LEFTWARDS DOUBLE ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027FE), "rel", "Longmapsto", "LONG RIGHTWARDS DOUBLE ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x027FF), "rel", "longrightsquigarrow", "LONG RIGHTWARDS SQUIGGLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02900), "rel", "nvtwoheadrightarrow", "RIGHTWARDS TWO-HEADED ARROW WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02901), "rel", "nVtwoheadrightarrow", "RIGHTWARDS TWO-HEADED ARROW WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02902), "rel", "nvLeftarrow", "LEFTWARDS DOUBLE ARROW WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02903), "rel", "nvRightarrow", "RIGHTWARDS DOUBLE ARROW WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02904), "rel", "nvLeftrightarrow", "LEFT RIGHT DOUBLE ARROW WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02905), "rel", "twoheadmapsto", "RIGHTWARDS TWO-HEADED ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02906), "rel", "Mapsfrom", "LEFTWARDS DOUBLE ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02907), "rel", "Mapsto", "RIGHTWARDS DOUBLE ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02908), "rel", "downarrowbarred", "DOWNWARDS ARROW WITH HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02909), "rel", "uparrowbarred", "UPWARDS ARROW WITH HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0290A), "rel", "Uuparrow", "UPWARDS TRIPLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0290B), "rel", "Ddownarrow", "DOWNWARDS TRIPLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0290C), "rel", "leftbkarrow", "LEFTWARDS DOUBLE DASH ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0290D), "rel", "rightbkarrow", "RIGHTWARDS DOUBLE DASH ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0290E), "rel", "leftdbkarrow", "LEFTWARDS TRIPLE DASH ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0290F), "rel", "dbkarrow", "RIGHTWARDS TRIPLE DASH ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02910), "rel", "drbkarrow", "RIGHTWARDS TWO-HEADED TRIPLE DASH ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02911), "rel", "rightdotarrow", "RIGHTWARDS ARROW WITH DOTTED STEM", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02912), "rel", "baruparrow", "UPWARDS ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02913), "rel", "downarrowbar", "DOWNWARDS ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02914), "rel", "nvrightarrowtail", "RIGHTWARDS ARROW WITH TAIL WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02915), "rel", "nVrightarrowtail", "RIGHTWARDS ARROW WITH TAIL WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02916), "rel", "twoheadrightarrowtail", "RIGHTWARDS TWO-HEADED ARROW WITH TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02917), "rel", "nvtwoheadrightarrowtail", "RIGHTWARDS TWO-HEADED ARROW WITH TAIL WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02918), "rel", "nVtwoheadrightarrowtail", "RIGHTWARDS TWO-HEADED ARROW WITH TAIL WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02919), "rel", "lefttail", "LEFTWARDS ARROW-TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0291A), "rel", "righttail", "RIGHTWARDS ARROW-TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0291B), "rel", "leftdbltail", "LEFTWARDS DOUBLE ARROW-TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0291C), "rel", "rightdbltail", "RIGHTWARDS DOUBLE ARROW-TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0291D), "rel", "diamondleftarrow", "LEFTWARDS ARROW TO BLACK DIAMOND", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0291E), "rel", "rightarrowdiamond", "RIGHTWARDS ARROW TO BLACK DIAMOND", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0291F), "rel", "diamondleftarrowbar", "LEFTWARDS ARROW FROM BAR TO BLACK DIAMOND", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02920), "rel", "barrightarrowdiamond", "RIGHTWARDS ARROW FROM BAR TO BLACK DIAMOND", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02921), "rel", "nwsearrow", "NORTH WEST AND SOUTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02922), "rel", "neswarrow", "NORTH EAST AND SOUTH WEST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02923), "rel", "hknwarrow", "NORTH WEST ARROW WITH HOOK", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02924), "rel", "hknearrow", "NORTH EAST ARROW WITH HOOK", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02925), "rel", "hksearrow", "SOUTH EAST ARROW WITH HOOK", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02926), "rel", "hkswarrow", "SOUTH WEST ARROW WITH HOOK", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02927), "rel", "tona", "NORTH WEST ARROW AND NORTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02928), "rel", "toea", "NORTH EAST ARROW AND SOUTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02929), "rel", "tosa", "SOUTH EAST ARROW AND SOUTH WEST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0292A), "rel", "towa", "SOUTH WEST ARROW AND NORTH WEST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0292B), "rel", "rdiagovfdiag", "RISING DIAGONAL CROSSING FALLING DIAGONAL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0292C), "rel", "fdiagovrdiag", "FALLING DIAGONAL CROSSING RISING DIAGONAL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0292D), "rel", "seovnearrow", "SOUTH EAST ARROW CROSSING NORTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0292E), "rel", "neovsearrow", "NORTH EAST ARROW CROSSING SOUTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0292F), "rel", "fdiagovnearrow", "FALLING DIAGONAL CROSSING NORTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02930), "rel", "rdiagovsearrow", "RISING DIAGONAL CROSSING SOUTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02931), "rel", "neovnwarrow", "NORTH EAST ARROW CROSSING NORTH WEST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02932), "rel", "nwovnearrow", "NORTH WEST ARROW CROSSING NORTH EAST ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02933), "rel", "rightcurvedarrow", "WAVE ARROW POINTING DIRECTLY RIGHT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02934), "rel", "uprightcurvearrow", "ARROW POINTING RIGHTWARDS THEN CURVING UPWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02935), "rel", "downrightcurvedarrow", "ARROW POINTING RIGHTWARDS THEN CURVING DOWNWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02936), "rel", "leftdowncurvedarrow", "ARROW POINTING DOWNWARDS THEN CURVING LEFTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02937), "rel", "rightdowncurvedarrow", "ARROW POINTING DOWNWARDS THEN CURVING RIGHTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02938), "rel", "cwrightarcarrow", "RIGHT-SIDE ARC CLOCKWISE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02939), "rel", "acwleftarcarrow", "LEFT-SIDE ARC ANTICLOCKWISE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0293A), "rel", "acwoverarcarrow", "TOP ARC ANTICLOCKWISE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0293B), "rel", "acwunderarcarrow", "BOTTOM ARC ANTICLOCKWISE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0293C), "rel", "curvearrowrightminus", "TOP ARC CLOCKWISE ARROW WITH MINUS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0293D), "rel", "curvearrowleftplus", "TOP ARC ANTICLOCKWISE ARROW WITH PLUS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0293E), "rel", "cwundercurvearrow", "LOWER RIGHT SEMICIRCULAR CLOCKWISE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x0293F), "rel", "ccwundercurvearrow", "LOWER LEFT SEMICIRCULAR ANTICLOCKWISE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02940), "rel", "acwcirclearrow", "ANTICLOCKWISE CLOSED CIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02941), "rel", "cwcirclearrow", "CLOCKWISE CLOSED CIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02942), "rel", "rightarrowshortleftarrow", "RIGHTWARDS ARROW ABOVE SHORT LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02943), "rel", "leftarrowshortrightarrow", "LEFTWARDS ARROW ABOVE SHORT RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02944), "rel", "shortrightarrowleftarrow", "SHORT RIGHTWARDS ARROW ABOVE LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02945), "rel", "rightarrowplus", "RIGHTWARDS ARROW WITH PLUS BELOW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02946), "rel", "leftarrowplus", "LEFTWARDS ARROW WITH PLUS BELOW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02947), "rel", "rightarrowx", "RIGHTWARDS ARROW THROUGH X", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02948), "rel", "leftrightarrowcircle", "LEFT RIGHT ARROW THROUGH SMALL CIRCLE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02949), "rel", "twoheaduparrowcircle", "UPWARDS TWO-HEADED ARROW FROM SMALL CIRCLE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0294A), "rel", "leftrightharpoonupdown", "LEFT BARB UP RIGHT BARB DOWN HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0294B), "rel", "leftrightharpoondownup", "LEFT BARB DOWN RIGHT BARB UP HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0294C), "rel", "updownharpoonrightleft", "UP BARB RIGHT DOWN BARB LEFT HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0294D), "rel", "updownharpoonleftright", "UP BARB LEFT DOWN BARB RIGHT HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0294E), "rel", "leftrightharpoonupup", "LEFT BARB UP RIGHT BARB UP HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0294F), "rel", "updownharpoonrightright", "UP BARB RIGHT DOWN BARB RIGHT HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02950), "rel", "leftrightharpoondowndown", "LEFT BARB DOWN RIGHT BARB DOWN HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02951), "rel", "updownharpoonleftleft", "UP BARB LEFT DOWN BARB LEFT HARPOON", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02952), "rel", "barleftharpoonup", "LEFTWARDS HARPOON WITH BARB UP TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02953), "rel", "rightharpoonupbar", "RIGHTWARDS HARPOON WITH BARB UP TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02954), "rel", "barupharpoonright", "UPWARDS HARPOON WITH BARB RIGHT TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02955), "rel", "downharpoonrightbar", "DOWNWARDS HARPOON WITH BARB RIGHT TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02956), "rel", "barleftharpoondown", "LEFTWARDS HARPOON WITH BARB DOWN TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02957), "rel", "rightharpoondownbar", "RIGHTWARDS HARPOON WITH BARB DOWN TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02958), "rel", "barupharpoonleft", "UPWARDS HARPOON WITH BARB LEFT TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02959), "rel", "downharpoonleftbar", "DOWNWARDS HARPOON WITH BARB LEFT TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0295A), "rel", "leftharpoonupbar", "LEFTWARDS HARPOON WITH BARB UP FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0295B), "rel", "barrightharpoonup", "RIGHTWARDS HARPOON WITH BARB UP FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0295C), "rel", "upharpoonrightbar", "UPWARDS HARPOON WITH BARB RIGHT FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0295D), "rel", "bardownharpoonright", "DOWNWARDS HARPOON WITH BARB RIGHT FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0295E), "rel", "leftharpoondownbar", "LEFTWARDS HARPOON WITH BARB DOWN FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0295F), "rel", "barrightharpoondown", "RIGHTWARDS HARPOON WITH BARB DOWN FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02960), "rel", "upharpoonleftbar", "UPWARDS HARPOON WITH BARB LEFT FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02961), "rel", "bardownharpoonleft", "DOWNWARDS HARPOON WITH BARB LEFT FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02962), "rel", "leftharpoonsupdown", "LEFTWARDS HARPOON WITH BARB UP ABOVE LEFTWARDS HARPOON WITH BARB DOWN", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02963), "rel", "upharpoonsleftright", "UPWARDS HARPOON WITH BARB LEFT BESIDE UPWARDS HARPOON WITH BARB RIGHT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02964), "rel", "rightharpoonsupdown", "RIGHTWARDS HARPOON WITH BARB UP ABOVE RIGHTWARDS HARPOON WITH BARB DOWN", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02965), "rel", "downharpoonsleftright", "DOWNWARDS HARPOON WITH BARB LEFT BESIDE DOWNWARDS HARPOON WITH BARB RIGHT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02966), "rel", "leftrightharpoonsup", "LEFTWARDS HARPOON WITH BARB UP ABOVE RIGHTWARDS HARPOON WITH BARB UP", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02967), "rel", "leftrightharpoonsdown", "LEFTWARDS HARPOON WITH BARB DOWN ABOVE RIGHTWARDS HARPOON WITH BARB DOWN", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02968), "rel", "rightleftharpoonsup", "RIGHTWARDS HARPOON WITH BARB UP ABOVE LEFTWARDS HARPOON WITH BARB UP", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02969), "rel", "rightleftharpoonsdown", "RIGHTWARDS HARPOON WITH BARB DOWN ABOVE LEFTWARDS HARPOON WITH BARB DOWN", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0296A), "rel", "leftharpoonupdash", "LEFTWARDS HARPOON WITH BARB UP ABOVE LONG DASH", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0296B), "rel", "dashleftharpoondown", "LEFTWARDS HARPOON WITH BARB DOWN BELOW LONG DASH", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0296C), "rel", "rightharpoonupdash", "RIGHTWARDS HARPOON WITH BARB UP ABOVE LONG DASH", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0296D), "rel", "dashrightharpoondown", "RIGHTWARDS HARPOON WITH BARB DOWN BELOW LONG DASH", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0296E), "rel", "updownharpoonsleftright", "UPWARDS HARPOON WITH BARB LEFT BESIDE DOWNWARDS HARPOON WITH BARB RIGHT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0296F), "rel", "downupharpoonsleftright", "DOWNWARDS HARPOON WITH BARB LEFT BESIDE UPWARDS HARPOON WITH BARB RIGHT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02970), "rel", "rightimply", "RIGHT DOUBLE ARROW WITH ROUNDED HEAD", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02971), "rel", "equalrightarrow", "EQUALS SIGN ABOVE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02972), "rel", "similarrightarrow", "TILDE OPERATOR ABOVE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02973), "rel", "leftarrowsimilar", "LEFTWARDS ARROW ABOVE TILDE OPERATOR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02974), "rel", "rightarrowsimilar", "RIGHTWARDS ARROW ABOVE TILDE OPERATOR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02975), "rel", "rightarrowapprox", "RIGHTWARDS ARROW ABOVE ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02976), "rel", "ltlarr", "LESS-THAN ABOVE LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02977), "rel", "leftarrowless", "LEFTWARDS ARROW THROUGH LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02978), "rel", "gtrarr", "GREATER-THAN ABOVE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02979), "rel", "subrarr", "SUBSET ABOVE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0297A), "rel", "leftarrowsubset", "LEFTWARDS ARROW THROUGH SUBSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0297B), "rel", "suplarr", "SUPERSET ABOVE LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x0297C), "rel", "leftfishtail", "LEFT FISH TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0297D), "rel", "rightfishtail", "RIGHT FISH TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0297E), "rel", "upfishtail", "UP FISH TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x0297F), "rel", "downfishtail", "DOWN FISH TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02980), "ord", "Vvert", "TRIPLE VERTICAL BAR DELIMITER", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true },
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02981), "ord", "mdsmblkcircle", "Z NOTATION SPOT", {
  { form = "infix", lspace = 5, priority = 140, rspace = 5 }})
addSymbol(U(0x02982), "ord", "typecolon", "Z NOTATION TYPE COLON", {
  { form = "infix", lspace = 5, priority = 180, rspace = 5 }})
addSymbol(U(0x02983), "open", "lBrace", "LEFT WHITE CURLY BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02984), "close", "rBrace", "RIGHT WHITE CURLY BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02985), "open", "lParen", "LEFT WHITE PARENTHESIS", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02986), "close", "rParen", "RIGHT WHITE PARENTHESIS", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02987), "open", "llparenthesis", "Z NOTATION LEFT IMAGE BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02988), "close", "rrparenthesis", "Z NOTATION RIGHT IMAGE BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02989), "open", "llangle", "Z NOTATION LEFT BINDING BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0298A), "close", "rrangle", "Z NOTATION RIGHT BINDING BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0298B), "open", "lbrackubar", "LEFT SQUARE BRACKET WITH UNDERBAR", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0298C), "close", "rbrackubar", "RIGHT SQUARE BRACKET WITH UNDERBAR", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0298D), "open", "lbrackultick", "LEFT SQUARE BRACKET WITH TICK IN TOP CORNER", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0298E), "close", "rbracklrtick", "RIGHT SQUARE BRACKET WITH TICK IN BOTTOM CORNER", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0298F), "open", "lbracklltick", "LEFT SQUARE BRACKET WITH TICK IN BOTTOM CORNER", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02990), "close", "rbrackurtick", "RIGHT SQUARE BRACKET WITH TICK IN TOP CORNER", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02991), "open", "langledot", "LEFT ANGLE BRACKET WITH DOT", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02992), "close", "rangledot", "RIGHT ANGLE BRACKET WITH DOT", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02993), "open", "lparenless", "LEFT ARC LESS-THAN BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02994), "close", "rparengtr", "RIGHT ARC GREATER-THAN BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02995), "open", "Lparengtr", "DOUBLE LEFT ARC GREATER-THAN BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02996), "close", "Rparenless", "DOUBLE RIGHT ARC LESS-THAN BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02997), "open", "lblkbrbrak", "LEFT BLACK TORTOISE SHELL BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02998), "close", "rblkbrbrak", "RIGHT BLACK TORTOISE SHELL BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x02999), "ord", "fourvdots", "DOTTED FENCE", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true },
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x0299A), "ord", "vzigzag", "VERTICAL ZIGZAG LINE", nil)
addSymbol(U(0x0299B), "ord", "measuredangleleft", "MEASURED ANGLE OPENING LEFT", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x0299C), "ord", "rightanglesqr", "RIGHT ANGLE VARIANT WITH SQUARE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x0299D), "ord", "rightanglemdot", "MEASURED RIGHT ANGLE WITH DOT", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x0299E), "ord", "angles", "ANGLE WITH S INSIDE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x0299F), "ord", "angdnr", "ACUTE ANGLE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A0), "ord", "gtlpar", "SPHERICAL ANGLE OPENING LEFT", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A1), "ord", "sphericalangleup", "SPHERICAL ANGLE OPENING UP", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A2), "ord", "turnangle", "TURNED ANGLE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A3), "ord", "revangle", "REVERSED ANGLE", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A4), "ord", "angleubar", "ANGLE WITH UNDERBAR", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A5), "ord", "revangleubar", "REVERSED ANGLE WITH UNDERBAR", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A6), "ord", "wideangledown", "OBLIQUE ANGLE OPENING UP", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A7), "ord", "wideangleup", "OBLIQUE ANGLE OPENING DOWN", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A8), "ord", "measanglerutone", "MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING UP AND RIGHT", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029A9), "ord", "measanglelutonw", "MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING UP AND LEFT", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029AA), "ord", "measanglerdtose", "MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING DOWN AND RIGHT", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029AB), "ord", "measangleldtosw", "MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING DOWN AND LEFT", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029AC), "ord", "measangleurtone", "MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING RIGHT AND UP", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029AD), "ord", "measangleultonw", "MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING LEFT AND UP", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029AE), "ord", "measangledrtose", "MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING RIGHT AND DOWN", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029AF), "ord", "measangledltosw", "MEASURED ANGLE WITH OPEN ARM ENDING IN ARROW POINTING LEFT AND DOWN", {
  { form = "prefix", lspace = 0, priority = 580, rspace = 0 }})
addSymbol(U(0x029B0), "ord", "revemptyset", "REVERSED EMPTY SET", nil)
addSymbol(U(0x029B1), "ord", "emptysetobar", "EMPTY SET WITH OVERBAR", nil)
addSymbol(U(0x029B2), "ord", "emptysetocirc", "EMPTY SET WITH SMALL CIRCLE ABOVE", nil)
addSymbol(U(0x029B3), "ord", "emptysetoarr", "EMPTY SET WITH RIGHT ARROW ABOVE", nil)
addSymbol(U(0x029B4), "ord", "emptysetoarrl", "EMPTY SET WITH LEFT ARROW ABOVE", nil)
addSymbol(U(0x029B5), "ord", "circlehbar", "CIRCLE WITH HORIZONTAL BAR", nil)
addSymbol(U(0x029B6), "bin", "circledvert", "CIRCLED VERTICAL BAR", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029B7), "bin", "circledparallel", "CIRCLED PARALLEL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029B8), "bin", "obslash", "CIRCLED REVERSE SOLIDUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x029B9), "bin", "operp", "CIRCLED PERPENDICULAR", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029BA), "ord", "obot", "CIRCLE DIVIDED BY HORIZONTAL BAR AND TOP HALF DIVIDED BY VERTICAL BAR", nil)
addSymbol(U(0x029BB), "ord", "olcross", "CIRCLE WITH SUPERIMPOSED X", nil)
addSymbol(U(0x029BC), "ord", "odotslashdot", "CIRCLED ANTICLOCKWISE-ROTATED DIVISION SIGN", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x029BD), "ord", "uparrowoncircle", "UP ARROW THROUGH CIRCLE", nil)
addSymbol(U(0x029BE), "ord", "circledwhitebullet", "CIRCLED WHITE BULLET", nil)
addSymbol(U(0x029BF), "ord", "circledbullet", "CIRCLED BULLET", nil)
addSymbol(U(0x029C0), "bin", "olessthan", "CIRCLED LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029C1), "bin", "ogreaterthan", "CIRCLED GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029C2), "ord", "cirscir", "CIRCLE WITH SMALL CIRCLE TO THE RIGHT", nil)
addSymbol(U(0x029C3), "ord", "cirE", "CIRCLE WITH TWO HORIZONTAL STROKES TO THE RIGHT", nil)
addSymbol(U(0x029C4), "bin", "boxdiag", "SQUARED RISING DIAGONAL SLASH", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x029C5), "bin", "boxbslash", "SQUARED FALLING DIAGONAL SLASH", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x029C6), "bin", "boxast", "SQUARED ASTERISK", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x029C7), "bin", "boxcircle", "SQUARED SMALL CIRCLE", {
  { form = "infix", lspace = 3, priority = 900, rspace = 3 }})
addSymbol(U(0x029C8), "bin", "boxbox", "SQUARED SQUARE", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x029C9), "ord", "boxonbox", "TWO JOINED SQUARES", nil)
addSymbol(U(0x029CA), "ord", "triangleodot", "TRIANGLE WITH DOT ABOVE", nil)
addSymbol(U(0x029CB), "ord", "triangleubar", "TRIANGLE WITH UNDERBAR", nil)
addSymbol(U(0x029CC), "ord", "triangles", "S IN TRIANGLE", nil)
addSymbol(U(0x029CD), "ord", "triangleserifs", "TRIANGLE WITH SERIFS AT BOTTOM", nil)
addSymbol(U(0x029CE), "rel", "rtriltri", "RIGHT TRIANGLE ABOVE LEFT TRIANGLE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029CF), "rel", "ltrivb", "LEFT TRIANGLE BESIDE VERTICAL BAR", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029D0), "rel", "vbrtri", "VERTICAL BAR BESIDE RIGHT TRIANGLE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029D1), "rel", "lfbowtie", "BOWTIE WITH LEFT HALF BLACK", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029D2), "rel", "rfbowtie", "BOWTIE WITH RIGHT HALF BLACK", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029D3), "rel", "fbowtie", "BLACK BOWTIE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029D4), "rel", "lftimes", "TIMES WITH LEFT HALF BLACK", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x029D5), "rel", "rftimes", "TIMES WITH RIGHT HALF BLACK", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x029D6), "bin", "hourglass", "WHITE HOURGLASS", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x029D7), "bin", "blackhourglass", "BLACK HOURGLASS", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x029D8), "open", "lvzigzag", "LEFT WIGGLY FENCE", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x029D9), "close", "rvzigzag", "RIGHT WIGGLY FENCE", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x029DA), "open", "Lvzigzag", "LEFT DOUBLE WIGGLY FENCE", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x029DB), "close", "Rvzigzag", "RIGHT DOUBLE WIGGLY FENCE", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x029DC), "ord", "iinfin", "INCOMPLETE INFINITY", nil)
addSymbol(U(0x029DD), "ord", "tieinfty", "TIE OVER INFINITY", nil)
addSymbol(U(0x029DE), "ord", "nvinfty", "INFINITY NEGATED WITH VERTICAL BAR", nil)
addSymbol(U(0x029DF), "rel", "dualmap", "DOUBLE-ENDED MULTIMAP", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x029E0), "ord", "laplac", "SQUARE WITH CONTOURED OUTLINE", nil)
addSymbol(U(0x029E1), "rel", "lrtriangleeq", "INCREASES AS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029E2), "bin", "shuffle", "SHUFFLE PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x029E3), "rel", "eparsl", "EQUALS SIGN AND SLANTED PARALLEL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029E4), "rel", "smeparsl", "EQUALS SIGN AND SLANTED PARALLEL WITH TILDE ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029E5), "rel", "eqvparsl", "IDENTICAL TO AND SLANTED PARALLEL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029E6), "rel", "gleichstark", "GLEICH STARK", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x029E7), "ord", "thermod", "THERMODYNAMIC", nil)
addSymbol(U(0x029E8), "ord", "downtriangleleftblack", "DOWN-POINTING TRIANGLE WITH LEFT HALF BLACK", nil)
addSymbol(U(0x029E9), "ord", "downtrianglerightblack", "DOWN-POINTING TRIANGLE WITH RIGHT HALF BLACK", nil)
addSymbol(U(0x029EA), "ord", "blackdiamonddownarrow", "BLACK DIAMOND WITH DOWN ARROW", nil)
addSymbol(U(0x029EB), "bin", "mdlgblklozenge", "BLACK LOZENGE", nil)
addSymbol(U(0x029EC), "ord", "circledownarrow", "WHITE CIRCLE WITH DOWN ARROW", nil)
addSymbol(U(0x029ED), "ord", "blackcircledownarrow", "BLACK CIRCLE WITH DOWN ARROW", nil)
addSymbol(U(0x029EE), "ord", "errbarsquare", "ERROR-BARRED WHITE SQUARE", nil)
addSymbol(U(0x029EF), "ord", "errbarblacksquare", "ERROR-BARRED BLACK SQUARE", nil)
addSymbol(U(0x029F0), "ord", "errbardiamond", "ERROR-BARRED WHITE DIAMOND", nil)
addSymbol(U(0x029F1), "ord", "errbarblackdiamond", "ERROR-BARRED BLACK DIAMOND", nil)
addSymbol(U(0x029F2), "ord", "errbarcircle", "ERROR-BARRED WHITE CIRCLE", nil)
addSymbol(U(0x029F3), "ord", "errbarblackcircle", "ERROR-BARRED BLACK CIRCLE", nil)
addSymbol(U(0x029F4), "rel", "ruledelayed", "RULE-DELAYED", {
  { form = "infix", lspace = 5, priority = 220, rspace = 5 }})
addSymbol(U(0x029F5), "bin", "reversesolidus", "REVERSE SOLIDUS OPERATOR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x029F6), "bin", "dsol", "SOLIDUS WITH OVERBAR", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x029F7), "bin", "rsolbar", "REVERSE SOLIDUS WITH HORIZONTAL STROKE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x029F8), "op", "xsol", "BIG SOLIDUS", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x029F9), "op", "xbsol", "BIG REVERSE SOLIDUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x029FA), "bin", "doubleplus", "DOUBLE PLUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x029FB), "bin", "tripleplus", "TRIPLE PLUS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x029FC), "open", "lcurvyangle", "LEFT-POINTING CURVED ANGLE BRACKET", {
  { fence = true, form = "prefix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x029FD), "close", "rcurvyangle", "RIGHT-POINTING CURVED ANGLE BRACKET", {
  { fence = true, form = "postfix", lspace = 0, priority = 120, rspace = 0, stretchy = true, symmetric = true }})
addSymbol(U(0x029FE), "bin", "tplus", "TINY", nil)
addSymbol(U(0x029FF), "bin", "tminus", "MINY", nil)
addSymbol(U(0x02A00), "op", "bigodot", "N-ARY CIRCLED DOT OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x02A01), "op", "bigoplus", "N-ARY CIRCLED PLUS OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 460, rspace = 3, symmetric = true }})
addSymbol(U(0x02A02), "op", "bigotimes", "N-ARY CIRCLED TIMES OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x02A03), "op", "bigcupdot", "N-ARY UNION OPERATOR WITH DOT", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 500, rspace = 3, symmetric = true }})
addSymbol(U(0x02A04), "op", "biguplus", "N-ARY UNION OPERATOR WITH PLUS", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 500, rspace = 3, symmetric = true }})
addSymbol(U(0x02A05), "op", "bigsqcap", "N-ARY SQUARE INTERSECTION OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x02A06), "op", "bigsqcup", "N-ARY SQUARE UNION OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x02A07), "op", "conjquant", "TWO LOGICAL AND OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x02A08), "op", "disjquant", "TWO LOGICAL OR OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x02A09), "op", "bigtimes", "N-ARY TIMES OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x02A0A), "op", "modtwosum", "MODULO TWO SUM", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 440, rspace = 3, symmetric = true }})
addSymbol(U(0x02A0B), "ord", "sumint", "SUMMATION WITH INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 440, rspace = 3, symmetric = true }})
addSymbol(U(0x02A0C), "ord", "iiiint", "QUADRUPLE INTEGRAL OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A0D), "ord", "intbar", "FINITE PART INTEGRAL", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A0E), "ord", "intBar", "INTEGRAL WITH DOUBLE STROKE", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A0F), "ord", "fint", "INTEGRAL AVERAGE WITH SLASH", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A10), "op", "cirfnint", "CIRCULATION FUNCTION", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A11), "op", "awint", "ANTICLOCKWISE INTEGRATION", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A12), "op", "rppolint", "LINE INTEGRATION WITH RECTANGULAR PATH AROUND POLE", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A13), "op", "scpolint", "LINE INTEGRATION WITH SEMICIRCULAR PATH AROUND POLE", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A14), "op", "npolint", "LINE INTEGRATION NOT INCLUDING THE POLE", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A15), "ord", "pointint", "INTEGRAL AROUND A POINT OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A16), "ord", "sqint", "QUATERNION INTEGRAL OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A17), "ord", "intlarhk", "INTEGRAL WITH LEFTWARDS ARROW WITH HOOK", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A18), "ord", "intx", "INTEGRAL WITH TIMES SIGN", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A19), "ord", "intcap", "INTEGRAL WITH INTERSECTION", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A1A), "ord", "intcup", "INTEGRAL WITH UNION", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A1B), "ord", "upint", "INTEGRAL WITH OVERBAR", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A1C), "ord", "lowint", "INTEGRAL WITH UNDERBAR", {
  { form = "prefix", largeop = true, lspace = 3, priority = 480, rspace = 3, symmetric = true }})
addSymbol(U(0x02A1D), "op", "Join", "JOIN", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 },
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 440, rspace = 3, symmetric = true }})
addSymbol(U(0x02A1E), "op", "bigtriangleleft", "LARGE LEFT TRIANGLE OPERATOR", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 },
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 440, rspace = 3, symmetric = true }})
addSymbol(U(0x02A1F), "op", "zcmp", "Z NOTATION SCHEMA COMPOSITION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A20), "op", "zpipe", "Z NOTATION SCHEMA PIPING", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A21), "op", "zproject", "Z NOTATION SCHEMA PROJECTION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A22), "bin", "ringplus", "PLUS SIGN WITH SMALL CIRCLE ABOVE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A23), "bin", "plushat", "PLUS SIGN WITH CIRCUMFLEX ACCENT ABOVE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A24), "bin", "simplus", "PLUS SIGN WITH TILDE ABOVE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A25), "bin", "plusdot", "PLUS SIGN WITH DOT BELOW", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A26), "bin", "plussim", "PLUS SIGN WITH TILDE BELOW", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A27), "bin", "plussubtwo", "PLUS SIGN WITH SUBSCRIPT TWO", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A28), "bin", "plustrif", "PLUS SIGN WITH BLACK TRIANGLE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A29), "bin", "commaminus", "MINUS SIGN WITH COMMA ABOVE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A2A), "bin", "minusdot", "MINUS SIGN WITH DOT BELOW", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A2B), "bin", "minusfdots", "MINUS SIGN WITH FALLING DOTS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A2C), "bin", "minusrdots", "MINUS SIGN WITH RISING DOTS", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A2D), "bin", "opluslhrim", "PLUS SIGN IN LEFT HALF CIRCLE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A2E), "bin", "oplusrhrim", "PLUS SIGN IN RIGHT HALF CIRCLE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A2F), "bin", "vectimes", "VECTOR OR CROSS PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A30), "bin", "dottimes", "MULTIPLICATION SIGN WITH DOT ABOVE", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A31), "bin", "timesbar", "MULTIPLICATION SIGN WITH UNDERBAR", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A32), "bin", "btimes", "SEMIDIRECT PRODUCT WITH BOTTOM CLOSED", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A33), "bin", "smashtimes", "SMASH PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A34), "bin", "otimeslhrim", "MULTIPLICATION SIGN IN LEFT HALF CIRCLE", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A35), "bin", "otimesrhrim", "MULTIPLICATION SIGN IN RIGHT HALF CIRCLE", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A36), "bin", "otimeshat", "CIRCLED MULTIPLICATION SIGN WITH CIRCUMFLEX ACCENT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A37), "bin", "Otimes", "MULTIPLICATION SIGN IN DOUBLE CIRCLE", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A38), "bin", "odiv", "CIRCLED DIVISION SIGN", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x02A39), "bin", "triangleplus", "PLUS SIGN IN TRIANGLE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A3A), "bin", "triangleminus", "MINUS SIGN IN TRIANGLE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A3B), "bin", "triangletimes", "MULTIPLICATION SIGN IN TRIANGLE", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A3C), "bin", "intprod", "INTERIOR PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A3D), "bin", "intprodr", "RIGHTHAND INTERIOR PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A3E), "bin", "fcmp", "Z NOTATION RELATIONAL COMPOSITION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A3F), "bin", "amalg", "AMALGAMATION OR COPRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A40), "bin", "capdot", "INTERSECTION WITH DOT", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A41), "bin", "uminus", "UNION WITH MINUS SIGN", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x02A42), "bin", "barcup", "UNION WITH OVERBAR", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x02A43), "bin", "barcap", "INTERSECTION WITH OVERBAR", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A44), "bin", "capwedge", "INTERSECTION WITH LOGICAL AND", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A45), "bin", "cupvee", "UNION WITH LOGICAL OR", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x02A46), "bin", "cupovercap", "UNION ABOVE INTERSECTION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A47), "bin", "capovercup", "INTERSECTION ABOVE UNION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A48), "bin", "cupbarcap", "UNION ABOVE BAR ABOVE INTERSECTION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A49), "bin", "capbarcup", "INTERSECTION ABOVE BAR ABOVE UNION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A4A), "bin", "twocups", "UNION BESIDE AND JOINED WITH UNION", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x02A4B), "bin", "twocaps", "INTERSECTION BESIDE AND JOINED WITH INTERSECTION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A4C), "bin", "closedvarcup", "CLOSED UNION WITH SERIFS", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x02A4D), "bin", "closedvarcap", "CLOSED INTERSECTION WITH SERIFS", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A4E), "bin", "Sqcap", "DOUBLE SQUARE INTERSECTION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02A4F), "bin", "Sqcup", "DOUBLE SQUARE UNION", {
  { form = "infix", lspace = 4, priority = 360, rspace = 4 }})
addSymbol(U(0x02A50), "bin", "closedvarcupsmashprod", "CLOSED UNION WITH SERIFS AND SMASH PRODUCT", {
  { form = "infix", lspace = 3, priority = 620, rspace = 3 }})
addSymbol(U(0x02A51), "bin", "wedgeodot", "LOGICAL AND WITH DOT ABOVE", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A52), "bin", "veeodot", "LOGICAL OR WITH DOT ABOVE", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A53), "bin", "Wedge", "DOUBLE LOGICAL AND", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A54), "bin", "Vee", "DOUBLE LOGICAL OR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A55), "bin", "wedgeonwedge", "TWO INTERSECTING LOGICAL AND", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A56), "bin", "veeonvee", "TWO INTERSECTING LOGICAL OR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A57), "bin", "bigslopedvee", "SLOPING LARGE OR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A58), "bin", "bigslopedwedge", "SLOPING LARGE AND", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A59), "rel", "veeonwedge", "LOGICAL OR OVERLAPPING LOGICAL AND", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A5A), "bin", "wedgemidvert", "LOGICAL AND WITH MIDDLE STEM", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A5B), "bin", "veemidvert", "LOGICAL OR WITH MIDDLE STEM", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A5C), "bin", "midbarwedge", "LOGICAL AND WITH HORIZONTAL DASH", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A5D), "bin", "midbarvee", "LOGICAL OR WITH HORIZONTAL DASH", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A5E), "bin", "doublebarwedge", "LOGICAL AND WITH DOUBLE OVERBAR", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A5F), "bin", "wedgebar", "LOGICAL AND WITH UNDERBAR", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A60), "bin", "wedgedoublebar", "LOGICAL AND WITH DOUBLE UNDERBAR", {
  { form = "infix", lspace = 4, priority = 600, rspace = 4 }})
addSymbol(U(0x02A61), "bin", "varveebar", "SMALL VEE WITH UNDERBAR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A62), "bin", "doublebarvee", "LOGICAL OR WITH DOUBLE OVERBAR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A63), "bin", "veedoublebar", "LOGICAL OR WITH DOUBLE UNDERBAR", {
  { form = "infix", lspace = 4, priority = 400, rspace = 4 }})
addSymbol(U(0x02A64), "bin", "dsub", "Z NOTATION DOMAIN ANTIRESTRICTION", {
  { form = "infix", lspace = 3, priority = 700, rspace = 3 }})
addSymbol(U(0x02A65), "bin", "rsub", "Z NOTATION RANGE ANTIRESTRICTION", {
  { form = "infix", lspace = 3, priority = 700, rspace = 3 }})
addSymbol(U(0x02A66), "rel", "eqdot", "EQUALS SIGN WITH DOT BELOW", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A67), "rel", "dotequiv", "IDENTICAL WITH DOT ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A68), "rel", "equivVert", "TRIPLE HORIZONTAL BAR WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A69), "rel", "equivVvert", "TRIPLE HORIZONTAL BAR WITH TRIPLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A6A), "rel", "dotsim", "TILDE OPERATOR WITH DOT ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A6B), "rel", "simrdots", "TILDE OPERATOR WITH RISING DOTS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A6C), "rel", "simminussim", "SIMILAR MINUS SIMILAR", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A6D), "rel", "congdot", "CONGRUENT WITH DOT ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A6E), "rel", "asteq", "EQUALS WITH ASTERISK", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A6F), "rel", "hatapprox", "ALMOST EQUAL TO WITH CIRCUMFLEX ACCENT", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A70), "rel", "approxeqq", "APPROXIMATELY EQUAL OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A71), "bin", "eqqplus", "EQUALS SIGN ABOVE PLUS SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A72), "bin", "pluseqq", "PLUS SIGN ABOVE EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A73), "rel", "eqqsim", "EQUALS SIGN ABOVE TILDE OPERATOR", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A74), "rel", "Coloneq", "DOUBLE COLON EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A75), "rel", "eqeq", "TWO CONSECUTIVE EQUALS SIGNS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A76), "rel", "eqeqeq", "THREE CONSECUTIVE EQUALS SIGNS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A77), "rel", "ddotseq", "EQUALS SIGN WITH TWO DOTS ABOVE AND TWO DOTS BELOW", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A78), "rel", "equivDD", "EQUIVALENT WITH FOUR DOTS ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A79), "rel", "ltcir", "LESS-THAN WITH CIRCLE INSIDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A7A), "rel", "gtcir", "GREATER-THAN WITH CIRCLE INSIDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A7B), "rel", "ltquest", "LESS-THAN WITH QUESTION MARK ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A7C), "rel", "gtquest", "GREATER-THAN WITH QUESTION MARK ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A7D), "rel", "leqslant", "LESS-THAN OR SLANTED EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A7E), "rel", "geqslant", "GREATER-THAN OR SLANTED EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A7F), "rel", "lesdot", "LESS-THAN OR SLANTED EQUAL TO WITH DOT INSIDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A80), "rel", "gesdot", "GREATER-THAN OR SLANTED EQUAL TO WITH DOT INSIDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A81), "rel", "lesdoto", "LESS-THAN OR SLANTED EQUAL TO WITH DOT ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A82), "rel", "gesdoto", "GREATER-THAN OR SLANTED EQUAL TO WITH DOT ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A83), "rel", "lesdotor", "LESS-THAN OR SLANTED EQUAL TO WITH DOT ABOVE RIGHT", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A84), "rel", "gesdotol", "GREATER-THAN OR SLANTED EQUAL TO WITH DOT ABOVE LEFT", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A85), "rel", "lessapprox", "LESS-THAN OR APPROXIMATE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A86), "rel", "gtrapprox", "GREATER-THAN OR APPROXIMATE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A87), "rel", "lneq", "LESS-THAN AND SINGLE-LINE NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A88), "rel", "gneq", "GREATER-THAN AND SINGLE-LINE NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A89), "rel", "lnapprox", "LESS-THAN AND NOT APPROXIMATE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A8A), "rel", "gnapprox", "GREATER-THAN AND NOT APPROXIMATE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A8B), "rel", "lesseqqgtr", "LESS-THAN ABOVE DOUBLE-LINE EQUAL ABOVE GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A8C), "rel", "gtreqqless", "GREATER-THAN ABOVE DOUBLE-LINE EQUAL ABOVE LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A8D), "rel", "lsime", "LESS-THAN ABOVE SIMILAR OR EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A8E), "rel", "gsime", "GREATER-THAN ABOVE SIMILAR OR EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A8F), "rel", "lsimg", "LESS-THAN ABOVE SIMILAR ABOVE GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A90), "rel", "gsiml", "GREATER-THAN ABOVE SIMILAR ABOVE LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A91), "rel", "lgE", "LESS-THAN ABOVE GREATER-THAN ABOVE DOUBLE-LINE EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A92), "rel", "glE", "GREATER-THAN ABOVE LESS-THAN ABOVE DOUBLE-LINE EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A93), "rel", "lesges", "LESS-THAN ABOVE SLANTED EQUAL ABOVE GREATER-THAN ABOVE SLANTED EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A94), "rel", "gesles", "GREATER-THAN ABOVE SLANTED EQUAL ABOVE LESS-THAN ABOVE SLANTED EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A95), "rel", "eqslantless", "SLANTED EQUAL TO OR LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A96), "rel", "eqslantgtr", "SLANTED EQUAL TO OR GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A97), "rel", "elsdot", "SLANTED EQUAL TO OR LESS-THAN WITH DOT INSIDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A98), "rel", "egsdot", "SLANTED EQUAL TO OR GREATER-THAN WITH DOT INSIDE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A99), "rel", "eqqless", "DOUBLE-LINE EQUAL TO OR LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A9A), "rel", "eqqgtr", "DOUBLE-LINE EQUAL TO OR GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A9B), "rel", "eqqslantless", "DOUBLE-LINE SLANTED EQUAL TO OR LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A9C), "rel", "eqqslantgtr", "DOUBLE-LINE SLANTED EQUAL TO OR GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A9D), "rel", "simless", "SIMILAR OR LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A9E), "rel", "simgtr", "SIMILAR OR GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02A9F), "rel", "simlE", "SIMILAR ABOVE LESS-THAN ABOVE EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA0), "rel", "simgE", "SIMILAR ABOVE GREATER-THAN ABOVE EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA1), "rel", "Lt", "DOUBLE NESTED LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA2), "rel", "Gt", "DOUBLE NESTED GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA3), "rel", "partialmeetcontraction", "DOUBLE NESTED LESS-THAN WITH UNDERBAR", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA4), "rel", "glj", "GREATER-THAN OVERLAPPING LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA5), "rel", "gla", "GREATER-THAN BESIDE LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA6), "rel", "ltcc", "LESS-THAN CLOSED BY CURVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA7), "rel", "gtcc", "GREATER-THAN CLOSED BY CURVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA8), "rel", "lescc", "LESS-THAN CLOSED BY CURVE ABOVE SLANTED EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AA9), "rel", "gescc", "GREATER-THAN CLOSED BY CURVE ABOVE SLANTED EQUAL", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AAA), "rel", "smt", "SMALLER THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AAB), "rel", "lat", "LARGER THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AAC), "rel", "smte", "SMALLER THAN OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AAD), "rel", "late", "LARGER THAN OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AAE), "rel", "bumpeqq", "EQUALS SIGN WITH BUMPY ABOVE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AAF), "rel", "preceq", "PRECEDES ABOVE SINGLE-LINE EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB0), "rel", "succeq", "SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB1), "rel", "precneq", "PRECEDES ABOVE SINGLE-LINE NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB2), "rel", "succneq", "SUCCEEDS ABOVE SINGLE-LINE NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB3), "rel", "preceqq", "PRECEDES ABOVE EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB4), "rel", "succeqq", "SUCCEEDS ABOVE EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB5), "rel", "precneqq", "PRECEDES ABOVE NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB6), "rel", "succneqq", "SUCCEEDS ABOVE NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB7), "rel", "precapprox", "PRECEDES ABOVE ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB8), "rel", "succapprox", "SUCCEEDS ABOVE ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AB9), "rel", "precnapprox", "PRECEDES ABOVE NOT ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02ABA), "rel", "succnapprox", "SUCCEEDS ABOVE NOT ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02ABB), "rel", "Prec", "DOUBLE PRECEDES", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02ABC), "rel", "Succ", "DOUBLE SUCCEEDS", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02ABD), "rel", "subsetdot", "SUBSET WITH DOT", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02ABE), "rel", "supsetdot", "SUPERSET WITH DOT", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02ABF), "rel", "subsetplus", "SUBSET WITH PLUS SIGN BELOW", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC0), "rel", "supsetplus", "SUPERSET WITH PLUS SIGN BELOW", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC1), "rel", "submult", "SUBSET WITH MULTIPLICATION SIGN BELOW", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC2), "rel", "supmult", "SUPERSET WITH MULTIPLICATION SIGN BELOW", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC3), "rel", "subedot", "SUBSET OF OR EQUAL TO WITH DOT ABOVE", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC4), "rel", "supedot", "SUPERSET OF OR EQUAL TO WITH DOT ABOVE", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC5), "rel", "subseteqq", "SUBSET OF ABOVE EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC6), "rel", "supseteqq", "SUPERSET OF ABOVE EQUALS SIGN", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC7), "rel", "subsim", "SUBSET OF ABOVE TILDE OPERATOR", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC8), "rel", "supsim", "SUPERSET OF ABOVE TILDE OPERATOR", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AC9), "rel", "subsetapprox", "SUBSET OF ABOVE ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02ACA), "rel", "supsetapprox", "SUPERSET OF ABOVE ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02ACB), "rel", "subsetneqq", "SUBSET OF ABOVE NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02ACC), "rel", "supsetneqq", "SUPERSET OF ABOVE NOT EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02ACD), "rel", "lsqhook", "SQUARE LEFT OPEN BOX OPERATOR", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02ACE), "rel", "rsqhook", "SQUARE RIGHT OPEN BOX OPERATOR", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02ACF), "rel", "csub", "CLOSED SUBSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD0), "rel", "csup", "CLOSED SUPERSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD1), "rel", "csube", "CLOSED SUBSET OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD2), "rel", "csupe", "CLOSED SUPERSET OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD3), "rel", "subsup", "SUBSET ABOVE SUPERSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD4), "rel", "supsub", "SUPERSET ABOVE SUBSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD5), "rel", "subsub", "SUBSET ABOVE SUBSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD6), "rel", "supsup", "SUPERSET ABOVE SUPERSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD7), "rel", "suphsub", "SUPERSET BESIDE SUBSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD8), "rel", "supdsub", "SUPERSET BESIDE AND JOINED BY DASH WITH SUBSET", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02AD9), "rel", "forkv", "ELEMENT OF OPENING DOWNWARDS", {
  { form = "infix", lspace = 5, priority = 300, rspace = 5 }})
addSymbol(U(0x02ADA), "rel", "topfork", "PITCHFORK WITH TEE TOP", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02ADB), "rel", "mlcp", "TRANSVERSAL INTERSECTION", {
  { form = "infix", lspace = 4, priority = 380, rspace = 4 }})
addSymbol(U(0x02ADC), "rel", "forks", "FORKING", {
  { form = "infix", lspace = 3, priority = 740, rspace = 3 }})
addSymbol(U(0x02ADD), "rel", "forksnot", "NONFORKING", {
  { form = "infix", lspace = 3, priority = 740, rspace = 3 }})
addSymbol(U(0x02ADE), "rel", "shortlefttack", "SHORT LEFT TACK", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02ADF), "rel", "shortdowntack", "SHORT DOWN TACK", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE0), "rel", "shortuptack", "SHORT UP TACK", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE1), "ord", "perps", "PERPENDICULAR WITH S", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE2), "rel", "vDdash", "VERTICAL BAR TRIPLE RIGHT TURNSTILE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE3), "rel", "dashV", "DOUBLE VERTICAL BAR LEFT TURNSTILE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE4), "rel", "Dashv", "VERTICAL BAR DOUBLE LEFT TURNSTILE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE5), "rel", "DashV", "DOUBLE VERTICAL BAR DOUBLE LEFT TURNSTILE", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE6), "rel", "varVdash", "LONG DASH FROM LEFT MEMBER OF DOUBLE VERTICAL", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE7), "rel", "Barv", "SHORT DOWN TACK WITH OVERBAR", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE8), "rel", "vBar", "SHORT UP TACK WITH UNDERBAR", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AE9), "rel", "vBarv", "SHORT UP TACK ABOVE SHORT DOWN TACK", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AEA), "rel", "barV", "DOUBLE DOWN TACK", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AEB), "rel", "Vbar", "DOUBLE UP TACK", {
  { form = "infix", lspace = 5, priority = 260, rspace = 5 }})
addSymbol(U(0x02AEC), "rel", "Not", "DOUBLE STROKE NOT SIGN", {
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x02AED), "rel", "bNot", "REVERSED DOUBLE STROKE NOT SIGN", {
  { form = "prefix", lspace = 0, priority = 280, rspace = 0 }})
addSymbol(U(0x02AEE), "rel", "revnmid", "DOES NOT DIVIDE WITH REVERSED NEGATION SLASH", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AEF), "rel", "cirmid", "VERTICAL LINE WITH CIRCLE ABOVE", nil)
addSymbol(U(0x02AF0), "rel", "midcir", "VERTICAL LINE WITH CIRCLE BELOW", nil)
addSymbol(U(0x02AF1), "ord", "topcir", "DOWN TACK WITH CIRCLE BELOW", nil)
addSymbol(U(0x02AF2), "rel", "nhpar", "PARALLEL WITH HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AF3), "rel", "parsim", "PARALLEL WITH TILDE OPERATOR", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AF4), "bin", "interleave", "TRIPLE VERTICAL BAR BINARY RELATION", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AF5), "bin", "nhVvert", "TRIPLE VERTICAL BAR WITH HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AF6), "bin", "threedotcolon", "TRIPLE COLON OPERATOR", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x02AF7), "rel", "lllnest", "TRIPLE NESTED LESS-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AF8), "rel", "gggnest", "TRIPLE NESTED GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AF9), "rel", "leqqslant", "DOUBLE-LINE SLANTED LESS-THAN OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AFA), "rel", "geqqslant", "DOUBLE-LINE SLANTED GREATER-THAN OR EQUAL TO", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x02AFB), "bin", "trslash", "TRIPLE SOLIDUS BINARY RELATION", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x02AFC), "op", "biginterleave", "LARGE TRIPLE VERTICAL BAR OPERATOR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x02AFD), "bin", "sslash", "DOUBLE SOLIDUS OPERATOR", {
  { form = "infix", lspace = 4, priority = 680, rspace = 4 }})
addSymbol(U(0x02AFE), "bin", "talloblong", "WHITE VERTICAL BAR", {
  { form = "infix", lspace = 3, priority = 680, rspace = 3 }})
addSymbol(U(0x02AFF), "op", "bigtalloblong", "N-ARY WHITE VERTICAL BAR", {
  { form = "prefix", largeop = true, lspace = 3, movablelimits = true, priority = 520, rspace = 3, symmetric = true }})
addSymbol(U(0x02B00), "rel", nil, "NORTH EAST WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B01), "rel", nil, "NORTH WEST WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B02), "rel", nil, "SOUTH EAST WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B03), "rel", nil, "SOUTH WEST WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B04), "rel", nil, "LEFT RIGHT WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B05), "rel", nil, "LEFTWARDS BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B06), "rel", nil, "UPWARDS BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B07), "rel", nil, "DOWNWARDS BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B08), "rel", nil, "NORTH EAST BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B09), "rel", nil, "NORTH WEST BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B0A), "rel", nil, "SOUTH EAST BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B0B), "rel", nil, "SOUTH WEST BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B0C), "rel", nil, "LEFT RIGHT BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B0D), "rel", nil, "UP DOWN BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B0E), "rel", nil, "RIGHTWARDS ARROW WITH TIP DOWNWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B0F), "rel", nil, "RIGHTWARDS ARROW WITH TIP UPWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B10), "rel", nil, "LEFTWARDS ARROW WITH TIP DOWNWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B11), "rel", nil, "LEFTWARDS ARROW WITH TIP UPWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B12), "ord", "squaretopblack", "SQUARE WITH TOP HALF BLACK", nil)
addSymbol(U(0x02B13), "ord", "squarebotblack", "SQUARE WITH BOTTOM HALF BLACK", nil)
addSymbol(U(0x02B14), "ord", "squareurblack", "SQUARE WITH UPPER RIGHT DIAGONAL HALF BLACK", nil)
addSymbol(U(0x02B15), "ord", "squarellblack", "SQUARE WITH LOWER LEFT DIAGONAL HALF BLACK", nil)
addSymbol(U(0x02B16), "ord", "diamondleftblack", "DIAMOND WITH LEFT HALF BLACK", nil)
addSymbol(U(0x02B17), "ord", "diamondrightblack", "DIAMOND WITH RIGHT HALF BLACK", nil)
addSymbol(U(0x02B18), "ord", "diamondtopblack", "DIAMOND WITH TOP HALF BLACK", nil)
addSymbol(U(0x02B19), "ord", "diamondbotblack", "DIAMOND WITH BOTTOM HALF BLACK", nil)
addSymbol(U(0x02B1A), "ord", "dottedsquare", "DOTTED SQUARE", nil)
addSymbol(U(0x02B1B), "ord", "lgblksquare", "BLACK LARGE SQUARE", nil)
addSymbol(U(0x02B1C), "ord", "lgwhtsquare", "WHITE LARGE SQUARE", nil)
addSymbol(U(0x02B1D), "ord", "vysmblksquare", "BLACK VERY SMALL SQUARE", nil)
addSymbol(U(0x02B1E), "ord", "vysmwhtsquare", "WHITE VERY SMALL SQUARE", nil)
addSymbol(U(0x02B1F), "ord", "pentagonblack", "BLACK PENTAGON", nil)
addSymbol(U(0x02B20), "ord", "pentagon", "WHITE PENTAGON", nil)
addSymbol(U(0x02B21), "ord", "varhexagon", "WHITE HEXAGON", nil)
addSymbol(U(0x02B22), "ord", "varhexagonblack", "BLACK HEXAGON", nil)
addSymbol(U(0x02B23), "ord", "hexagonblack", "HORIZONTAL BLACK HEXAGON", nil)
addSymbol(U(0x02B24), "ord", "lgblkcircle", "BLACK LARGE CIRCLE", nil)
addSymbol(U(0x02B25), "ord", "mdblkdiamond", "BLACK MEDIUM DIAMOND", nil)
addSymbol(U(0x02B26), "ord", "mdwhtdiamond", "WHITE MEDIUM DIAMOND", nil)
addSymbol(U(0x02B27), "ord", "mdblklozenge", "BLACK MEDIUM LOZENGE", nil)
addSymbol(U(0x02B28), "ord", "mdwhtlozenge", "WHITE MEDIUM LOZENGE", nil)
addSymbol(U(0x02B29), "ord", "smblkdiamond", "BLACK SMALL DIAMOND", nil)
addSymbol(U(0x02B2A), "ord", "smblklozenge", "BLACK SMALL LOZENGE", nil)
addSymbol(U(0x02B2B), "ord", "smwhtlozenge", "WHITE SMALL LOZENGE", nil)
addSymbol(U(0x02B2C), "ord", "blkhorzoval", "BLACK HORIZONTAL ELLIPSE", nil)
addSymbol(U(0x02B2D), "ord", "whthorzoval", "WHITE HORIZONTAL ELLIPSE", nil)
addSymbol(U(0x02B2E), "ord", "blkvertoval", "BLACK VERTICAL ELLIPSE", nil)
addSymbol(U(0x02B2F), "ord", "whtvertoval", "WHITE VERTICAL ELLIPSE", nil)
addSymbol(U(0x02B30), "rel", "circleonleftarrow", "LEFT ARROW WITH SMALL CIRCLE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B31), "rel", "leftthreearrows", "THREE LEFTWARDS ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B32), "rel", "leftarrowonoplus", "LEFT ARROW WITH CIRCLED PLUS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B33), "rel", "longleftsquigarrow", "LONG LEFTWARDS SQUIGGLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B34), "rel", "nvtwoheadleftarrow", "LEFTWARDS TWO-HEADED ARROW WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B35), "rel", "nVtwoheadleftarrow", "LEFTWARDS TWO-HEADED ARROW WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B36), "rel", "twoheadmapsfrom", "LEFTWARDS TWO-HEADED ARROW FROM BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B37), "rel", "twoheadleftdbkarrow", "LEFTWARDS TWO-HEADED TRIPLE DASH ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B38), "rel", "leftdotarrow", "LEFTWARDS ARROW WITH DOTTED STEM", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B39), "rel", "nvleftarrowtail", "LEFTWARDS ARROW WITH TAIL WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B3A), "rel", "nVleftarrowtail", "LEFTWARDS ARROW WITH TAIL WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B3B), "rel", "twoheadleftarrowtail", "LEFTWARDS TWO-HEADED ARROW WITH TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B3C), "rel", "nvtwoheadleftarrowtail", "LEFTWARDS TWO-HEADED ARROW WITH TAIL WITH VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B3D), "rel", "nVtwoheadleftarrowtail", "LEFTWARDS TWO-HEADED ARROW WITH TAIL WITH DOUBLE VERTICAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B3E), "rel", "leftarrowx", "LEFTWARDS ARROW THROUGH X", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B3F), "rel", "leftcurvedarrow", "WAVE ARROW POINTING DIRECTLY LEFT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B40), "rel", "equalleftarrow", "EQUALS SIGN ABOVE LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B41), "rel", "bsimilarleftarrow", "REVERSE TILDE OPERATOR ABOVE LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B42), "rel", "leftarrowbackapprox", "LEFTWARDS ARROW ABOVE REVERSE ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B43), "rel", "rightarrowgtr", "RIGHTWARDS ARROW THROUGH GREATER-THAN", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B44), "rel", "rightarrowsupset", "RIGHTWARDS ARROW THROUGH SUPERSET", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B45), "ord", "LLeftarrow", "LEFTWARDS QUADRUPLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B46), "ord", "RRightarrow", "RIGHTWARDS QUADRUPLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B47), "rel", "bsimilarrightarrow", "REVERSE TILDE OPERATOR ABOVE RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B48), "rel", "rightarrowbackapprox", "RIGHTWARDS ARROW ABOVE REVERSE ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B49), "rel", "similarleftarrow", "TILDE OPERATOR ABOVE LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B4A), "rel", "leftarrowapprox", "LEFTWARDS ARROW ABOVE ALMOST EQUAL TO", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B4B), "rel", "leftarrowbsimilar", "LEFTWARDS ARROW ABOVE REVERSE TILDE OPERATOR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B4C), "rel", "rightarrowbsimilar", "RIGHTWARDS ARROW ABOVE REVERSE TILDE OPERATOR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B4D), "ord", nil, "DOWNWARDS TRIANGLE-HEADED ZIGZAG ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B4E), "ord", nil, "SHORT SLANTED NORTH ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B4F), "ord", nil, "SHORT BACKSLANTED SOUTH ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B50), "ord", "medwhitestar", "WHITE MEDIUM STAR", nil)
addSymbol(U(0x02B51), "ord", "medblackstar", "BLACK SMALL STAR", nil)
addSymbol(U(0x02B52), "ord", "smwhitestar", "WHITE SMALL STAR", nil)
addSymbol(U(0x02B53), "ord", "rightpentagonblack", "BLACK RIGHT-POINTING PENTAGON", nil)
addSymbol(U(0x02B54), "ord", "rightpentagon", "WHITE RIGHT-POINTING PENTAGON", nil)
addSymbol(U(0x02B5A), "ord", nil, "SLANTED NORTH ARROW WITH HOOKED HEAD", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B5B), "ord", nil, "BACKSLANTED SOUTH ARROW WITH HOOKED TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B5C), "ord", nil, "SLANTED NORTH ARROW WITH HORIZONTAL TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B5D), "ord", nil, "BACKSLANTED SOUTH ARROW WITH HORIZONTAL TAIL", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B5E), "ord", nil, "BENT ARROW POINTING DOWNWARDS THEN NORTH EAST", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B5F), "ord", nil, "SHORT BENT ARROW POINTING DOWNWARDS THEN NORTH EAST", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B60), "ord", nil, "LEFTWARDS TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B61), "ord", nil, "UPWARDS TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B62), "ord", nil, "RIGHTWARDS TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B63), "ord", nil, "DOWNWARDS TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B64), "ord", nil, "LEFT RIGHT TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B65), "ord", nil, "UP DOWN TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B66), "ord", nil, "NORTH WEST TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B67), "ord", nil, "NORTH EAST TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B68), "ord", nil, "SOUTH EAST TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B69), "ord", nil, "SOUTH WEST TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B6A), "ord", nil, "LEFTWARDS TRIANGLE-HEADED DASHED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B6B), "ord", nil, "UPWARDS TRIANGLE-HEADED DASHED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B6C), "ord", nil, "RIGHTWARDS TRIANGLE-HEADED DASHED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B6D), "ord", nil, "DOWNWARDS TRIANGLE-HEADED DASHED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B6E), "ord", nil, "CLOCKWISE TRIANGLE-HEADED OPEN CIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B6F), "ord", nil, "ANTICLOCKWISE TRIANGLE-HEADED OPEN CIRCLE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B70), "ord", nil, "LEFTWARDS TRIANGLE-HEADED ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B71), "ord", nil, "UPWARDS TRIANGLE-HEADED ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B72), "ord", nil, "RIGHTWARDS TRIANGLE-HEADED ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B73), "ord", nil, "DOWNWARDS TRIANGLE-HEADED ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B76), "ord", nil, "NORTH WEST TRIANGLE-HEADED ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B77), "ord", nil, "NORTH EAST TRIANGLE-HEADED ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B78), "ord", nil, "SOUTH EAST TRIANGLE-HEADED ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B79), "ord", nil, "SOUTH WEST TRIANGLE-HEADED ARROW TO BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B7A), "ord", nil, "LEFTWARDS TRIANGLE-HEADED ARROW WITH DOUBLE HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B7B), "ord", nil, "UPWARDS TRIANGLE-HEADED ARROW WITH DOUBLE HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B7C), "ord", nil, "RIGHTWARDS TRIANGLE-HEADED ARROW WITH DOUBLE HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B7D), "ord", nil, "DOWNWARDS TRIANGLE-HEADED ARROW WITH DOUBLE HORIZONTAL STROKE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B80), "ord", nil, "LEFTWARDS TRIANGLE-HEADED ARROW OVER RIGHTWARDS TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B81), "ord", nil, "UPWARDS TRIANGLE-HEADED ARROW LEFTWARDS OF DOWNWARDS TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B82), "ord", nil, "RIGHTWARDS TRIANGLE-HEADED ARROW OVER LEFTWARDS TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B83), "ord", nil, "DOWNWARDS TRIANGLE-HEADED ARROW LEFTWARDS OF UPWARDS TRIANGLE-HEADED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B84), "ord", nil, "LEFTWARDS TRIANGLE-HEADED PAIRED ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B85), "ord", nil, "UPWARDS TRIANGLE-HEADED PAIRED ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B86), "ord", nil, "RIGHTWARDS TRIANGLE-HEADED PAIRED ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B87), "ord", nil, "DOWNWARDS TRIANGLE-HEADED PAIRED ARROWS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02B88), "ord", nil, "LEFTWARDS BLACK CIRCLED WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B89), "ord", nil, "UPWARDS BLACK CIRCLED WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B8A), "ord", nil, "RIGHTWARDS BLACK CIRCLED WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B8B), "ord", nil, "DOWNWARDS BLACK CIRCLED WHITE ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B8C), "ord", nil, "ANTICLOCKWISE TRIANGLE-HEADED RIGHT U-SHAPED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B8D), "ord", nil, "ANTICLOCKWISE TRIANGLE-HEADED BOTTOM U-SHAPED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B8E), "ord", nil, "ANTICLOCKWISE TRIANGLE-HEADED LEFT U-SHAPED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B8F), "ord", nil, "ANTICLOCKWISE TRIANGLE-HEADED TOP U-SHAPED ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B94), "ord", nil, "FOUR CORNER ARROWS CIRCLING ANTICLOCKWISE", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02B95), "ord", nil, "RIGHTWARDS BLACK ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA0), "ord", nil, "DOWNWARDS TRIANGLE-HEADED ARROW WITH LONG TIP LEFTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA1), "ord", nil, "DOWNWARDS TRIANGLE-HEADED ARROW WITH LONG TIP RIGHTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA2), "ord", nil, "UPWARDS TRIANGLE-HEADED ARROW WITH LONG TIP LEFTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA3), "ord", nil, "UPWARDS TRIANGLE-HEADED ARROW WITH LONG TIP RIGHTWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA4), "ord", nil, "LEFTWARDS TRIANGLE-HEADED ARROW WITH LONG TIP UPWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA5), "ord", nil, "RIGHTWARDS TRIANGLE-HEADED ARROW WITH LONG TIP UPWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA6), "ord", nil, "LEFTWARDS TRIANGLE-HEADED ARROW WITH LONG TIP DOWNWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA7), "ord", nil, "RIGHTWARDS TRIANGLE-HEADED ARROW WITH LONG TIP DOWNWARDS", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA8), "ord", nil, "BLACK CURVED DOWNWARDS AND LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BA9), "ord", nil, "BLACK CURVED DOWNWARDS AND RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BAA), "ord", nil, "BLACK CURVED UPWARDS AND LEFTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BAB), "ord", nil, "BLACK CURVED UPWARDS AND RIGHTWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BAC), "ord", nil, "BLACK CURVED LEFTWARDS AND UPWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BAD), "ord", nil, "BLACK CURVED RIGHTWARDS AND UPWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BAE), "ord", nil, "BLACK CURVED LEFTWARDS AND DOWNWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BAF), "ord", nil, "BLACK CURVED RIGHTWARDS AND DOWNWARDS ARROW", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BB0), "ord", nil, "RIBBON ARROW DOWN LEFT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02BB1), "ord", nil, "RIBBON ARROW DOWN RIGHT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02BB2), "ord", nil, "RIBBON ARROW UP LEFT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02BB3), "ord", nil, "RIBBON ARROW UP RIGHT", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02BB4), "ord", nil, "RIBBON ARROW LEFT UP", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02BB5), "ord", nil, "RIBBON ARROW RIGHT UP", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02BB6), "ord", nil, "RIBBON ARROW LEFT DOWN", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02BB7), "ord", nil, "RIBBON ARROW RIGHT DOWN", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5 }})
addSymbol(U(0x02BB8), "ord", nil, "UPWARDS WHITE ARROW FROM BAR WITH HORIZONTAL BAR", {
  { form = "infix", lspace = 5, priority = 340, rspace = 5, stretchy = true }})
addSymbol(U(0x02BD1), "ord", nil, "UNCERTAINTY SIGN", {
  { form = "infix", lspace = 5, priority = 320, rspace = 5 }})
addSymbol(U(0x03012), "ord", "postalmark", "POSTAL MARK", nil)
addSymbol(U(0x03030), "ord", "hzigzag", "WAVY DASH", nil)
addSymbol(U(0x1D400), "ord", "mbfA", "MATHEMATICAL BOLD CAPITAL A", nil)
addSymbol(U(0x1D401), "ord", "mbfB", "MATHEMATICAL BOLD CAPITAL B", nil)
addSymbol(U(0x1D402), "ord", "mbfC", "MATHEMATICAL BOLD CAPITAL C", nil)
addSymbol(U(0x1D403), "ord", "mbfD", "MATHEMATICAL BOLD CAPITAL D", nil)
addSymbol(U(0x1D404), "ord", "mbfE", "MATHEMATICAL BOLD CAPITAL E", nil)
addSymbol(U(0x1D405), "ord", "mbfF", "MATHEMATICAL BOLD CAPITAL F", nil)
addSymbol(U(0x1D406), "ord", "mbfG", "MATHEMATICAL BOLD CAPITAL G", nil)
addSymbol(U(0x1D407), "ord", "mbfH", "MATHEMATICAL BOLD CAPITAL H", nil)
addSymbol(U(0x1D408), "ord", "mbfI", "MATHEMATICAL BOLD CAPITAL I", nil)
addSymbol(U(0x1D409), "ord", "mbfJ", "MATHEMATICAL BOLD CAPITAL J", nil)
addSymbol(U(0x1D40A), "ord", "mbfK", "MATHEMATICAL BOLD CAPITAL K", nil)
addSymbol(U(0x1D40B), "ord", "mbfL", "MATHEMATICAL BOLD CAPITAL L", nil)
addSymbol(U(0x1D40C), "ord", "mbfM", "MATHEMATICAL BOLD CAPITAL M", nil)
addSymbol(U(0x1D40D), "ord", "mbfN", "MATHEMATICAL BOLD CAPITAL N", nil)
addSymbol(U(0x1D40E), "ord", "mbfO", "MATHEMATICAL BOLD CAPITAL O", nil)
addSymbol(U(0x1D40F), "ord", "mbfP", "MATHEMATICAL BOLD CAPITAL P", nil)
addSymbol(U(0x1D410), "ord", "mbfQ", "MATHEMATICAL BOLD CAPITAL Q", nil)
addSymbol(U(0x1D411), "ord", "mbfR", "MATHEMATICAL BOLD CAPITAL R", nil)
addSymbol(U(0x1D412), "ord", "mbfS", "MATHEMATICAL BOLD CAPITAL S", nil)
addSymbol(U(0x1D413), "ord", "mbfT", "MATHEMATICAL BOLD CAPITAL T", nil)
addSymbol(U(0x1D414), "ord", "mbfU", "MATHEMATICAL BOLD CAPITAL U", nil)
addSymbol(U(0x1D415), "ord", "mbfV", "MATHEMATICAL BOLD CAPITAL V", nil)
addSymbol(U(0x1D416), "ord", "mbfW", "MATHEMATICAL BOLD CAPITAL W", nil)
addSymbol(U(0x1D417), "ord", "mbfX", "MATHEMATICAL BOLD CAPITAL X", nil)
addSymbol(U(0x1D418), "ord", "mbfY", "MATHEMATICAL BOLD CAPITAL Y", nil)
addSymbol(U(0x1D419), "ord", "mbfZ", "MATHEMATICAL BOLD CAPITAL Z", nil)
addSymbol(U(0x1D41A), "ord", "mbfa", "MATHEMATICAL BOLD SMALL A", nil)
addSymbol(U(0x1D41B), "ord", "mbfb", "MATHEMATICAL BOLD SMALL B", nil)
addSymbol(U(0x1D41C), "ord", "mbfc", "MATHEMATICAL BOLD SMALL C", nil)
addSymbol(U(0x1D41D), "ord", "mbfd", "MATHEMATICAL BOLD SMALL D", nil)
addSymbol(U(0x1D41E), "ord", "mbfe", "MATHEMATICAL BOLD SMALL E", nil)
addSymbol(U(0x1D41F), "ord", "mbff", "MATHEMATICAL BOLD SMALL F", nil)
addSymbol(U(0x1D420), "ord", "mbfg", "MATHEMATICAL BOLD SMALL G", nil)
addSymbol(U(0x1D421), "ord", "mbfh", "MATHEMATICAL BOLD SMALL H", nil)
addSymbol(U(0x1D422), "ord", "mbfi", "MATHEMATICAL BOLD SMALL I", nil)
addSymbol(U(0x1D423), "ord", "mbfj", "MATHEMATICAL BOLD SMALL J", nil)
addSymbol(U(0x1D424), "ord", "mbfk", "MATHEMATICAL BOLD SMALL K", nil)
addSymbol(U(0x1D425), "ord", "mbfl", "MATHEMATICAL BOLD SMALL L", nil)
addSymbol(U(0x1D426), "ord", "mbfm", "MATHEMATICAL BOLD SMALL M", nil)
addSymbol(U(0x1D427), "ord", "mbfn", "MATHEMATICAL BOLD SMALL N", nil)
addSymbol(U(0x1D428), "ord", "mbfo", "MATHEMATICAL BOLD SMALL O", nil)
addSymbol(U(0x1D429), "ord", "mbfp", "MATHEMATICAL BOLD SMALL P", nil)
addSymbol(U(0x1D42A), "ord", "mbfq", "MATHEMATICAL BOLD SMALL Q", nil)
addSymbol(U(0x1D42B), "ord", "mbfr", "MATHEMATICAL BOLD SMALL R", nil)
addSymbol(U(0x1D42C), "ord", "mbfs", "MATHEMATICAL BOLD SMALL S", nil)
addSymbol(U(0x1D42D), "ord", "mbft", "MATHEMATICAL BOLD SMALL T", nil)
addSymbol(U(0x1D42E), "ord", "mbfu", "MATHEMATICAL BOLD SMALL U", nil)
addSymbol(U(0x1D42F), "ord", "mbfv", "MATHEMATICAL BOLD SMALL V", nil)
addSymbol(U(0x1D430), "ord", "mbfw", "MATHEMATICAL BOLD SMALL W", nil)
addSymbol(U(0x1D431), "ord", "mbfx", "MATHEMATICAL BOLD SMALL X", nil)
addSymbol(U(0x1D432), "ord", "mbfy", "MATHEMATICAL BOLD SMALL Y", nil)
addSymbol(U(0x1D433), "ord", "mbfz", "MATHEMATICAL BOLD SMALL Z", nil)
addSymbol(U(0x1D434), "ord", "mitA", "MATHEMATICAL ITALIC CAPITAL A", nil)
addSymbol(U(0x1D435), "ord", "mitB", "MATHEMATICAL ITALIC CAPITAL B", nil)
addSymbol(U(0x1D436), "ord", "mitC", "MATHEMATICAL ITALIC CAPITAL C", nil)
addSymbol(U(0x1D437), "ord", "mitD", "MATHEMATICAL ITALIC CAPITAL D", nil)
addSymbol(U(0x1D438), "ord", "mitE", "MATHEMATICAL ITALIC CAPITAL E", nil)
addSymbol(U(0x1D439), "ord", "mitF", "MATHEMATICAL ITALIC CAPITAL F", nil)
addSymbol(U(0x1D43A), "ord", "mitG", "MATHEMATICAL ITALIC CAPITAL G", nil)
addSymbol(U(0x1D43B), "ord", "mitH", "MATHEMATICAL ITALIC CAPITAL H", nil)
addSymbol(U(0x1D43C), "ord", "mitI", "MATHEMATICAL ITALIC CAPITAL I", nil)
addSymbol(U(0x1D43D), "ord", "mitJ", "MATHEMATICAL ITALIC CAPITAL J", nil)
addSymbol(U(0x1D43E), "ord", "mitK", "MATHEMATICAL ITALIC CAPITAL K", nil)
addSymbol(U(0x1D43F), "ord", "mitL", "MATHEMATICAL ITALIC CAPITAL L", nil)
addSymbol(U(0x1D440), "ord", "mitM", "MATHEMATICAL ITALIC CAPITAL M", nil)
addSymbol(U(0x1D441), "ord", "mitN", "MATHEMATICAL ITALIC CAPITAL N", nil)
addSymbol(U(0x1D442), "ord", "mitO", "MATHEMATICAL ITALIC CAPITAL O", nil)
addSymbol(U(0x1D443), "ord", "mitP", "MATHEMATICAL ITALIC CAPITAL P", nil)
addSymbol(U(0x1D444), "ord", "mitQ", "MATHEMATICAL ITALIC CAPITAL Q", nil)
addSymbol(U(0x1D445), "ord", "mitR", "MATHEMATICAL ITALIC CAPITAL R", nil)
addSymbol(U(0x1D446), "ord", "mitS", "MATHEMATICAL ITALIC CAPITAL S", nil)
addSymbol(U(0x1D447), "ord", "mitT", "MATHEMATICAL ITALIC CAPITAL T", nil)
addSymbol(U(0x1D448), "ord", "mitU", "MATHEMATICAL ITALIC CAPITAL U", nil)
addSymbol(U(0x1D449), "ord", "mitV", "MATHEMATICAL ITALIC CAPITAL V", nil)
addSymbol(U(0x1D44A), "ord", "mitW", "MATHEMATICAL ITALIC CAPITAL W", nil)
addSymbol(U(0x1D44B), "ord", "mitX", "MATHEMATICAL ITALIC CAPITAL X", nil)
addSymbol(U(0x1D44C), "ord", "mitY", "MATHEMATICAL ITALIC CAPITAL Y", nil)
addSymbol(U(0x1D44D), "ord", "mitZ", "MATHEMATICAL ITALIC CAPITAL Z", nil)
addSymbol(U(0x1D44E), "ord", "mita", "MATHEMATICAL ITALIC SMALL A", nil)
addSymbol(U(0x1D44F), "ord", "mitb", "MATHEMATICAL ITALIC SMALL B", nil)
addSymbol(U(0x1D450), "ord", "mitc", "MATHEMATICAL ITALIC SMALL C", nil)
addSymbol(U(0x1D451), "ord", "mitd", "MATHEMATICAL ITALIC SMALL D", nil)
addSymbol(U(0x1D452), "ord", "mite", "MATHEMATICAL ITALIC SMALL E", nil)
addSymbol(U(0x1D453), "ord", "mitf", "MATHEMATICAL ITALIC SMALL F", nil)
addSymbol(U(0x1D454), "ord", "mitg", "MATHEMATICAL ITALIC SMALL G", nil)
addSymbol(U(0x1D456), "ord", "miti", "MATHEMATICAL ITALIC SMALL I", nil)
addSymbol(U(0x1D457), "ord", "mitj", "MATHEMATICAL ITALIC SMALL J", nil)
addSymbol(U(0x1D458), "ord", "mitk", "MATHEMATICAL ITALIC SMALL K", nil)
addSymbol(U(0x1D459), "ord", "mitl", "MATHEMATICAL ITALIC SMALL L", nil)
addSymbol(U(0x1D45A), "ord", "mitm", "MATHEMATICAL ITALIC SMALL M", nil)
addSymbol(U(0x1D45B), "ord", "mitn", "MATHEMATICAL ITALIC SMALL N", nil)
addSymbol(U(0x1D45C), "ord", "mito", "MATHEMATICAL ITALIC SMALL O", nil)
addSymbol(U(0x1D45D), "ord", "mitp", "MATHEMATICAL ITALIC SMALL P", nil)
addSymbol(U(0x1D45E), "ord", "mitq", "MATHEMATICAL ITALIC SMALL Q", nil)
addSymbol(U(0x1D45F), "ord", "mitr", "MATHEMATICAL ITALIC SMALL R", nil)
addSymbol(U(0x1D460), "ord", "mits", "MATHEMATICAL ITALIC SMALL S", nil)
addSymbol(U(0x1D461), "ord", "mitt", "MATHEMATICAL ITALIC SMALL T", nil)
addSymbol(U(0x1D462), "ord", "mitu", "MATHEMATICAL ITALIC SMALL U", nil)
addSymbol(U(0x1D463), "ord", "mitv", "MATHEMATICAL ITALIC SMALL V", nil)
addSymbol(U(0x1D464), "ord", "mitw", "MATHEMATICAL ITALIC SMALL W", nil)
addSymbol(U(0x1D465), "ord", "mitx", "MATHEMATICAL ITALIC SMALL X", nil)
addSymbol(U(0x1D466), "ord", "mity", "MATHEMATICAL ITALIC SMALL Y", nil)
addSymbol(U(0x1D467), "ord", "mitz", "MATHEMATICAL ITALIC SMALL Z", nil)
addSymbol(U(0x1D468), "ord", "mbfitA", "MATHEMATICAL BOLD ITALIC CAPITAL A", nil)
addSymbol(U(0x1D469), "ord", "mbfitB", "MATHEMATICAL BOLD ITALIC CAPITAL B", nil)
addSymbol(U(0x1D46A), "ord", "mbfitC", "MATHEMATICAL BOLD ITALIC CAPITAL C", nil)
addSymbol(U(0x1D46B), "ord", "mbfitD", "MATHEMATICAL BOLD ITALIC CAPITAL D", nil)
addSymbol(U(0x1D46C), "ord", "mbfitE", "MATHEMATICAL BOLD ITALIC CAPITAL E", nil)
addSymbol(U(0x1D46D), "ord", "mbfitF", "MATHEMATICAL BOLD ITALIC CAPITAL F", nil)
addSymbol(U(0x1D46E), "ord", "mbfitG", "MATHEMATICAL BOLD ITALIC CAPITAL G", nil)
addSymbol(U(0x1D46F), "ord", "mbfitH", "MATHEMATICAL BOLD ITALIC CAPITAL H", nil)
addSymbol(U(0x1D470), "ord", "mbfitI", "MATHEMATICAL BOLD ITALIC CAPITAL I", nil)
addSymbol(U(0x1D471), "ord", "mbfitJ", "MATHEMATICAL BOLD ITALIC CAPITAL J", nil)
addSymbol(U(0x1D472), "ord", "mbfitK", "MATHEMATICAL BOLD ITALIC CAPITAL K", nil)
addSymbol(U(0x1D473), "ord", "mbfitL", "MATHEMATICAL BOLD ITALIC CAPITAL L", nil)
addSymbol(U(0x1D474), "ord", "mbfitM", "MATHEMATICAL BOLD ITALIC CAPITAL M", nil)
addSymbol(U(0x1D475), "ord", "mbfitN", "MATHEMATICAL BOLD ITALIC CAPITAL N", nil)
addSymbol(U(0x1D476), "ord", "mbfitO", "MATHEMATICAL BOLD ITALIC CAPITAL O", nil)
addSymbol(U(0x1D477), "ord", "mbfitP", "MATHEMATICAL BOLD ITALIC CAPITAL P", nil)
addSymbol(U(0x1D478), "ord", "mbfitQ", "MATHEMATICAL BOLD ITALIC CAPITAL Q", nil)
addSymbol(U(0x1D479), "ord", "mbfitR", "MATHEMATICAL BOLD ITALIC CAPITAL R", nil)
addSymbol(U(0x1D47A), "ord", "mbfitS", "MATHEMATICAL BOLD ITALIC CAPITAL S", nil)
addSymbol(U(0x1D47B), "ord", "mbfitT", "MATHEMATICAL BOLD ITALIC CAPITAL T", nil)
addSymbol(U(0x1D47C), "ord", "mbfitU", "MATHEMATICAL BOLD ITALIC CAPITAL U", nil)
addSymbol(U(0x1D47D), "ord", "mbfitV", "MATHEMATICAL BOLD ITALIC CAPITAL V", nil)
addSymbol(U(0x1D47E), "ord", "mbfitW", "MATHEMATICAL BOLD ITALIC CAPITAL W", nil)
addSymbol(U(0x1D47F), "ord", "mbfitX", "MATHEMATICAL BOLD ITALIC CAPITAL X", nil)
addSymbol(U(0x1D480), "ord", "mbfitY", "MATHEMATICAL BOLD ITALIC CAPITAL Y", nil)
addSymbol(U(0x1D481), "ord", "mbfitZ", "MATHEMATICAL BOLD ITALIC CAPITAL Z", nil)
addSymbol(U(0x1D482), "ord", "mbfita", "MATHEMATICAL BOLD ITALIC SMALL A", nil)
addSymbol(U(0x1D483), "ord", "mbfitb", "MATHEMATICAL BOLD ITALIC SMALL B", nil)
addSymbol(U(0x1D484), "ord", "mbfitc", "MATHEMATICAL BOLD ITALIC SMALL C", nil)
addSymbol(U(0x1D485), "ord", "mbfitd", "MATHEMATICAL BOLD ITALIC SMALL D", nil)
addSymbol(U(0x1D486), "ord", "mbfite", "MATHEMATICAL BOLD ITALIC SMALL E", nil)
addSymbol(U(0x1D487), "ord", "mbfitf", "MATHEMATICAL BOLD ITALIC SMALL F", nil)
addSymbol(U(0x1D488), "ord", "mbfitg", "MATHEMATICAL BOLD ITALIC SMALL G", nil)
addSymbol(U(0x1D489), "ord", "mbfith", "MATHEMATICAL BOLD ITALIC SMALL H", nil)
addSymbol(U(0x1D48A), "ord", "mbfiti", "MATHEMATICAL BOLD ITALIC SMALL I", nil)
addSymbol(U(0x1D48B), "ord", "mbfitj", "MATHEMATICAL BOLD ITALIC SMALL J", nil)
addSymbol(U(0x1D48C), "ord", "mbfitk", "MATHEMATICAL BOLD ITALIC SMALL K", nil)
addSymbol(U(0x1D48D), "ord", "mbfitl", "MATHEMATICAL BOLD ITALIC SMALL L", nil)
addSymbol(U(0x1D48E), "ord", "mbfitm", "MATHEMATICAL BOLD ITALIC SMALL M", nil)
addSymbol(U(0x1D48F), "ord", "mbfitn", "MATHEMATICAL BOLD ITALIC SMALL N", nil)
addSymbol(U(0x1D490), "ord", "mbfito", "MATHEMATICAL BOLD ITALIC SMALL O", nil)
addSymbol(U(0x1D491), "ord", "mbfitp", "MATHEMATICAL BOLD ITALIC SMALL P", nil)
addSymbol(U(0x1D492), "ord", "mbfitq", "MATHEMATICAL BOLD ITALIC SMALL Q", nil)
addSymbol(U(0x1D493), "ord", "mbfitr", "MATHEMATICAL BOLD ITALIC SMALL R", nil)
addSymbol(U(0x1D494), "ord", "mbfits", "MATHEMATICAL BOLD ITALIC SMALL S", nil)
addSymbol(U(0x1D495), "ord", "mbfitt", "MATHEMATICAL BOLD ITALIC SMALL T", nil)
addSymbol(U(0x1D496), "ord", "mbfitu", "MATHEMATICAL BOLD ITALIC SMALL U", nil)
addSymbol(U(0x1D497), "ord", "mbfitv", "MATHEMATICAL BOLD ITALIC SMALL V", nil)
addSymbol(U(0x1D498), "ord", "mbfitw", "MATHEMATICAL BOLD ITALIC SMALL W", nil)
addSymbol(U(0x1D499), "ord", "mbfitx", "MATHEMATICAL BOLD ITALIC SMALL X", nil)
addSymbol(U(0x1D49A), "ord", "mbfity", "MATHEMATICAL BOLD ITALIC SMALL Y", nil)
addSymbol(U(0x1D49B), "ord", "mbfitz", "MATHEMATICAL BOLD ITALIC SMALL Z", nil)
addSymbol(U(0x1D49C), "ord", "mscrA", "MATHEMATICAL SCRIPT CAPITAL A", nil)
addSymbol(U(0x1D49E), "ord", "mscrC", "MATHEMATICAL SCRIPT CAPITAL C", nil)
addSymbol(U(0x1D49F), "ord", "mscrD", "MATHEMATICAL SCRIPT CAPITAL D", nil)
addSymbol(U(0x1D4A2), "ord", "mscrG", "MATHEMATICAL SCRIPT CAPITAL G", nil)
addSymbol(U(0x1D4A5), "ord", "mscrJ", "MATHEMATICAL SCRIPT CAPITAL J", nil)
addSymbol(U(0x1D4A6), "ord", "mscrK", "MATHEMATICAL SCRIPT CAPITAL K", nil)
addSymbol(U(0x1D4A9), "ord", "mscrN", "MATHEMATICAL SCRIPT CAPITAL N", nil)
addSymbol(U(0x1D4AA), "ord", "mscrO", "MATHEMATICAL SCRIPT CAPITAL O", nil)
addSymbol(U(0x1D4AB), "ord", "mscrP", "MATHEMATICAL SCRIPT CAPITAL P", nil)
addSymbol(U(0x1D4AC), "ord", "mscrQ", "MATHEMATICAL SCRIPT CAPITAL Q", nil)
addSymbol(U(0x1D4AE), "ord", "mscrS", "MATHEMATICAL SCRIPT CAPITAL S", nil)
addSymbol(U(0x1D4AF), "ord", "mscrT", "MATHEMATICAL SCRIPT CAPITAL T", nil)
addSymbol(U(0x1D4B0), "ord", "mscrU", "MATHEMATICAL SCRIPT CAPITAL U", nil)
addSymbol(U(0x1D4B1), "ord", "mscrV", "MATHEMATICAL SCRIPT CAPITAL V", nil)
addSymbol(U(0x1D4B2), "ord", "mscrW", "MATHEMATICAL SCRIPT CAPITAL W", nil)
addSymbol(U(0x1D4B3), "ord", "mscrX", "MATHEMATICAL SCRIPT CAPITAL X", nil)
addSymbol(U(0x1D4B4), "ord", "mscrY", "MATHEMATICAL SCRIPT CAPITAL Y", nil)
addSymbol(U(0x1D4B5), "ord", "mscrZ", "MATHEMATICAL SCRIPT CAPITAL Z", nil)
addSymbol(U(0x1D4B6), "ord", "mscra", "MATHEMATICAL SCRIPT SMALL A", nil)
addSymbol(U(0x1D4B7), "ord", "mscrb", "MATHEMATICAL SCRIPT SMALL B", nil)
addSymbol(U(0x1D4B8), "ord", "mscrc", "MATHEMATICAL SCRIPT SMALL C", nil)
addSymbol(U(0x1D4B9), "ord", "mscrd", "MATHEMATICAL SCRIPT SMALL D", nil)
addSymbol(U(0x1D4BB), "ord", "mscrf", "MATHEMATICAL SCRIPT SMALL F", nil)
addSymbol(U(0x1D4BD), "ord", "mscrh", "MATHEMATICAL SCRIPT SMALL H", nil)
addSymbol(U(0x1D4BE), "ord", "mscri", "MATHEMATICAL SCRIPT SMALL I", nil)
addSymbol(U(0x1D4BF), "ord", "mscrj", "MATHEMATICAL SCRIPT SMALL J", nil)
addSymbol(U(0x1D4C0), "ord", "mscrk", "MATHEMATICAL SCRIPT SMALL K", nil)
addSymbol(U(0x1D4C1), "ord", "mscrl", "MATHEMATICAL SCRIPT SMALL L", nil)
addSymbol(U(0x1D4C2), "ord", "mscrm", "MATHEMATICAL SCRIPT SMALL M", nil)
addSymbol(U(0x1D4C3), "ord", "mscrn", "MATHEMATICAL SCRIPT SMALL N", nil)
addSymbol(U(0x1D4C5), "ord", "mscrp", "MATHEMATICAL SCRIPT SMALL P", nil)
addSymbol(U(0x1D4C6), "ord", "mscrq", "MATHEMATICAL SCRIPT SMALL Q", nil)
addSymbol(U(0x1D4C7), "ord", "mscrr", "MATHEMATICAL SCRIPT SMALL R", nil)
addSymbol(U(0x1D4C8), "ord", "mscrs", "MATHEMATICAL SCRIPT SMALL S", nil)
addSymbol(U(0x1D4C9), "ord", "mscrt", "MATHEMATICAL SCRIPT SMALL T", nil)
addSymbol(U(0x1D4CA), "ord", "mscru", "MATHEMATICAL SCRIPT SMALL U", nil)
addSymbol(U(0x1D4CB), "ord", "mscrv", "MATHEMATICAL SCRIPT SMALL V", nil)
addSymbol(U(0x1D4CC), "ord", "mscrw", "MATHEMATICAL SCRIPT SMALL W", nil)
addSymbol(U(0x1D4CD), "ord", "mscrx", "MATHEMATICAL SCRIPT SMALL X", nil)
addSymbol(U(0x1D4CE), "ord", "mscry", "MATHEMATICAL SCRIPT SMALL Y", nil)
addSymbol(U(0x1D4CF), "ord", "mscrz", "MATHEMATICAL SCRIPT SMALL Z", nil)
addSymbol(U(0x1D4D0), "ord", "mbfscrA", "MATHEMATICAL BOLD SCRIPT CAPITAL A", nil)
addSymbol(U(0x1D4D1), "ord", "mbfscrB", "MATHEMATICAL BOLD SCRIPT CAPITAL B", nil)
addSymbol(U(0x1D4D2), "ord", "mbfscrC", "MATHEMATICAL BOLD SCRIPT CAPITAL C", nil)
addSymbol(U(0x1D4D3), "ord", "mbfscrD", "MATHEMATICAL BOLD SCRIPT CAPITAL D", nil)
addSymbol(U(0x1D4D4), "ord", "mbfscrE", "MATHEMATICAL BOLD SCRIPT CAPITAL E", nil)
addSymbol(U(0x1D4D5), "ord", "mbfscrF", "MATHEMATICAL BOLD SCRIPT CAPITAL F", nil)
addSymbol(U(0x1D4D6), "ord", "mbfscrG", "MATHEMATICAL BOLD SCRIPT CAPITAL G", nil)
addSymbol(U(0x1D4D7), "ord", "mbfscrH", "MATHEMATICAL BOLD SCRIPT CAPITAL H", nil)
addSymbol(U(0x1D4D8), "ord", "mbfscrI", "MATHEMATICAL BOLD SCRIPT CAPITAL I", nil)
addSymbol(U(0x1D4D9), "ord", "mbfscrJ", "MATHEMATICAL BOLD SCRIPT CAPITAL J", nil)
addSymbol(U(0x1D4DA), "ord", "mbfscrK", "MATHEMATICAL BOLD SCRIPT CAPITAL K", nil)
addSymbol(U(0x1D4DB), "ord", "mbfscrL", "MATHEMATICAL BOLD SCRIPT CAPITAL L", nil)
addSymbol(U(0x1D4DC), "ord", "mbfscrM", "MATHEMATICAL BOLD SCRIPT CAPITAL M", nil)
addSymbol(U(0x1D4DD), "ord", "mbfscrN", "MATHEMATICAL BOLD SCRIPT CAPITAL N", nil)
addSymbol(U(0x1D4DE), "ord", "mbfscrO", "MATHEMATICAL BOLD SCRIPT CAPITAL O", nil)
addSymbol(U(0x1D4DF), "ord", "mbfscrP", "MATHEMATICAL BOLD SCRIPT CAPITAL P", nil)
addSymbol(U(0x1D4E0), "ord", "mbfscrQ", "MATHEMATICAL BOLD SCRIPT CAPITAL Q", nil)
addSymbol(U(0x1D4E1), "ord", "mbfscrR", "MATHEMATICAL BOLD SCRIPT CAPITAL R", nil)
addSymbol(U(0x1D4E2), "ord", "mbfscrS", "MATHEMATICAL BOLD SCRIPT CAPITAL S", nil)
addSymbol(U(0x1D4E3), "ord", "mbfscrT", "MATHEMATICAL BOLD SCRIPT CAPITAL T", nil)
addSymbol(U(0x1D4E4), "ord", "mbfscrU", "MATHEMATICAL BOLD SCRIPT CAPITAL U", nil)
addSymbol(U(0x1D4E5), "ord", "mbfscrV", "MATHEMATICAL BOLD SCRIPT CAPITAL V", nil)
addSymbol(U(0x1D4E6), "ord", "mbfscrW", "MATHEMATICAL BOLD SCRIPT CAPITAL W", nil)
addSymbol(U(0x1D4E7), "ord", "mbfscrX", "MATHEMATICAL BOLD SCRIPT CAPITAL X", nil)
addSymbol(U(0x1D4E8), "ord", "mbfscrY", "MATHEMATICAL BOLD SCRIPT CAPITAL Y", nil)
addSymbol(U(0x1D4E9), "ord", "mbfscrZ", "MATHEMATICAL BOLD SCRIPT CAPITAL Z", nil)
addSymbol(U(0x1D4EA), "ord", "mbfscra", "MATHEMATICAL BOLD SCRIPT SMALL A", nil)
addSymbol(U(0x1D4EB), "ord", "mbfscrb", "MATHEMATICAL BOLD SCRIPT SMALL B", nil)
addSymbol(U(0x1D4EC), "ord", "mbfscrc", "MATHEMATICAL BOLD SCRIPT SMALL C", nil)
addSymbol(U(0x1D4ED), "ord", "mbfscrd", "MATHEMATICAL BOLD SCRIPT SMALL D", nil)
addSymbol(U(0x1D4EE), "ord", "mbfscre", "MATHEMATICAL BOLD SCRIPT SMALL E", nil)
addSymbol(U(0x1D4EF), "ord", "mbfscrf", "MATHEMATICAL BOLD SCRIPT SMALL F", nil)
addSymbol(U(0x1D4F0), "ord", "mbfscrg", "MATHEMATICAL BOLD SCRIPT SMALL G", nil)
addSymbol(U(0x1D4F1), "ord", "mbfscrh", "MATHEMATICAL BOLD SCRIPT SMALL H", nil)
addSymbol(U(0x1D4F2), "ord", "mbfscri", "MATHEMATICAL BOLD SCRIPT SMALL I", nil)
addSymbol(U(0x1D4F3), "ord", "mbfscrj", "MATHEMATICAL BOLD SCRIPT SMALL J", nil)
addSymbol(U(0x1D4F4), "ord", "mbfscrk", "MATHEMATICAL BOLD SCRIPT SMALL K", nil)
addSymbol(U(0x1D4F5), "ord", "mbfscrl", "MATHEMATICAL BOLD SCRIPT SMALL L", nil)
addSymbol(U(0x1D4F6), "ord", "mbfscrm", "MATHEMATICAL BOLD SCRIPT SMALL M", nil)
addSymbol(U(0x1D4F7), "ord", "mbfscrn", "MATHEMATICAL BOLD SCRIPT SMALL N", nil)
addSymbol(U(0x1D4F8), "ord", "mbfscro", "MATHEMATICAL BOLD SCRIPT SMALL O", nil)
addSymbol(U(0x1D4F9), "ord", "mbfscrp", "MATHEMATICAL BOLD SCRIPT SMALL P", nil)
addSymbol(U(0x1D4FA), "ord", "mbfscrq", "MATHEMATICAL BOLD SCRIPT SMALL Q", nil)
addSymbol(U(0x1D4FB), "ord", "mbfscrr", "MATHEMATICAL BOLD SCRIPT SMALL R", nil)
addSymbol(U(0x1D4FC), "ord", "mbfscrs", "MATHEMATICAL BOLD SCRIPT SMALL S", nil)
addSymbol(U(0x1D4FD), "ord", "mbfscrt", "MATHEMATICAL BOLD SCRIPT SMALL T", nil)
addSymbol(U(0x1D4FE), "ord", "mbfscru", "MATHEMATICAL BOLD SCRIPT SMALL U", nil)
addSymbol(U(0x1D4FF), "ord", "mbfscrv", "MATHEMATICAL BOLD SCRIPT SMALL V", nil)
addSymbol(U(0x1D500), "ord", "mbfscrw", "MATHEMATICAL BOLD SCRIPT SMALL W", nil)
addSymbol(U(0x1D501), "ord", "mbfscrx", "MATHEMATICAL BOLD SCRIPT SMALL X", nil)
addSymbol(U(0x1D502), "ord", "mbfscry", "MATHEMATICAL BOLD SCRIPT SMALL Y", nil)
addSymbol(U(0x1D503), "ord", "mbfscrz", "MATHEMATICAL BOLD SCRIPT SMALL Z", nil)
addSymbol(U(0x1D504), "ord", "mfrakA", "MATHEMATICAL FRAKTUR CAPITAL A", nil)
addSymbol(U(0x1D505), "ord", "mfrakB", "MATHEMATICAL FRAKTUR CAPITAL B", nil)
addSymbol(U(0x1D507), "ord", "mfrakD", "MATHEMATICAL FRAKTUR CAPITAL D", nil)
addSymbol(U(0x1D508), "ord", "mfrakE", "MATHEMATICAL FRAKTUR CAPITAL E", nil)
addSymbol(U(0x1D509), "ord", "mfrakF", "MATHEMATICAL FRAKTUR CAPITAL F", nil)
addSymbol(U(0x1D50A), "ord", "mfrakG", "MATHEMATICAL FRAKTUR CAPITAL G", nil)
addSymbol(U(0x1D50D), "ord", "mfrakJ", "MATHEMATICAL FRAKTUR CAPITAL J", nil)
addSymbol(U(0x1D50E), "ord", "mfrakK", "MATHEMATICAL FRAKTUR CAPITAL K", nil)
addSymbol(U(0x1D50F), "ord", "mfrakL", "MATHEMATICAL FRAKTUR CAPITAL L", nil)
addSymbol(U(0x1D510), "ord", "mfrakM", "MATHEMATICAL FRAKTUR CAPITAL M", nil)
addSymbol(U(0x1D511), "ord", "mfrakN", "MATHEMATICAL FRAKTUR CAPITAL N", nil)
addSymbol(U(0x1D512), "ord", "mfrakO", "MATHEMATICAL FRAKTUR CAPITAL O", nil)
addSymbol(U(0x1D513), "ord", "mfrakP", "MATHEMATICAL FRAKTUR CAPITAL P", nil)
addSymbol(U(0x1D514), "ord", "mfrakQ", "MATHEMATICAL FRAKTUR CAPITAL Q", nil)
addSymbol(U(0x1D516), "ord", "mfrakS", "MATHEMATICAL FRAKTUR CAPITAL S", nil)
addSymbol(U(0x1D517), "ord", "mfrakT", "MATHEMATICAL FRAKTUR CAPITAL T", nil)
addSymbol(U(0x1D518), "ord", "mfrakU", "MATHEMATICAL FRAKTUR CAPITAL U", nil)
addSymbol(U(0x1D519), "ord", "mfrakV", "MATHEMATICAL FRAKTUR CAPITAL V", nil)
addSymbol(U(0x1D51A), "ord", "mfrakW", "MATHEMATICAL FRAKTUR CAPITAL W", nil)
addSymbol(U(0x1D51B), "ord", "mfrakX", "MATHEMATICAL FRAKTUR CAPITAL X", nil)
addSymbol(U(0x1D51C), "ord", "mfrakY", "MATHEMATICAL FRAKTUR CAPITAL Y", nil)
addSymbol(U(0x1D51E), "ord", "mfraka", "MATHEMATICAL FRAKTUR SMALL A", nil)
addSymbol(U(0x1D51F), "ord", "mfrakb", "MATHEMATICAL FRAKTUR SMALL B", nil)
addSymbol(U(0x1D520), "ord", "mfrakc", "MATHEMATICAL FRAKTUR SMALL C", nil)
addSymbol(U(0x1D521), "ord", "mfrakd", "MATHEMATICAL FRAKTUR SMALL D", nil)
addSymbol(U(0x1D522), "ord", "mfrake", "MATHEMATICAL FRAKTUR SMALL E", nil)
addSymbol(U(0x1D523), "ord", "mfrakf", "MATHEMATICAL FRAKTUR SMALL F", nil)
addSymbol(U(0x1D524), "ord", "mfrakg", "MATHEMATICAL FRAKTUR SMALL G", nil)
addSymbol(U(0x1D525), "ord", "mfrakh", "MATHEMATICAL FRAKTUR SMALL H", nil)
addSymbol(U(0x1D526), "ord", "mfraki", "MATHEMATICAL FRAKTUR SMALL I", nil)
addSymbol(U(0x1D527), "ord", "mfrakj", "MATHEMATICAL FRAKTUR SMALL J", nil)
addSymbol(U(0x1D528), "ord", "mfrakk", "MATHEMATICAL FRAKTUR SMALL K", nil)
addSymbol(U(0x1D529), "ord", "mfrakl", "MATHEMATICAL FRAKTUR SMALL L", nil)
addSymbol(U(0x1D52A), "ord", "mfrakm", "MATHEMATICAL FRAKTUR SMALL M", nil)
addSymbol(U(0x1D52B), "ord", "mfrakn", "MATHEMATICAL FRAKTUR SMALL N", nil)
addSymbol(U(0x1D52C), "ord", "mfrako", "MATHEMATICAL FRAKTUR SMALL O", nil)
addSymbol(U(0x1D52D), "ord", "mfrakp", "MATHEMATICAL FRAKTUR SMALL P", nil)
addSymbol(U(0x1D52E), "ord", "mfrakq", "MATHEMATICAL FRAKTUR SMALL Q", nil)
addSymbol(U(0x1D52F), "ord", "mfrakr", "MATHEMATICAL FRAKTUR SMALL R", nil)
addSymbol(U(0x1D530), "ord", "mfraks", "MATHEMATICAL FRAKTUR SMALL S", nil)
addSymbol(U(0x1D531), "ord", "mfrakt", "MATHEMATICAL FRAKTUR SMALL T", nil)
addSymbol(U(0x1D532), "ord", "mfraku", "MATHEMATICAL FRAKTUR SMALL U", nil)
addSymbol(U(0x1D533), "ord", "mfrakv", "MATHEMATICAL FRAKTUR SMALL V", nil)
addSymbol(U(0x1D534), "ord", "mfrakw", "MATHEMATICAL FRAKTUR SMALL W", nil)
addSymbol(U(0x1D535), "ord", "mfrakx", "MATHEMATICAL FRAKTUR SMALL X", nil)
addSymbol(U(0x1D536), "ord", "mfraky", "MATHEMATICAL FRAKTUR SMALL Y", nil)
addSymbol(U(0x1D537), "ord", "mfrakz", "MATHEMATICAL FRAKTUR SMALL Z", nil)
addSymbol(U(0x1D538), "ord", "BbbA", "MATHEMATICAL DOUBLE-STRUCK CAPITAL A", nil)
addSymbol(U(0x1D539), "ord", "BbbB", "MATHEMATICAL DOUBLE-STRUCK CAPITAL B", nil)
addSymbol(U(0x1D53B), "ord", "BbbD", "MATHEMATICAL DOUBLE-STRUCK CAPITAL D", nil)
addSymbol(U(0x1D53C), "ord", "BbbE", "MATHEMATICAL DOUBLE-STRUCK CAPITAL E", nil)
addSymbol(U(0x1D53D), "ord", "BbbF", "MATHEMATICAL DOUBLE-STRUCK CAPITAL F", nil)
addSymbol(U(0x1D53E), "ord", "BbbG", "MATHEMATICAL DOUBLE-STRUCK CAPITAL G", nil)
addSymbol(U(0x1D540), "ord", "BbbI", "MATHEMATICAL DOUBLE-STRUCK CAPITAL I", nil)
addSymbol(U(0x1D541), "ord", "BbbJ", "MATHEMATICAL DOUBLE-STRUCK CAPITAL J", nil)
addSymbol(U(0x1D542), "ord", "BbbK", "MATHEMATICAL DOUBLE-STRUCK CAPITAL K", nil)
addSymbol(U(0x1D543), "ord", "BbbL", "MATHEMATICAL DOUBLE-STRUCK CAPITAL L", nil)
addSymbol(U(0x1D544), "ord", "BbbM", "MATHEMATICAL DOUBLE-STRUCK CAPITAL M", nil)
addSymbol(U(0x1D546), "ord", "BbbO", "MATHEMATICAL DOUBLE-STRUCK CAPITAL O", nil)
addSymbol(U(0x1D54A), "ord", "BbbS", "MATHEMATICAL DOUBLE-STRUCK CAPITAL S", nil)
addSymbol(U(0x1D54B), "ord", "BbbT", "MATHEMATICAL DOUBLE-STRUCK CAPITAL T", nil)
addSymbol(U(0x1D54C), "ord", "BbbU", "MATHEMATICAL DOUBLE-STRUCK CAPITAL U", nil)
addSymbol(U(0x1D54D), "ord", "BbbV", "MATHEMATICAL DOUBLE-STRUCK CAPITAL V", nil)
addSymbol(U(0x1D54E), "ord", "BbbW", "MATHEMATICAL DOUBLE-STRUCK CAPITAL W", nil)
addSymbol(U(0x1D54F), "ord", "BbbX", "MATHEMATICAL DOUBLE-STRUCK CAPITAL X", nil)
addSymbol(U(0x1D550), "ord", "BbbY", "MATHEMATICAL DOUBLE-STRUCK CAPITAL Y", nil)
addSymbol(U(0x1D552), "ord", "Bbba", "MATHEMATICAL DOUBLE-STRUCK SMALL A", nil)
addSymbol(U(0x1D553), "ord", "Bbbb", "MATHEMATICAL DOUBLE-STRUCK SMALL B", nil)
addSymbol(U(0x1D554), "ord", "Bbbc", "MATHEMATICAL DOUBLE-STRUCK SMALL C", nil)
addSymbol(U(0x1D555), "ord", "Bbbd", "MATHEMATICAL DOUBLE-STRUCK SMALL D", nil)
addSymbol(U(0x1D556), "ord", "Bbbe", "MATHEMATICAL DOUBLE-STRUCK SMALL E", nil)
addSymbol(U(0x1D557), "ord", "Bbbf", "MATHEMATICAL DOUBLE-STRUCK SMALL F", nil)
addSymbol(U(0x1D558), "ord", "Bbbg", "MATHEMATICAL DOUBLE-STRUCK SMALL G", nil)
addSymbol(U(0x1D559), "ord", "Bbbh", "MATHEMATICAL DOUBLE-STRUCK SMALL H", nil)
addSymbol(U(0x1D55A), "ord", "Bbbi", "MATHEMATICAL DOUBLE-STRUCK SMALL I", nil)
addSymbol(U(0x1D55B), "ord", "Bbbj", "MATHEMATICAL DOUBLE-STRUCK SMALL J", nil)
addSymbol(U(0x1D55C), "ord", "Bbbk", "MATHEMATICAL DOUBLE-STRUCK SMALL K", nil)
addSymbol(U(0x1D55D), "ord", "Bbbl", "MATHEMATICAL DOUBLE-STRUCK SMALL L", nil)
addSymbol(U(0x1D55E), "ord", "Bbbm", "MATHEMATICAL DOUBLE-STRUCK SMALL M", nil)
addSymbol(U(0x1D55F), "ord", "Bbbn", "MATHEMATICAL DOUBLE-STRUCK SMALL N", nil)
addSymbol(U(0x1D560), "ord", "Bbbo", "MATHEMATICAL DOUBLE-STRUCK SMALL O", nil)
addSymbol(U(0x1D561), "ord", "Bbbp", "MATHEMATICAL DOUBLE-STRUCK SMALL P", nil)
addSymbol(U(0x1D562), "ord", "Bbbq", "MATHEMATICAL DOUBLE-STRUCK SMALL Q", nil)
addSymbol(U(0x1D563), "ord", "Bbbr", "MATHEMATICAL DOUBLE-STRUCK SMALL R", nil)
addSymbol(U(0x1D564), "ord", "Bbbs", "MATHEMATICAL DOUBLE-STRUCK SMALL S", nil)
addSymbol(U(0x1D565), "ord", "Bbbt", "MATHEMATICAL DOUBLE-STRUCK SMALL T", nil)
addSymbol(U(0x1D566), "ord", "Bbbu", "MATHEMATICAL DOUBLE-STRUCK SMALL U", nil)
addSymbol(U(0x1D567), "ord", "Bbbv", "MATHEMATICAL DOUBLE-STRUCK SMALL V", nil)
addSymbol(U(0x1D568), "ord", "Bbbw", "MATHEMATICAL DOUBLE-STRUCK SMALL W", nil)
addSymbol(U(0x1D569), "ord", "Bbbx", "MATHEMATICAL DOUBLE-STRUCK SMALL X", nil)
addSymbol(U(0x1D56A), "ord", "Bbby", "MATHEMATICAL DOUBLE-STRUCK SMALL Y", nil)
addSymbol(U(0x1D56B), "ord", "Bbbz", "MATHEMATICAL DOUBLE-STRUCK SMALL Z", nil)
addSymbol(U(0x1D56C), "ord", "mbffrakA", "MATHEMATICAL BOLD FRAKTUR CAPITAL A", nil)
addSymbol(U(0x1D56D), "ord", "mbffrakB", "MATHEMATICAL BOLD FRAKTUR CAPITAL B", nil)
addSymbol(U(0x1D56E), "ord", "mbffrakC", "MATHEMATICAL BOLD FRAKTUR CAPITAL C", nil)
addSymbol(U(0x1D56F), "ord", "mbffrakD", "MATHEMATICAL BOLD FRAKTUR CAPITAL D", nil)
addSymbol(U(0x1D570), "ord", "mbffrakE", "MATHEMATICAL BOLD FRAKTUR CAPITAL E", nil)
addSymbol(U(0x1D571), "ord", "mbffrakF", "MATHEMATICAL BOLD FRAKTUR CAPITAL F", nil)
addSymbol(U(0x1D572), "ord", "mbffrakG", "MATHEMATICAL BOLD FRAKTUR CAPITAL G", nil)
addSymbol(U(0x1D573), "ord", "mbffrakH", "MATHEMATICAL BOLD FRAKTUR CAPITAL H", nil)
addSymbol(U(0x1D574), "ord", "mbffrakI", "MATHEMATICAL BOLD FRAKTUR CAPITAL I", nil)
addSymbol(U(0x1D575), "ord", "mbffrakJ", "MATHEMATICAL BOLD FRAKTUR CAPITAL J", nil)
addSymbol(U(0x1D576), "ord", "mbffrakK", "MATHEMATICAL BOLD FRAKTUR CAPITAL K", nil)
addSymbol(U(0x1D577), "ord", "mbffrakL", "MATHEMATICAL BOLD FRAKTUR CAPITAL L", nil)
addSymbol(U(0x1D578), "ord", "mbffrakM", "MATHEMATICAL BOLD FRAKTUR CAPITAL M", nil)
addSymbol(U(0x1D579), "ord", "mbffrakN", "MATHEMATICAL BOLD FRAKTUR CAPITAL N", nil)
addSymbol(U(0x1D57A), "ord", "mbffrakO", "MATHEMATICAL BOLD FRAKTUR CAPITAL O", nil)
addSymbol(U(0x1D57B), "ord", "mbffrakP", "MATHEMATICAL BOLD FRAKTUR CAPITAL P", nil)
addSymbol(U(0x1D57C), "ord", "mbffrakQ", "MATHEMATICAL BOLD FRAKTUR CAPITAL Q", nil)
addSymbol(U(0x1D57D), "ord", "mbffrakR", "MATHEMATICAL BOLD FRAKTUR CAPITAL R", nil)
addSymbol(U(0x1D57E), "ord", "mbffrakS", "MATHEMATICAL BOLD FRAKTUR CAPITAL S", nil)
addSymbol(U(0x1D57F), "ord", "mbffrakT", "MATHEMATICAL BOLD FRAKTUR CAPITAL T", nil)
addSymbol(U(0x1D580), "ord", "mbffrakU", "MATHEMATICAL BOLD FRAKTUR CAPITAL U", nil)
addSymbol(U(0x1D581), "ord", "mbffrakV", "MATHEMATICAL BOLD FRAKTUR CAPITAL V", nil)
addSymbol(U(0x1D582), "ord", "mbffrakW", "MATHEMATICAL BOLD FRAKTUR CAPITAL W", nil)
addSymbol(U(0x1D583), "ord", "mbffrakX", "MATHEMATICAL BOLD FRAKTUR CAPITAL X", nil)
addSymbol(U(0x1D584), "ord", "mbffrakY", "MATHEMATICAL BOLD FRAKTUR CAPITAL Y", nil)
addSymbol(U(0x1D585), "ord", "mbffrakZ", "MATHEMATICAL BOLD FRAKTUR CAPITAL Z", nil)
addSymbol(U(0x1D586), "ord", "mbffraka", "MATHEMATICAL BOLD FRAKTUR SMALL A", nil)
addSymbol(U(0x1D587), "ord", "mbffrakb", "MATHEMATICAL BOLD FRAKTUR SMALL B", nil)
addSymbol(U(0x1D588), "ord", "mbffrakc", "MATHEMATICAL BOLD FRAKTUR SMALL C", nil)
addSymbol(U(0x1D589), "ord", "mbffrakd", "MATHEMATICAL BOLD FRAKTUR SMALL D", nil)
addSymbol(U(0x1D58A), "ord", "mbffrake", "MATHEMATICAL BOLD FRAKTUR SMALL E", nil)
addSymbol(U(0x1D58B), "ord", "mbffrakf", "MATHEMATICAL BOLD FRAKTUR SMALL F", nil)
addSymbol(U(0x1D58C), "ord", "mbffrakg", "MATHEMATICAL BOLD FRAKTUR SMALL G", nil)
addSymbol(U(0x1D58D), "ord", "mbffrakh", "MATHEMATICAL BOLD FRAKTUR SMALL H", nil)
addSymbol(U(0x1D58E), "ord", "mbffraki", "MATHEMATICAL BOLD FRAKTUR SMALL I", nil)
addSymbol(U(0x1D58F), "ord", "mbffrakj", "MATHEMATICAL BOLD FRAKTUR SMALL J", nil)
addSymbol(U(0x1D590), "ord", "mbffrakk", "MATHEMATICAL BOLD FRAKTUR SMALL K", nil)
addSymbol(U(0x1D591), "ord", "mbffrakl", "MATHEMATICAL BOLD FRAKTUR SMALL L", nil)
addSymbol(U(0x1D592), "ord", "mbffrakm", "MATHEMATICAL BOLD FRAKTUR SMALL M", nil)
addSymbol(U(0x1D593), "ord", "mbffrakn", "MATHEMATICAL BOLD FRAKTUR SMALL N", nil)
addSymbol(U(0x1D594), "ord", "mbffrako", "MATHEMATICAL BOLD FRAKTUR SMALL O", nil)
addSymbol(U(0x1D595), "ord", "mbffrakp", "MATHEMATICAL BOLD FRAKTUR SMALL P", nil)
addSymbol(U(0x1D596), "ord", "mbffrakq", "MATHEMATICAL BOLD FRAKTUR SMALL Q", nil)
addSymbol(U(0x1D597), "ord", "mbffrakr", "MATHEMATICAL BOLD FRAKTUR SMALL R", nil)
addSymbol(U(0x1D598), "ord", "mbffraks", "MATHEMATICAL BOLD FRAKTUR SMALL S", nil)
addSymbol(U(0x1D599), "ord", "mbffrakt", "MATHEMATICAL BOLD FRAKTUR SMALL T", nil)
addSymbol(U(0x1D59A), "ord", "mbffraku", "MATHEMATICAL BOLD FRAKTUR SMALL U", nil)
addSymbol(U(0x1D59B), "ord", "mbffrakv", "MATHEMATICAL BOLD FRAKTUR SMALL V", nil)
addSymbol(U(0x1D59C), "ord", "mbffrakw", "MATHEMATICAL BOLD FRAKTUR SMALL W", nil)
addSymbol(U(0x1D59D), "ord", "mbffrakx", "MATHEMATICAL BOLD FRAKTUR SMALL X", nil)
addSymbol(U(0x1D59E), "ord", "mbffraky", "MATHEMATICAL BOLD FRAKTUR SMALL Y", nil)
addSymbol(U(0x1D59F), "ord", "mbffrakz", "MATHEMATICAL BOLD FRAKTUR SMALL Z", nil)
addSymbol(U(0x1D5A0), "ord", "msansA", "MATHEMATICAL SANS-SERIF CAPITAL A", nil)
addSymbol(U(0x1D5A1), "ord", "msansB", "MATHEMATICAL SANS-SERIF CAPITAL B", nil)
addSymbol(U(0x1D5A2), "ord", "msansC", "MATHEMATICAL SANS-SERIF CAPITAL C", nil)
addSymbol(U(0x1D5A3), "ord", "msansD", "MATHEMATICAL SANS-SERIF CAPITAL D", nil)
addSymbol(U(0x1D5A4), "ord", "msansE", "MATHEMATICAL SANS-SERIF CAPITAL E", nil)
addSymbol(U(0x1D5A5), "ord", "msansF", "MATHEMATICAL SANS-SERIF CAPITAL F", nil)
addSymbol(U(0x1D5A6), "ord", "msansG", "MATHEMATICAL SANS-SERIF CAPITAL G", nil)
addSymbol(U(0x1D5A7), "ord", "msansH", "MATHEMATICAL SANS-SERIF CAPITAL H", nil)
addSymbol(U(0x1D5A8), "ord", "msansI", "MATHEMATICAL SANS-SERIF CAPITAL I", nil)
addSymbol(U(0x1D5A9), "ord", "msansJ", "MATHEMATICAL SANS-SERIF CAPITAL J", nil)
addSymbol(U(0x1D5AA), "ord", "msansK", "MATHEMATICAL SANS-SERIF CAPITAL K", nil)
addSymbol(U(0x1D5AB), "ord", "msansL", "MATHEMATICAL SANS-SERIF CAPITAL L", nil)
addSymbol(U(0x1D5AC), "ord", "msansM", "MATHEMATICAL SANS-SERIF CAPITAL M", nil)
addSymbol(U(0x1D5AD), "ord", "msansN", "MATHEMATICAL SANS-SERIF CAPITAL N", nil)
addSymbol(U(0x1D5AE), "ord", "msansO", "MATHEMATICAL SANS-SERIF CAPITAL O", nil)
addSymbol(U(0x1D5AF), "ord", "msansP", "MATHEMATICAL SANS-SERIF CAPITAL P", nil)
addSymbol(U(0x1D5B0), "ord", "msansQ", "MATHEMATICAL SANS-SERIF CAPITAL Q", nil)
addSymbol(U(0x1D5B1), "ord", "msansR", "MATHEMATICAL SANS-SERIF CAPITAL R", nil)
addSymbol(U(0x1D5B2), "ord", "msansS", "MATHEMATICAL SANS-SERIF CAPITAL S", nil)
addSymbol(U(0x1D5B3), "ord", "msansT", "MATHEMATICAL SANS-SERIF CAPITAL T", nil)
addSymbol(U(0x1D5B4), "ord", "msansU", "MATHEMATICAL SANS-SERIF CAPITAL U", nil)
addSymbol(U(0x1D5B5), "ord", "msansV", "MATHEMATICAL SANS-SERIF CAPITAL V", nil)
addSymbol(U(0x1D5B6), "ord", "msansW", "MATHEMATICAL SANS-SERIF CAPITAL W", nil)
addSymbol(U(0x1D5B7), "ord", "msansX", "MATHEMATICAL SANS-SERIF CAPITAL X", nil)
addSymbol(U(0x1D5B8), "ord", "msansY", "MATHEMATICAL SANS-SERIF CAPITAL Y", nil)
addSymbol(U(0x1D5B9), "ord", "msansZ", "MATHEMATICAL SANS-SERIF CAPITAL Z", nil)
addSymbol(U(0x1D5BA), "ord", "msansa", "MATHEMATICAL SANS-SERIF SMALL A", nil)
addSymbol(U(0x1D5BB), "ord", "msansb", "MATHEMATICAL SANS-SERIF SMALL B", nil)
addSymbol(U(0x1D5BC), "ord", "msansc", "MATHEMATICAL SANS-SERIF SMALL C", nil)
addSymbol(U(0x1D5BD), "ord", "msansd", "MATHEMATICAL SANS-SERIF SMALL D", nil)
addSymbol(U(0x1D5BE), "ord", "msanse", "MATHEMATICAL SANS-SERIF SMALL E", nil)
addSymbol(U(0x1D5BF), "ord", "msansf", "MATHEMATICAL SANS-SERIF SMALL F", nil)
addSymbol(U(0x1D5C0), "ord", "msansg", "MATHEMATICAL SANS-SERIF SMALL G", nil)
addSymbol(U(0x1D5C1), "ord", "msansh", "MATHEMATICAL SANS-SERIF SMALL H", nil)
addSymbol(U(0x1D5C2), "ord", "msansi", "MATHEMATICAL SANS-SERIF SMALL I", nil)
addSymbol(U(0x1D5C3), "ord", "msansj", "MATHEMATICAL SANS-SERIF SMALL J", nil)
addSymbol(U(0x1D5C4), "ord", "msansk", "MATHEMATICAL SANS-SERIF SMALL K", nil)
addSymbol(U(0x1D5C5), "ord", "msansl", "MATHEMATICAL SANS-SERIF SMALL L", nil)
addSymbol(U(0x1D5C6), "ord", "msansm", "MATHEMATICAL SANS-SERIF SMALL M", nil)
addSymbol(U(0x1D5C7), "ord", "msansn", "MATHEMATICAL SANS-SERIF SMALL N", nil)
addSymbol(U(0x1D5C8), "ord", "msanso", "MATHEMATICAL SANS-SERIF SMALL O", nil)
addSymbol(U(0x1D5C9), "ord", "msansp", "MATHEMATICAL SANS-SERIF SMALL P", nil)
addSymbol(U(0x1D5CA), "ord", "msansq", "MATHEMATICAL SANS-SERIF SMALL Q", nil)
addSymbol(U(0x1D5CB), "ord", "msansr", "MATHEMATICAL SANS-SERIF SMALL R", nil)
addSymbol(U(0x1D5CC), "ord", "msanss", "MATHEMATICAL SANS-SERIF SMALL S", nil)
addSymbol(U(0x1D5CD), "ord", "msanst", "MATHEMATICAL SANS-SERIF SMALL T", nil)
addSymbol(U(0x1D5CE), "ord", "msansu", "MATHEMATICAL SANS-SERIF SMALL U", nil)
addSymbol(U(0x1D5CF), "ord", "msansv", "MATHEMATICAL SANS-SERIF SMALL V", nil)
addSymbol(U(0x1D5D0), "ord", "msansw", "MATHEMATICAL SANS-SERIF SMALL W", nil)
addSymbol(U(0x1D5D1), "ord", "msansx", "MATHEMATICAL SANS-SERIF SMALL X", nil)
addSymbol(U(0x1D5D2), "ord", "msansy", "MATHEMATICAL SANS-SERIF SMALL Y", nil)
addSymbol(U(0x1D5D3), "ord", "msansz", "MATHEMATICAL SANS-SERIF SMALL Z", nil)
addSymbol(U(0x1D5D4), "ord", "mbfsansA", "MATHEMATICAL SANS-SERIF BOLD CAPITAL A", nil)
addSymbol(U(0x1D5D5), "ord", "mbfsansB", "MATHEMATICAL SANS-SERIF BOLD CAPITAL B", nil)
addSymbol(U(0x1D5D6), "ord", "mbfsansC", "MATHEMATICAL SANS-SERIF BOLD CAPITAL C", nil)
addSymbol(U(0x1D5D7), "ord", "mbfsansD", "MATHEMATICAL SANS-SERIF BOLD CAPITAL D", nil)
addSymbol(U(0x1D5D8), "ord", "mbfsansE", "MATHEMATICAL SANS-SERIF BOLD CAPITAL E", nil)
addSymbol(U(0x1D5D9), "ord", "mbfsansF", "MATHEMATICAL SANS-SERIF BOLD CAPITAL F", nil)
addSymbol(U(0x1D5DA), "ord", "mbfsansG", "MATHEMATICAL SANS-SERIF BOLD CAPITAL G", nil)
addSymbol(U(0x1D5DB), "ord", "mbfsansH", "MATHEMATICAL SANS-SERIF BOLD CAPITAL H", nil)
addSymbol(U(0x1D5DC), "ord", "mbfsansI", "MATHEMATICAL SANS-SERIF BOLD CAPITAL I", nil)
addSymbol(U(0x1D5DD), "ord", "mbfsansJ", "MATHEMATICAL SANS-SERIF BOLD CAPITAL J", nil)
addSymbol(U(0x1D5DE), "ord", "mbfsansK", "MATHEMATICAL SANS-SERIF BOLD CAPITAL K", nil)
addSymbol(U(0x1D5DF), "ord", "mbfsansL", "MATHEMATICAL SANS-SERIF BOLD CAPITAL L", nil)
addSymbol(U(0x1D5E0), "ord", "mbfsansM", "MATHEMATICAL SANS-SERIF BOLD CAPITAL M", nil)
addSymbol(U(0x1D5E1), "ord", "mbfsansN", "MATHEMATICAL SANS-SERIF BOLD CAPITAL N", nil)
addSymbol(U(0x1D5E2), "ord", "mbfsansO", "MATHEMATICAL SANS-SERIF BOLD CAPITAL O", nil)
addSymbol(U(0x1D5E3), "ord", "mbfsansP", "MATHEMATICAL SANS-SERIF BOLD CAPITAL P", nil)
addSymbol(U(0x1D5E4), "ord", "mbfsansQ", "MATHEMATICAL SANS-SERIF BOLD CAPITAL Q", nil)
addSymbol(U(0x1D5E5), "ord", "mbfsansR", "MATHEMATICAL SANS-SERIF BOLD CAPITAL R", nil)
addSymbol(U(0x1D5E6), "ord", "mbfsansS", "MATHEMATICAL SANS-SERIF BOLD CAPITAL S", nil)
addSymbol(U(0x1D5E7), "ord", "mbfsansT", "MATHEMATICAL SANS-SERIF BOLD CAPITAL T", nil)
addSymbol(U(0x1D5E8), "ord", "mbfsansU", "MATHEMATICAL SANS-SERIF BOLD CAPITAL U", nil)
addSymbol(U(0x1D5E9), "ord", "mbfsansV", "MATHEMATICAL SANS-SERIF BOLD CAPITAL V", nil)
addSymbol(U(0x1D5EA), "ord", "mbfsansW", "MATHEMATICAL SANS-SERIF BOLD CAPITAL W", nil)
addSymbol(U(0x1D5EB), "ord", "mbfsansX", "MATHEMATICAL SANS-SERIF BOLD CAPITAL X", nil)
addSymbol(U(0x1D5EC), "ord", "mbfsansY", "MATHEMATICAL SANS-SERIF BOLD CAPITAL Y", nil)
addSymbol(U(0x1D5ED), "ord", "mbfsansZ", "MATHEMATICAL SANS-SERIF BOLD CAPITAL Z", nil)
addSymbol(U(0x1D5EE), "ord", "mbfsansa", "MATHEMATICAL SANS-SERIF BOLD SMALL A", nil)
addSymbol(U(0x1D5EF), "ord", "mbfsansb", "MATHEMATICAL SANS-SERIF BOLD SMALL B", nil)
addSymbol(U(0x1D5F0), "ord", "mbfsansc", "MATHEMATICAL SANS-SERIF BOLD SMALL C", nil)
addSymbol(U(0x1D5F1), "ord", "mbfsansd", "MATHEMATICAL SANS-SERIF BOLD SMALL D", nil)
addSymbol(U(0x1D5F2), "ord", "mbfsanse", "MATHEMATICAL SANS-SERIF BOLD SMALL E", nil)
addSymbol(U(0x1D5F3), "ord", "mbfsansf", "MATHEMATICAL SANS-SERIF BOLD SMALL F", nil)
addSymbol(U(0x1D5F4), "ord", "mbfsansg", "MATHEMATICAL SANS-SERIF BOLD SMALL G", nil)
addSymbol(U(0x1D5F5), "ord", "mbfsansh", "MATHEMATICAL SANS-SERIF BOLD SMALL H", nil)
addSymbol(U(0x1D5F6), "ord", "mbfsansi", "MATHEMATICAL SANS-SERIF BOLD SMALL I", nil)
addSymbol(U(0x1D5F7), "ord", "mbfsansj", "MATHEMATICAL SANS-SERIF BOLD SMALL J", nil)
addSymbol(U(0x1D5F8), "ord", "mbfsansk", "MATHEMATICAL SANS-SERIF BOLD SMALL K", nil)
addSymbol(U(0x1D5F9), "ord", "mbfsansl", "MATHEMATICAL SANS-SERIF BOLD SMALL L", nil)
addSymbol(U(0x1D5FA), "ord", "mbfsansm", "MATHEMATICAL SANS-SERIF BOLD SMALL M", nil)
addSymbol(U(0x1D5FB), "ord", "mbfsansn", "MATHEMATICAL SANS-SERIF BOLD SMALL N", nil)
addSymbol(U(0x1D5FC), "ord", "mbfsanso", "MATHEMATICAL SANS-SERIF BOLD SMALL O", nil)
addSymbol(U(0x1D5FD), "ord", "mbfsansp", "MATHEMATICAL SANS-SERIF BOLD SMALL P", nil)
addSymbol(U(0x1D5FE), "ord", "mbfsansq", "MATHEMATICAL SANS-SERIF BOLD SMALL Q", nil)
addSymbol(U(0x1D5FF), "ord", "mbfsansr", "MATHEMATICAL SANS-SERIF BOLD SMALL R", nil)
addSymbol(U(0x1D600), "ord", "mbfsanss", "MATHEMATICAL SANS-SERIF BOLD SMALL S", nil)
addSymbol(U(0x1D601), "ord", "mbfsanst", "MATHEMATICAL SANS-SERIF BOLD SMALL T", nil)
addSymbol(U(0x1D602), "ord", "mbfsansu", "MATHEMATICAL SANS-SERIF BOLD SMALL U", nil)
addSymbol(U(0x1D603), "ord", "mbfsansv", "MATHEMATICAL SANS-SERIF BOLD SMALL V", nil)
addSymbol(U(0x1D604), "ord", "mbfsansw", "MATHEMATICAL SANS-SERIF BOLD SMALL W", nil)
addSymbol(U(0x1D605), "ord", "mbfsansx", "MATHEMATICAL SANS-SERIF BOLD SMALL X", nil)
addSymbol(U(0x1D606), "ord", "mbfsansy", "MATHEMATICAL SANS-SERIF BOLD SMALL Y", nil)
addSymbol(U(0x1D607), "ord", "mbfsansz", "MATHEMATICAL SANS-SERIF BOLD SMALL Z", nil)
addSymbol(U(0x1D608), "ord", "mitsansA", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL A", nil)
addSymbol(U(0x1D609), "ord", "mitsansB", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL B", nil)
addSymbol(U(0x1D60A), "ord", "mitsansC", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL C", nil)
addSymbol(U(0x1D60B), "ord", "mitsansD", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL D", nil)
addSymbol(U(0x1D60C), "ord", "mitsansE", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL E", nil)
addSymbol(U(0x1D60D), "ord", "mitsansF", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL F", nil)
addSymbol(U(0x1D60E), "ord", "mitsansG", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL G", nil)
addSymbol(U(0x1D60F), "ord", "mitsansH", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL H", nil)
addSymbol(U(0x1D610), "ord", "mitsansI", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL I", nil)
addSymbol(U(0x1D611), "ord", "mitsansJ", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL J", nil)
addSymbol(U(0x1D612), "ord", "mitsansK", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL K", nil)
addSymbol(U(0x1D613), "ord", "mitsansL", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL L", nil)
addSymbol(U(0x1D614), "ord", "mitsansM", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL M", nil)
addSymbol(U(0x1D615), "ord", "mitsansN", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL N", nil)
addSymbol(U(0x1D616), "ord", "mitsansO", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL O", nil)
addSymbol(U(0x1D617), "ord", "mitsansP", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL P", nil)
addSymbol(U(0x1D618), "ord", "mitsansQ", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL Q", nil)
addSymbol(U(0x1D619), "ord", "mitsansR", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL R", nil)
addSymbol(U(0x1D61A), "ord", "mitsansS", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL S", nil)
addSymbol(U(0x1D61B), "ord", "mitsansT", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL T", nil)
addSymbol(U(0x1D61C), "ord", "mitsansU", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL U", nil)
addSymbol(U(0x1D61D), "ord", "mitsansV", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL V", nil)
addSymbol(U(0x1D61E), "ord", "mitsansW", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL W", nil)
addSymbol(U(0x1D61F), "ord", "mitsansX", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL X", nil)
addSymbol(U(0x1D620), "ord", "mitsansY", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL Y", nil)
addSymbol(U(0x1D621), "ord", "mitsansZ", "MATHEMATICAL SANS-SERIF ITALIC CAPITAL Z", nil)
addSymbol(U(0x1D622), "ord", "mitsansa", "MATHEMATICAL SANS-SERIF ITALIC SMALL A", nil)
addSymbol(U(0x1D623), "ord", "mitsansb", "MATHEMATICAL SANS-SERIF ITALIC SMALL B", nil)
addSymbol(U(0x1D624), "ord", "mitsansc", "MATHEMATICAL SANS-SERIF ITALIC SMALL C", nil)
addSymbol(U(0x1D625), "ord", "mitsansd", "MATHEMATICAL SANS-SERIF ITALIC SMALL D", nil)
addSymbol(U(0x1D626), "ord", "mitsanse", "MATHEMATICAL SANS-SERIF ITALIC SMALL E", nil)
addSymbol(U(0x1D627), "ord", "mitsansf", "MATHEMATICAL SANS-SERIF ITALIC SMALL F", nil)
addSymbol(U(0x1D628), "ord", "mitsansg", "MATHEMATICAL SANS-SERIF ITALIC SMALL G", nil)
addSymbol(U(0x1D629), "ord", "mitsansh", "MATHEMATICAL SANS-SERIF ITALIC SMALL H", nil)
addSymbol(U(0x1D62A), "ord", "mitsansi", "MATHEMATICAL SANS-SERIF ITALIC SMALL I", nil)
addSymbol(U(0x1D62B), "ord", "mitsansj", "MATHEMATICAL SANS-SERIF ITALIC SMALL J", nil)
addSymbol(U(0x1D62C), "ord", "mitsansk", "MATHEMATICAL SANS-SERIF ITALIC SMALL K", nil)
addSymbol(U(0x1D62D), "ord", "mitsansl", "MATHEMATICAL SANS-SERIF ITALIC SMALL L", nil)
addSymbol(U(0x1D62E), "ord", "mitsansm", "MATHEMATICAL SANS-SERIF ITALIC SMALL M", nil)
addSymbol(U(0x1D62F), "ord", "mitsansn", "MATHEMATICAL SANS-SERIF ITALIC SMALL N", nil)
addSymbol(U(0x1D630), "ord", "mitsanso", "MATHEMATICAL SANS-SERIF ITALIC SMALL O", nil)
addSymbol(U(0x1D631), "ord", "mitsansp", "MATHEMATICAL SANS-SERIF ITALIC SMALL P", nil)
addSymbol(U(0x1D632), "ord", "mitsansq", "MATHEMATICAL SANS-SERIF ITALIC SMALL Q", nil)
addSymbol(U(0x1D633), "ord", "mitsansr", "MATHEMATICAL SANS-SERIF ITALIC SMALL R", nil)
addSymbol(U(0x1D634), "ord", "mitsanss", "MATHEMATICAL SANS-SERIF ITALIC SMALL S", nil)
addSymbol(U(0x1D635), "ord", "mitsanst", "MATHEMATICAL SANS-SERIF ITALIC SMALL T", nil)
addSymbol(U(0x1D636), "ord", "mitsansu", "MATHEMATICAL SANS-SERIF ITALIC SMALL U", nil)
addSymbol(U(0x1D637), "ord", "mitsansv", "MATHEMATICAL SANS-SERIF ITALIC SMALL V", nil)
addSymbol(U(0x1D638), "ord", "mitsansw", "MATHEMATICAL SANS-SERIF ITALIC SMALL W", nil)
addSymbol(U(0x1D639), "ord", "mitsansx", "MATHEMATICAL SANS-SERIF ITALIC SMALL X", nil)
addSymbol(U(0x1D63A), "ord", "mitsansy", "MATHEMATICAL SANS-SERIF ITALIC SMALL Y", nil)
addSymbol(U(0x1D63B), "ord", "mitsansz", "MATHEMATICAL SANS-SERIF ITALIC SMALL Z", nil)
addSymbol(U(0x1D63C), "ord", "mbfitsansA", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL A", nil)
addSymbol(U(0x1D63D), "ord", "mbfitsansB", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL B", nil)
addSymbol(U(0x1D63E), "ord", "mbfitsansC", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL C", nil)
addSymbol(U(0x1D63F), "ord", "mbfitsansD", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL D", nil)
addSymbol(U(0x1D640), "ord", "mbfitsansE", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL E", nil)
addSymbol(U(0x1D641), "ord", "mbfitsansF", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL F", nil)
addSymbol(U(0x1D642), "ord", "mbfitsansG", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL G", nil)
addSymbol(U(0x1D643), "ord", "mbfitsansH", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL H", nil)
addSymbol(U(0x1D644), "ord", "mbfitsansI", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL I", nil)
addSymbol(U(0x1D645), "ord", "mbfitsansJ", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL J", nil)
addSymbol(U(0x1D646), "ord", "mbfitsansK", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL K", nil)
addSymbol(U(0x1D647), "ord", "mbfitsansL", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL L", nil)
addSymbol(U(0x1D648), "ord", "mbfitsansM", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL M", nil)
addSymbol(U(0x1D649), "ord", "mbfitsansN", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL N", nil)
addSymbol(U(0x1D64A), "ord", "mbfitsansO", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL O", nil)
addSymbol(U(0x1D64B), "ord", "mbfitsansP", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL P", nil)
addSymbol(U(0x1D64C), "ord", "mbfitsansQ", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL Q", nil)
addSymbol(U(0x1D64D), "ord", "mbfitsansR", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL R", nil)
addSymbol(U(0x1D64E), "ord", "mbfitsansS", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL S", nil)
addSymbol(U(0x1D64F), "ord", "mbfitsansT", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL T", nil)
addSymbol(U(0x1D650), "ord", "mbfitsansU", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL U", nil)
addSymbol(U(0x1D651), "ord", "mbfitsansV", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL V", nil)
addSymbol(U(0x1D652), "ord", "mbfitsansW", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL W", nil)
addSymbol(U(0x1D653), "ord", "mbfitsansX", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL X", nil)
addSymbol(U(0x1D654), "ord", "mbfitsansY", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL Y", nil)
addSymbol(U(0x1D655), "ord", "mbfitsansZ", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL Z", nil)
addSymbol(U(0x1D656), "ord", "mbfitsansa", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL A", nil)
addSymbol(U(0x1D657), "ord", "mbfitsansb", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL B", nil)
addSymbol(U(0x1D658), "ord", "mbfitsansc", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL C", nil)
addSymbol(U(0x1D659), "ord", "mbfitsansd", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL D", nil)
addSymbol(U(0x1D65A), "ord", "mbfitsanse", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL E", nil)
addSymbol(U(0x1D65B), "ord", "mbfitsansf", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL F", nil)
addSymbol(U(0x1D65C), "ord", "mbfitsansg", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL G", nil)
addSymbol(U(0x1D65D), "ord", "mbfitsansh", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL H", nil)
addSymbol(U(0x1D65E), "ord", "mbfitsansi", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL I", nil)
addSymbol(U(0x1D65F), "ord", "mbfitsansj", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL J", nil)
addSymbol(U(0x1D660), "ord", "mbfitsansk", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL K", nil)
addSymbol(U(0x1D661), "ord", "mbfitsansl", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL L", nil)
addSymbol(U(0x1D662), "ord", "mbfitsansm", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL M", nil)
addSymbol(U(0x1D663), "ord", "mbfitsansn", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL N", nil)
addSymbol(U(0x1D664), "ord", "mbfitsanso", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL O", nil)
addSymbol(U(0x1D665), "ord", "mbfitsansp", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL P", nil)
addSymbol(U(0x1D666), "ord", "mbfitsansq", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL Q", nil)
addSymbol(U(0x1D667), "ord", "mbfitsansr", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL R", nil)
addSymbol(U(0x1D668), "ord", "mbfitsanss", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL S", nil)
addSymbol(U(0x1D669), "ord", "mbfitsanst", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL T", nil)
addSymbol(U(0x1D66A), "ord", "mbfitsansu", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL U", nil)
addSymbol(U(0x1D66B), "ord", "mbfitsansv", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL V", nil)
addSymbol(U(0x1D66C), "ord", "mbfitsansw", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL W", nil)
addSymbol(U(0x1D66D), "ord", "mbfitsansx", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL X", nil)
addSymbol(U(0x1D66E), "ord", "mbfitsansy", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL Y", nil)
addSymbol(U(0x1D66F), "ord", "mbfitsansz", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL Z", nil)
addSymbol(U(0x1D670), "ord", "mttA", "MATHEMATICAL MONOSPACE CAPITAL A", nil)
addSymbol(U(0x1D671), "ord", "mttB", "MATHEMATICAL MONOSPACE CAPITAL B", nil)
addSymbol(U(0x1D672), "ord", "mttC", "MATHEMATICAL MONOSPACE CAPITAL C", nil)
addSymbol(U(0x1D673), "ord", "mttD", "MATHEMATICAL MONOSPACE CAPITAL D", nil)
addSymbol(U(0x1D674), "ord", "mttE", "MATHEMATICAL MONOSPACE CAPITAL E", nil)
addSymbol(U(0x1D675), "ord", "mttF", "MATHEMATICAL MONOSPACE CAPITAL F", nil)
addSymbol(U(0x1D676), "ord", "mttG", "MATHEMATICAL MONOSPACE CAPITAL G", nil)
addSymbol(U(0x1D677), "ord", "mttH", "MATHEMATICAL MONOSPACE CAPITAL H", nil)
addSymbol(U(0x1D678), "ord", "mttI", "MATHEMATICAL MONOSPACE CAPITAL I", nil)
addSymbol(U(0x1D679), "ord", "mttJ", "MATHEMATICAL MONOSPACE CAPITAL J", nil)
addSymbol(U(0x1D67A), "ord", "mttK", "MATHEMATICAL MONOSPACE CAPITAL K", nil)
addSymbol(U(0x1D67B), "ord", "mttL", "MATHEMATICAL MONOSPACE CAPITAL L", nil)
addSymbol(U(0x1D67C), "ord", "mttM", "MATHEMATICAL MONOSPACE CAPITAL M", nil)
addSymbol(U(0x1D67D), "ord", "mttN", "MATHEMATICAL MONOSPACE CAPITAL N", nil)
addSymbol(U(0x1D67E), "ord", "mttO", "MATHEMATICAL MONOSPACE CAPITAL O", nil)
addSymbol(U(0x1D67F), "ord", "mttP", "MATHEMATICAL MONOSPACE CAPITAL P", nil)
addSymbol(U(0x1D680), "ord", "mttQ", "MATHEMATICAL MONOSPACE CAPITAL Q", nil)
addSymbol(U(0x1D681), "ord", "mttR", "MATHEMATICAL MONOSPACE CAPITAL R", nil)
addSymbol(U(0x1D682), "ord", "mttS", "MATHEMATICAL MONOSPACE CAPITAL S", nil)
addSymbol(U(0x1D683), "ord", "mttT", "MATHEMATICAL MONOSPACE CAPITAL T", nil)
addSymbol(U(0x1D684), "ord", "mttU", "MATHEMATICAL MONOSPACE CAPITAL U", nil)
addSymbol(U(0x1D685), "ord", "mttV", "MATHEMATICAL MONOSPACE CAPITAL V", nil)
addSymbol(U(0x1D686), "ord", "mttW", "MATHEMATICAL MONOSPACE CAPITAL W", nil)
addSymbol(U(0x1D687), "ord", "mttX", "MATHEMATICAL MONOSPACE CAPITAL X", nil)
addSymbol(U(0x1D688), "ord", "mttY", "MATHEMATICAL MONOSPACE CAPITAL Y", nil)
addSymbol(U(0x1D689), "ord", "mttZ", "MATHEMATICAL MONOSPACE CAPITAL Z", nil)
addSymbol(U(0x1D68A), "ord", "mtta", "MATHEMATICAL MONOSPACE SMALL A", nil)
addSymbol(U(0x1D68B), "ord", "mttb", "MATHEMATICAL MONOSPACE SMALL B", nil)
addSymbol(U(0x1D68C), "ord", "mttc", "MATHEMATICAL MONOSPACE SMALL C", nil)
addSymbol(U(0x1D68D), "ord", "mttd", "MATHEMATICAL MONOSPACE SMALL D", nil)
addSymbol(U(0x1D68E), "ord", "mtte", "MATHEMATICAL MONOSPACE SMALL E", nil)
addSymbol(U(0x1D68F), "ord", "mttf", "MATHEMATICAL MONOSPACE SMALL F", nil)
addSymbol(U(0x1D690), "ord", "mttg", "MATHEMATICAL MONOSPACE SMALL G", nil)
addSymbol(U(0x1D691), "ord", "mtth", "MATHEMATICAL MONOSPACE SMALL H", nil)
addSymbol(U(0x1D692), "ord", "mtti", "MATHEMATICAL MONOSPACE SMALL I", nil)
addSymbol(U(0x1D693), "ord", "mttj", "MATHEMATICAL MONOSPACE SMALL J", nil)
addSymbol(U(0x1D694), "ord", "mttk", "MATHEMATICAL MONOSPACE SMALL K", nil)
addSymbol(U(0x1D695), "ord", "mttl", "MATHEMATICAL MONOSPACE SMALL L", nil)
addSymbol(U(0x1D696), "ord", "mttm", "MATHEMATICAL MONOSPACE SMALL M", nil)
addSymbol(U(0x1D697), "ord", "mttn", "MATHEMATICAL MONOSPACE SMALL N", nil)
addSymbol(U(0x1D698), "ord", "mtto", "MATHEMATICAL MONOSPACE SMALL O", nil)
addSymbol(U(0x1D699), "ord", "mttp", "MATHEMATICAL MONOSPACE SMALL P", nil)
addSymbol(U(0x1D69A), "ord", "mttq", "MATHEMATICAL MONOSPACE SMALL Q", nil)
addSymbol(U(0x1D69B), "ord", "mttr", "MATHEMATICAL MONOSPACE SMALL R", nil)
addSymbol(U(0x1D69C), "ord", "mtts", "MATHEMATICAL MONOSPACE SMALL S", nil)
addSymbol(U(0x1D69D), "ord", "mttt", "MATHEMATICAL MONOSPACE SMALL T", nil)
addSymbol(U(0x1D69E), "ord", "mttu", "MATHEMATICAL MONOSPACE SMALL U", nil)
addSymbol(U(0x1D69F), "ord", "mttv", "MATHEMATICAL MONOSPACE SMALL V", nil)
addSymbol(U(0x1D6A0), "ord", "mttw", "MATHEMATICAL MONOSPACE SMALL W", nil)
addSymbol(U(0x1D6A1), "ord", "mttx", "MATHEMATICAL MONOSPACE SMALL X", nil)
addSymbol(U(0x1D6A2), "ord", "mtty", "MATHEMATICAL MONOSPACE SMALL Y", nil)
addSymbol(U(0x1D6A3), "ord", "mttz", "MATHEMATICAL MONOSPACE SMALL Z", nil)
addSymbol(U(0x1D6A4), "ord", "imath", "MATHEMATICAL ITALIC SMALL DOTLESS I", nil)
addSymbol(U(0x1D6A5), "ord", "jmath", "MATHEMATICAL ITALIC SMALL DOTLESS J", nil)
addSymbol(U(0x1D6A8), "ord", "mbfAlpha", "MATHEMATICAL BOLD CAPITAL ALPHA", nil)
addSymbol(U(0x1D6A9), "ord", "mbfBeta", "MATHEMATICAL BOLD CAPITAL BETA", nil)
addSymbol(U(0x1D6AA), "ord", "mbfGamma", "MATHEMATICAL BOLD CAPITAL GAMMA", nil)
addSymbol(U(0x1D6AB), "ord", "mbfDelta", "MATHEMATICAL BOLD CAPITAL DELTA", nil)
addSymbol(U(0x1D6AC), "ord", "mbfEpsilon", "MATHEMATICAL BOLD CAPITAL EPSILON", nil)
addSymbol(U(0x1D6AD), "ord", "mbfZeta", "MATHEMATICAL BOLD CAPITAL ZETA", nil)
addSymbol(U(0x1D6AE), "ord", "mbfEta", "MATHEMATICAL BOLD CAPITAL ETA", nil)
addSymbol(U(0x1D6AF), "ord", "mbfTheta", "MATHEMATICAL BOLD CAPITAL THETA", nil)
addSymbol(U(0x1D6B0), "ord", "mbfIota", "MATHEMATICAL BOLD CAPITAL IOTA", nil)
addSymbol(U(0x1D6B1), "ord", "mbfKappa", "MATHEMATICAL BOLD CAPITAL KAPPA", nil)
addSymbol(U(0x1D6B2), "ord", "mbfLambda", "MATHEMATICAL BOLD CAPITAL LAMDA", nil)
addSymbol(U(0x1D6B3), "ord", "mbfMu", "MATHEMATICAL BOLD CAPITAL MU", nil)
addSymbol(U(0x1D6B4), "ord", "mbfNu", "MATHEMATICAL BOLD CAPITAL NU", nil)
addSymbol(U(0x1D6B5), "ord", "mbfXi", "MATHEMATICAL BOLD CAPITAL XI", nil)
addSymbol(U(0x1D6B6), "ord", "mbfOmicron", "MATHEMATICAL BOLD CAPITAL OMICRON", nil)
addSymbol(U(0x1D6B7), "ord", "mbfPi", "MATHEMATICAL BOLD CAPITAL PI", nil)
addSymbol(U(0x1D6B8), "ord", "mbfRho", "MATHEMATICAL BOLD CAPITAL RHO", nil)
addSymbol(U(0x1D6B9), "ord", "mbfvarTheta", "MATHEMATICAL BOLD CAPITAL THETA SYMBOL", nil)
addSymbol(U(0x1D6BA), "ord", "mbfSigma", "MATHEMATICAL BOLD CAPITAL SIGMA", nil)
addSymbol(U(0x1D6BB), "ord", "mbfTau", "MATHEMATICAL BOLD CAPITAL TAU", nil)
addSymbol(U(0x1D6BC), "ord", "mbfUpsilon", "MATHEMATICAL BOLD CAPITAL UPSILON", nil)
addSymbol(U(0x1D6BD), "ord", "mbfPhi", "MATHEMATICAL BOLD CAPITAL PHI", nil)
addSymbol(U(0x1D6BE), "ord", "mbfChi", "MATHEMATICAL BOLD CAPITAL CHI", nil)
addSymbol(U(0x1D6BF), "ord", "mbfPsi", "MATHEMATICAL BOLD CAPITAL PSI", nil)
addSymbol(U(0x1D6C0), "ord", "mbfOmega", "MATHEMATICAL BOLD CAPITAL OMEGA", nil)
addSymbol(U(0x1D6C1), "ord", "mbfnabla", "MATHEMATICAL BOLD NABLA", nil)
addSymbol(U(0x1D6C2), "ord", "mbfalpha", "MATHEMATICAL BOLD SMALL ALPHA", nil)
addSymbol(U(0x1D6C3), "ord", "mbfbeta", "MATHEMATICAL BOLD SMALL BETA", nil)
addSymbol(U(0x1D6C4), "ord", "mbfgamma", "MATHEMATICAL BOLD SMALL GAMMA", nil)
addSymbol(U(0x1D6C5), "ord", "mbfdelta", "MATHEMATICAL BOLD SMALL DELTA", nil)
addSymbol(U(0x1D6C6), "ord", "mbfvarepsilon", "MATHEMATICAL BOLD SMALL EPSILON", nil)
addSymbol(U(0x1D6C7), "ord", "mbfzeta", "MATHEMATICAL BOLD SMALL ZETA", nil)
addSymbol(U(0x1D6C8), "ord", "mbfeta", "MATHEMATICAL BOLD SMALL ETA", nil)
addSymbol(U(0x1D6C9), "ord", "mbftheta", "MATHEMATICAL BOLD SMALL THETA", nil)
addSymbol(U(0x1D6CA), "ord", "mbfiota", "MATHEMATICAL BOLD SMALL IOTA", nil)
addSymbol(U(0x1D6CB), "ord", "mbfkappa", "MATHEMATICAL BOLD SMALL KAPPA", nil)
addSymbol(U(0x1D6CC), "ord", "mbflambda", "MATHEMATICAL BOLD SMALL LAMDA", nil)
addSymbol(U(0x1D6CD), "ord", "mbfmu", "MATHEMATICAL BOLD SMALL MU", nil)
addSymbol(U(0x1D6CE), "ord", "mbfnu", "MATHEMATICAL BOLD SMALL NU", nil)
addSymbol(U(0x1D6CF), "ord", "mbfxi", "MATHEMATICAL BOLD SMALL XI", nil)
addSymbol(U(0x1D6D0), "ord", "mbfomicron", "MATHEMATICAL BOLD SMALL OMICRON", nil)
addSymbol(U(0x1D6D1), "ord", "mbfpi", "MATHEMATICAL BOLD SMALL PI", nil)
addSymbol(U(0x1D6D2), "ord", "mbfrho", "MATHEMATICAL BOLD SMALL RHO", nil)
addSymbol(U(0x1D6D3), "ord", "mbfvarsigma", "MATHEMATICAL BOLD SMALL FINAL SIGMA", nil)
addSymbol(U(0x1D6D4), "ord", "mbfsigma", "MATHEMATICAL BOLD SMALL SIGMA", nil)
addSymbol(U(0x1D6D5), "ord", "mbftau", "MATHEMATICAL BOLD SMALL TAU", nil)
addSymbol(U(0x1D6D6), "ord", "mbfupsilon", "MATHEMATICAL BOLD SMALL UPSILON", nil)
addSymbol(U(0x1D6D7), "ord", "mbfvarphi", "MATHEMATICAL BOLD SMALL PHI", nil)
addSymbol(U(0x1D6D8), "ord", "mbfchi", "MATHEMATICAL BOLD SMALL CHI", nil)
addSymbol(U(0x1D6D9), "ord", "mbfpsi", "MATHEMATICAL BOLD SMALL PSI", nil)
addSymbol(U(0x1D6DA), "ord", "mbfomega", "MATHEMATICAL BOLD SMALL OMEGA", nil)
addSymbol(U(0x1D6DB), "ord", "mbfpartial", "MATHEMATICAL BOLD PARTIAL DIFFERENTIAL", nil)
addSymbol(U(0x1D6DC), "ord", "mbfepsilon", "MATHEMATICAL BOLD EPSILON SYMBOL", nil)
addSymbol(U(0x1D6DD), "ord", "mbfvartheta", "MATHEMATICAL BOLD THETA SYMBOL", nil)
addSymbol(U(0x1D6DE), "ord", "mbfvarkappa", "MATHEMATICAL BOLD KAPPA SYMBOL", nil)
addSymbol(U(0x1D6DF), "ord", "mbfphi", "MATHEMATICAL BOLD PHI SYMBOL", nil)
addSymbol(U(0x1D6E0), "ord", "mbfvarrho", "MATHEMATICAL BOLD RHO SYMBOL", nil)
addSymbol(U(0x1D6E1), "ord", "mbfvarpi", "MATHEMATICAL BOLD PI SYMBOL", nil)
addSymbol(U(0x1D6E2), "ord", "mitAlpha", "MATHEMATICAL ITALIC CAPITAL ALPHA", nil)
addSymbol(U(0x1D6E3), "ord", "mitBeta", "MATHEMATICAL ITALIC CAPITAL BETA", nil)
addSymbol(U(0x1D6E4), "ord", "mitGamma", "MATHEMATICAL ITALIC CAPITAL GAMMA", nil)
addSymbol(U(0x1D6E5), "ord", "mitDelta", "MATHEMATICAL ITALIC CAPITAL DELTA", nil)
addSymbol(U(0x1D6E6), "ord", "mitEpsilon", "MATHEMATICAL ITALIC CAPITAL EPSILON", nil)
addSymbol(U(0x1D6E7), "ord", "mitZeta", "MATHEMATICAL ITALIC CAPITAL ZETA", nil)
addSymbol(U(0x1D6E8), "ord", "mitEta", "MATHEMATICAL ITALIC CAPITAL ETA", nil)
addSymbol(U(0x1D6E9), "ord", "mitTheta", "MATHEMATICAL ITALIC CAPITAL THETA", nil)
addSymbol(U(0x1D6EA), "ord", "mitIota", "MATHEMATICAL ITALIC CAPITAL IOTA", nil)
addSymbol(U(0x1D6EB), "ord", "mitKappa", "MATHEMATICAL ITALIC CAPITAL KAPPA", nil)
addSymbol(U(0x1D6EC), "ord", "mitLambda", "MATHEMATICAL ITALIC CAPITAL LAMDA", nil)
addSymbol(U(0x1D6ED), "ord", "mitMu", "MATHEMATICAL ITALIC CAPITAL MU", nil)
addSymbol(U(0x1D6EE), "ord", "mitNu", "MATHEMATICAL ITALIC CAPITAL NU", nil)
addSymbol(U(0x1D6EF), "ord", "mitXi", "MATHEMATICAL ITALIC CAPITAL XI", nil)
addSymbol(U(0x1D6F0), "ord", "mitOmicron", "MATHEMATICAL ITALIC CAPITAL OMICRON", nil)
addSymbol(U(0x1D6F1), "ord", "mitPi", "MATHEMATICAL ITALIC CAPITAL PI", nil)
addSymbol(U(0x1D6F2), "ord", "mitRho", "MATHEMATICAL ITALIC CAPITAL RHO", nil)
addSymbol(U(0x1D6F3), "ord", "mitvarTheta", "MATHEMATICAL ITALIC CAPITAL THETA SYMBOL", nil)
addSymbol(U(0x1D6F4), "ord", "mitSigma", "MATHEMATICAL ITALIC CAPITAL SIGMA", nil)
addSymbol(U(0x1D6F5), "ord", "mitTau", "MATHEMATICAL ITALIC CAPITAL TAU", nil)
addSymbol(U(0x1D6F6), "ord", "mitUpsilon", "MATHEMATICAL ITALIC CAPITAL UPSILON", nil)
addSymbol(U(0x1D6F7), "ord", "mitPhi", "MATHEMATICAL ITALIC CAPITAL PHI", nil)
addSymbol(U(0x1D6F8), "ord", "mitChi", "MATHEMATICAL ITALIC CAPITAL CHI", nil)
addSymbol(U(0x1D6F9), "ord", "mitPsi", "MATHEMATICAL ITALIC CAPITAL PSI", nil)
addSymbol(U(0x1D6FA), "ord", "mitOmega", "MATHEMATICAL ITALIC CAPITAL OMEGA", nil)
addSymbol(U(0x1D6FB), "ord", "mitnabla", "MATHEMATICAL ITALIC NABLA", nil)
addSymbol(U(0x1D6FC), "ord", "mitalpha", "MATHEMATICAL ITALIC SMALL ALPHA", nil)
addSymbol(U(0x1D6FD), "ord", "mitbeta", "MATHEMATICAL ITALIC SMALL BETA", nil)
addSymbol(U(0x1D6FE), "ord", "mitgamma", "MATHEMATICAL ITALIC SMALL GAMMA", nil)
addSymbol(U(0x1D6FF), "ord", "mitdelta", "MATHEMATICAL ITALIC SMALL DELTA", nil)
addSymbol(U(0x1D700), "ord", "mitvarepsilon", "MATHEMATICAL ITALIC SMALL EPSILON", nil)
addSymbol(U(0x1D701), "ord", "mitzeta", "MATHEMATICAL ITALIC SMALL ZETA", nil)
addSymbol(U(0x1D702), "ord", "miteta", "MATHEMATICAL ITALIC SMALL ETA", nil)
addSymbol(U(0x1D703), "ord", "mittheta", "MATHEMATICAL ITALIC SMALL THETA", nil)
addSymbol(U(0x1D704), "ord", "mitiota", "MATHEMATICAL ITALIC SMALL IOTA", nil)
addSymbol(U(0x1D705), "ord", "mitkappa", "MATHEMATICAL ITALIC SMALL KAPPA", nil)
addSymbol(U(0x1D706), "ord", "mitlambda", "MATHEMATICAL ITALIC SMALL LAMDA", nil)
addSymbol(U(0x1D707), "ord", "mitmu", "MATHEMATICAL ITALIC SMALL MU", nil)
addSymbol(U(0x1D708), "ord", "mitnu", "MATHEMATICAL ITALIC SMALL NU", nil)
addSymbol(U(0x1D709), "ord", "mitxi", "MATHEMATICAL ITALIC SMALL XI", nil)
addSymbol(U(0x1D70A), "ord", "mitomicron", "MATHEMATICAL ITALIC SMALL OMICRON", nil)
addSymbol(U(0x1D70B), "ord", "mitpi", "MATHEMATICAL ITALIC SMALL PI", nil)
addSymbol(U(0x1D70C), "ord", "mitrho", "MATHEMATICAL ITALIC SMALL RHO", nil)
addSymbol(U(0x1D70D), "ord", "mitvarsigma", "MATHEMATICAL ITALIC SMALL FINAL SIGMA", nil)
addSymbol(U(0x1D70E), "ord", "mitsigma", "MATHEMATICAL ITALIC SMALL SIGMA", nil)
addSymbol(U(0x1D70F), "ord", "mittau", "MATHEMATICAL ITALIC SMALL TAU", nil)
addSymbol(U(0x1D710), "ord", "mitupsilon", "MATHEMATICAL ITALIC SMALL UPSILON", nil)
addSymbol(U(0x1D711), "ord", "mitvarphi", "MATHEMATICAL ITALIC SMALL PHI", nil)
addSymbol(U(0x1D712), "ord", "mitchi", "MATHEMATICAL ITALIC SMALL CHI", nil)
addSymbol(U(0x1D713), "ord", "mitpsi", "MATHEMATICAL ITALIC SMALL PSI", nil)
addSymbol(U(0x1D714), "ord", "mitomega", "MATHEMATICAL ITALIC SMALL OMEGA", nil)
addSymbol(U(0x1D715), "ord", "mitpartial", "MATHEMATICAL ITALIC PARTIAL DIFFERENTIAL", nil)
addSymbol(U(0x1D716), "ord", "mitepsilon", "MATHEMATICAL ITALIC EPSILON SYMBOL", nil)
addSymbol(U(0x1D717), "ord", "mitvartheta", "MATHEMATICAL ITALIC THETA SYMBOL", nil)
addSymbol(U(0x1D718), "ord", "mitvarkappa", "MATHEMATICAL ITALIC KAPPA SYMBOL", nil)
addSymbol(U(0x1D719), "ord", "mitphi", "MATHEMATICAL ITALIC PHI SYMBOL", nil)
addSymbol(U(0x1D71A), "ord", "mitvarrho", "MATHEMATICAL ITALIC RHO SYMBOL", nil)
addSymbol(U(0x1D71B), "ord", "mitvarpi", "MATHEMATICAL ITALIC PI SYMBOL", nil)
addSymbol(U(0x1D71C), "ord", "mbfitAlpha", "MATHEMATICAL BOLD ITALIC CAPITAL ALPHA", nil)
addSymbol(U(0x1D71D), "ord", "mbfitBeta", "MATHEMATICAL BOLD ITALIC CAPITAL BETA", nil)
addSymbol(U(0x1D71E), "ord", "mbfitGamma", "MATHEMATICAL BOLD ITALIC CAPITAL GAMMA", nil)
addSymbol(U(0x1D71F), "ord", "mbfitDelta", "MATHEMATICAL BOLD ITALIC CAPITAL DELTA", nil)
addSymbol(U(0x1D720), "ord", "mbfitEpsilon", "MATHEMATICAL BOLD ITALIC CAPITAL EPSILON", nil)
addSymbol(U(0x1D721), "ord", "mbfitZeta", "MATHEMATICAL BOLD ITALIC CAPITAL ZETA", nil)
addSymbol(U(0x1D722), "ord", "mbfitEta", "MATHEMATICAL BOLD ITALIC CAPITAL ETA", nil)
addSymbol(U(0x1D723), "ord", "mbfitTheta", "MATHEMATICAL BOLD ITALIC CAPITAL THETA", nil)
addSymbol(U(0x1D724), "ord", "mbfitIota", "MATHEMATICAL BOLD ITALIC CAPITAL IOTA", nil)
addSymbol(U(0x1D725), "ord", "mbfitKappa", "MATHEMATICAL BOLD ITALIC CAPITAL KAPPA", nil)
addSymbol(U(0x1D726), "ord", "mbfitLambda", "MATHEMATICAL BOLD ITALIC CAPITAL LAMDA", nil)
addSymbol(U(0x1D727), "ord", "mbfitMu", "MATHEMATICAL BOLD ITALIC CAPITAL MU", nil)
addSymbol(U(0x1D728), "ord", "mbfitNu", "MATHEMATICAL BOLD ITALIC CAPITAL NU", nil)
addSymbol(U(0x1D729), "ord", "mbfitXi", "MATHEMATICAL BOLD ITALIC CAPITAL XI", nil)
addSymbol(U(0x1D72A), "ord", "mbfitOmicron", "MATHEMATICAL BOLD ITALIC CAPITAL OMICRON", nil)
addSymbol(U(0x1D72B), "ord", "mbfitPi", "MATHEMATICAL BOLD ITALIC CAPITAL PI", nil)
addSymbol(U(0x1D72C), "ord", "mbfitRho", "MATHEMATICAL BOLD ITALIC CAPITAL RHO", nil)
addSymbol(U(0x1D72D), "ord", "mbfitvarTheta", "MATHEMATICAL BOLD ITALIC CAPITAL THETA SYMBOL", nil)
addSymbol(U(0x1D72E), "ord", "mbfitSigma", "MATHEMATICAL BOLD ITALIC CAPITAL SIGMA", nil)
addSymbol(U(0x1D72F), "ord", "mbfitTau", "MATHEMATICAL BOLD ITALIC CAPITAL TAU", nil)
addSymbol(U(0x1D730), "ord", "mbfitUpsilon", "MATHEMATICAL BOLD ITALIC CAPITAL UPSILON", nil)
addSymbol(U(0x1D731), "ord", "mbfitPhi", "MATHEMATICAL BOLD ITALIC CAPITAL PHI", nil)
addSymbol(U(0x1D732), "ord", "mbfitChi", "MATHEMATICAL BOLD ITALIC CAPITAL CHI", nil)
addSymbol(U(0x1D733), "ord", "mbfitPsi", "MATHEMATICAL BOLD ITALIC CAPITAL PSI", nil)
addSymbol(U(0x1D734), "ord", "mbfitOmega", "MATHEMATICAL BOLD ITALIC CAPITAL OMEGA", nil)
addSymbol(U(0x1D735), "ord", "mbfitnabla", "MATHEMATICAL BOLD ITALIC NABLA", nil)
addSymbol(U(0x1D736), "ord", "mbfitalpha", "MATHEMATICAL BOLD ITALIC SMALL ALPHA", nil)
addSymbol(U(0x1D737), "ord", "mbfitbeta", "MATHEMATICAL BOLD ITALIC SMALL BETA", nil)
addSymbol(U(0x1D738), "ord", "mbfitgamma", "MATHEMATICAL BOLD ITALIC SMALL GAMMA", nil)
addSymbol(U(0x1D739), "ord", "mbfitdelta", "MATHEMATICAL BOLD ITALIC SMALL DELTA", nil)
addSymbol(U(0x1D73A), "ord", "mbfitvarepsilon", "MATHEMATICAL BOLD ITALIC SMALL EPSILON", nil)
addSymbol(U(0x1D73B), "ord", "mbfitzeta", "MATHEMATICAL BOLD ITALIC SMALL ZETA", nil)
addSymbol(U(0x1D73C), "ord", "mbfiteta", "MATHEMATICAL BOLD ITALIC SMALL ETA", nil)
addSymbol(U(0x1D73D), "ord", "mbfittheta", "MATHEMATICAL BOLD ITALIC SMALL THETA", nil)
addSymbol(U(0x1D73E), "ord", "mbfitiota", "MATHEMATICAL BOLD ITALIC SMALL IOTA", nil)
addSymbol(U(0x1D73F), "ord", "mbfitkappa", "MATHEMATICAL BOLD ITALIC SMALL KAPPA", nil)
addSymbol(U(0x1D740), "ord", "mbfitlambda", "MATHEMATICAL BOLD ITALIC SMALL LAMDA", nil)
addSymbol(U(0x1D741), "ord", "mbfitmu", "MATHEMATICAL BOLD ITALIC SMALL MU", nil)
addSymbol(U(0x1D742), "ord", "mbfitnu", "MATHEMATICAL BOLD ITALIC SMALL NU", nil)
addSymbol(U(0x1D743), "ord", "mbfitxi", "MATHEMATICAL BOLD ITALIC SMALL XI", nil)
addSymbol(U(0x1D744), "ord", "mbfitomicron", "MATHEMATICAL BOLD ITALIC SMALL OMICRON", nil)
addSymbol(U(0x1D745), "ord", "mbfitpi", "MATHEMATICAL BOLD ITALIC SMALL PI", nil)
addSymbol(U(0x1D746), "ord", "mbfitrho", "MATHEMATICAL BOLD ITALIC SMALL RHO", nil)
addSymbol(U(0x1D747), "ord", "mbfitvarsigma", "MATHEMATICAL BOLD ITALIC SMALL FINAL SIGMA", nil)
addSymbol(U(0x1D748), "ord", "mbfitsigma", "MATHEMATICAL BOLD ITALIC SMALL SIGMA", nil)
addSymbol(U(0x1D749), "ord", "mbfittau", "MATHEMATICAL BOLD ITALIC SMALL TAU", nil)
addSymbol(U(0x1D74A), "ord", "mbfitupsilon", "MATHEMATICAL BOLD ITALIC SMALL UPSILON", nil)
addSymbol(U(0x1D74B), "ord", "mbfitvarphi", "MATHEMATICAL BOLD ITALIC SMALL PHI", nil)
addSymbol(U(0x1D74C), "ord", "mbfitchi", "MATHEMATICAL BOLD ITALIC SMALL CHI", nil)
addSymbol(U(0x1D74D), "ord", "mbfitpsi", "MATHEMATICAL BOLD ITALIC SMALL PSI", nil)
addSymbol(U(0x1D74E), "ord", "mbfitomega", "MATHEMATICAL BOLD ITALIC SMALL OMEGA", nil)
addSymbol(U(0x1D74F), "ord", "mbfitpartial", "MATHEMATICAL BOLD ITALIC PARTIAL DIFFERENTIAL", nil)
addSymbol(U(0x1D750), "ord", "mbfitepsilon", "MATHEMATICAL BOLD ITALIC EPSILON SYMBOL", nil)
addSymbol(U(0x1D751), "ord", "mbfitvartheta", "MATHEMATICAL BOLD ITALIC THETA SYMBOL", nil)
addSymbol(U(0x1D752), "ord", "mbfitvarkappa", "MATHEMATICAL BOLD ITALIC KAPPA SYMBOL", nil)
addSymbol(U(0x1D753), "ord", "mbfitphi", "MATHEMATICAL BOLD ITALIC PHI SYMBOL", nil)
addSymbol(U(0x1D754), "ord", "mbfitvarrho", "MATHEMATICAL BOLD ITALIC RHO SYMBOL", nil)
addSymbol(U(0x1D755), "ord", "mbfitvarpi", "MATHEMATICAL BOLD ITALIC PI SYMBOL", nil)
addSymbol(U(0x1D756), "ord", "mbfsansAlpha", "MATHEMATICAL SANS-SERIF BOLD CAPITAL ALPHA", nil)
addSymbol(U(0x1D757), "ord", "mbfsansBeta", "MATHEMATICAL SANS-SERIF BOLD CAPITAL BETA", nil)
addSymbol(U(0x1D758), "ord", "mbfsansGamma", "MATHEMATICAL SANS-SERIF BOLD CAPITAL GAMMA", nil)
addSymbol(U(0x1D759), "ord", "mbfsansDelta", "MATHEMATICAL SANS-SERIF BOLD CAPITAL DELTA", nil)
addSymbol(U(0x1D75A), "ord", "mbfsansEpsilon", "MATHEMATICAL SANS-SERIF BOLD CAPITAL EPSILON", nil)
addSymbol(U(0x1D75B), "ord", "mbfsansZeta", "MATHEMATICAL SANS-SERIF BOLD CAPITAL ZETA", nil)
addSymbol(U(0x1D75C), "ord", "mbfsansEta", "MATHEMATICAL SANS-SERIF BOLD CAPITAL ETA", nil)
addSymbol(U(0x1D75D), "ord", "mbfsansTheta", "MATHEMATICAL SANS-SERIF BOLD CAPITAL THETA", nil)
addSymbol(U(0x1D75E), "ord", "mbfsansIota", "MATHEMATICAL SANS-SERIF BOLD CAPITAL IOTA", nil)
addSymbol(U(0x1D75F), "ord", "mbfsansKappa", "MATHEMATICAL SANS-SERIF BOLD CAPITAL KAPPA", nil)
addSymbol(U(0x1D760), "ord", "mbfsansLambda", "MATHEMATICAL SANS-SERIF BOLD CAPITAL LAMDA", nil)
addSymbol(U(0x1D761), "ord", "mbfsansMu", "MATHEMATICAL SANS-SERIF BOLD CAPITAL MU", nil)
addSymbol(U(0x1D762), "ord", "mbfsansNu", "MATHEMATICAL SANS-SERIF BOLD CAPITAL NU", nil)
addSymbol(U(0x1D763), "ord", "mbfsansXi", "MATHEMATICAL SANS-SERIF BOLD CAPITAL XI", nil)
addSymbol(U(0x1D764), "ord", "mbfsansOmicron", "MATHEMATICAL SANS-SERIF BOLD CAPITAL OMICRON", nil)
addSymbol(U(0x1D765), "ord", "mbfsansPi", "MATHEMATICAL SANS-SERIF BOLD CAPITAL PI", nil)
addSymbol(U(0x1D766), "ord", "mbfsansRho", "MATHEMATICAL SANS-SERIF BOLD CAPITAL RHO", nil)
addSymbol(U(0x1D767), "ord", "mbfsansvarTheta", "MATHEMATICAL SANS-SERIF BOLD CAPITAL THETA SYMBOL", nil)
addSymbol(U(0x1D768), "ord", "mbfsansSigma", "MATHEMATICAL SANS-SERIF BOLD CAPITAL SIGMA", nil)
addSymbol(U(0x1D769), "ord", "mbfsansTau", "MATHEMATICAL SANS-SERIF BOLD CAPITAL TAU", nil)
addSymbol(U(0x1D76A), "ord", "mbfsansUpsilon", "MATHEMATICAL SANS-SERIF BOLD CAPITAL UPSILON", nil)
addSymbol(U(0x1D76B), "ord", "mbfsansPhi", "MATHEMATICAL SANS-SERIF BOLD CAPITAL PHI", nil)
addSymbol(U(0x1D76C), "ord", "mbfsansChi", "MATHEMATICAL SANS-SERIF BOLD CAPITAL CHI", nil)
addSymbol(U(0x1D76D), "ord", "mbfsansPsi", "MATHEMATICAL SANS-SERIF BOLD CAPITAL PSI", nil)
addSymbol(U(0x1D76E), "ord", "mbfsansOmega", "MATHEMATICAL SANS-SERIF BOLD CAPITAL OMEGA", nil)
addSymbol(U(0x1D76F), "ord", "mbfsansnabla", "MATHEMATICAL SANS-SERIF BOLD NABLA", nil)
addSymbol(U(0x1D770), "ord", "mbfsansalpha", "MATHEMATICAL SANS-SERIF BOLD SMALL ALPHA", nil)
addSymbol(U(0x1D771), "ord", "mbfsansbeta", "MATHEMATICAL SANS-SERIF BOLD SMALL BETA", nil)
addSymbol(U(0x1D772), "ord", "mbfsansgamma", "MATHEMATICAL SANS-SERIF BOLD SMALL GAMMA", nil)
addSymbol(U(0x1D773), "ord", "mbfsansdelta", "MATHEMATICAL SANS-SERIF BOLD SMALL DELTA", nil)
addSymbol(U(0x1D774), "ord", "mbfsansvarepsilon", "MATHEMATICAL SANS-SERIF BOLD SMALL EPSILON", nil)
addSymbol(U(0x1D775), "ord", "mbfsanszeta", "MATHEMATICAL SANS-SERIF BOLD SMALL ZETA", nil)
addSymbol(U(0x1D776), "ord", "mbfsanseta", "MATHEMATICAL SANS-SERIF BOLD SMALL ETA", nil)
addSymbol(U(0x1D777), "ord", "mbfsanstheta", "MATHEMATICAL SANS-SERIF BOLD SMALL THETA", nil)
addSymbol(U(0x1D778), "ord", "mbfsansiota", "MATHEMATICAL SANS-SERIF BOLD SMALL IOTA", nil)
addSymbol(U(0x1D779), "ord", "mbfsanskappa", "MATHEMATICAL SANS-SERIF BOLD SMALL KAPPA", nil)
addSymbol(U(0x1D77A), "ord", "mbfsanslambda", "MATHEMATICAL SANS-SERIF BOLD SMALL LAMDA", nil)
addSymbol(U(0x1D77B), "ord", "mbfsansmu", "MATHEMATICAL SANS-SERIF BOLD SMALL MU", nil)
addSymbol(U(0x1D77C), "ord", "mbfsansnu", "MATHEMATICAL SANS-SERIF BOLD SMALL NU", nil)
addSymbol(U(0x1D77D), "ord", "mbfsansxi", "MATHEMATICAL SANS-SERIF BOLD SMALL XI", nil)
addSymbol(U(0x1D77E), "ord", "mbfsansomicron", "MATHEMATICAL SANS-SERIF BOLD SMALL OMICRON", nil)
addSymbol(U(0x1D77F), "ord", "mbfsanspi", "MATHEMATICAL SANS-SERIF BOLD SMALL PI", nil)
addSymbol(U(0x1D780), "ord", "mbfsansrho", "MATHEMATICAL SANS-SERIF BOLD SMALL RHO", nil)
addSymbol(U(0x1D781), "ord", "mbfsansvarsigma", "MATHEMATICAL SANS-SERIF BOLD SMALL FINAL SIGMA", nil)
addSymbol(U(0x1D782), "ord", "mbfsanssigma", "MATHEMATICAL SANS-SERIF BOLD SMALL SIGMA", nil)
addSymbol(U(0x1D783), "ord", "mbfsanstau", "MATHEMATICAL SANS-SERIF BOLD SMALL TAU", nil)
addSymbol(U(0x1D784), "ord", "mbfsansupsilon", "MATHEMATICAL SANS-SERIF BOLD SMALL UPSILON", nil)
addSymbol(U(0x1D785), "ord", "mbfsansvarphi", "MATHEMATICAL SANS-SERIF BOLD SMALL PHI", nil)
addSymbol(U(0x1D786), "ord", "mbfsanschi", "MATHEMATICAL SANS-SERIF BOLD SMALL CHI", nil)
addSymbol(U(0x1D787), "ord", "mbfsanspsi", "MATHEMATICAL SANS-SERIF BOLD SMALL PSI", nil)
addSymbol(U(0x1D788), "ord", "mbfsansomega", "MATHEMATICAL SANS-SERIF BOLD SMALL OMEGA", nil)
addSymbol(U(0x1D789), "ord", "mbfsanspartial", "MATHEMATICAL SANS-SERIF BOLD PARTIAL DIFFERENTIAL", nil)
addSymbol(U(0x1D78A), "ord", "mbfsansepsilon", "MATHEMATICAL SANS-SERIF BOLD EPSILON SYMBOL", nil)
addSymbol(U(0x1D78B), "ord", "mbfsansvartheta", "MATHEMATICAL SANS-SERIF BOLD THETA SYMBOL", nil)
addSymbol(U(0x1D78C), "ord", "mbfsansvarkappa", "MATHEMATICAL SANS-SERIF BOLD KAPPA SYMBOL", nil)
addSymbol(U(0x1D78D), "ord", "mbfsansphi", "MATHEMATICAL SANS-SERIF BOLD PHI SYMBOL", nil)
addSymbol(U(0x1D78E), "ord", "mbfsansvarrho", "MATHEMATICAL SANS-SERIF BOLD RHO SYMBOL", nil)
addSymbol(U(0x1D78F), "ord", "mbfsansvarpi", "MATHEMATICAL SANS-SERIF BOLD PI SYMBOL", nil)
addSymbol(U(0x1D790), "ord", "mbfitsansAlpha", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL ALPHA", nil)
addSymbol(U(0x1D791), "ord", "mbfitsansBeta", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL BETA", nil)
addSymbol(U(0x1D792), "ord", "mbfitsansGamma", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL GAMMA", nil)
addSymbol(U(0x1D793), "ord", "mbfitsansDelta", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL DELTA", nil)
addSymbol(U(0x1D794), "ord", "mbfitsansEpsilon", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL EPSILON", nil)
addSymbol(U(0x1D795), "ord", "mbfitsansZeta", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL ZETA", nil)
addSymbol(U(0x1D796), "ord", "mbfitsansEta", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL ETA", nil)
addSymbol(U(0x1D797), "ord", "mbfitsansTheta", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL THETA", nil)
addSymbol(U(0x1D798), "ord", "mbfitsansIota", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL IOTA", nil)
addSymbol(U(0x1D799), "ord", "mbfitsansKappa", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL KAPPA", nil)
addSymbol(U(0x1D79A), "ord", "mbfitsansLambda", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL LAMDA", nil)
addSymbol(U(0x1D79B), "ord", "mbfitsansMu", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL MU", nil)
addSymbol(U(0x1D79C), "ord", "mbfitsansNu", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL NU", nil)
addSymbol(U(0x1D79D), "ord", "mbfitsansXi", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL XI", nil)
addSymbol(U(0x1D79E), "ord", "mbfitsansOmicron", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL OMICRON", nil)
addSymbol(U(0x1D79F), "ord", "mbfitsansPi", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL PI", nil)
addSymbol(U(0x1D7A0), "ord", "mbfitsansRho", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL RHO", nil)
addSymbol(U(0x1D7A1), "ord", "mbfitsansvarTheta", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL THETA SYMBOL", nil)
addSymbol(U(0x1D7A2), "ord", "mbfitsansSigma", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL SIGMA", nil)
addSymbol(U(0x1D7A3), "ord", "mbfitsansTau", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL TAU", nil)
addSymbol(U(0x1D7A4), "ord", "mbfitsansUpsilon", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL UPSILON", nil)
addSymbol(U(0x1D7A5), "ord", "mbfitsansPhi", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL PHI", nil)
addSymbol(U(0x1D7A6), "ord", "mbfitsansChi", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL CHI", nil)
addSymbol(U(0x1D7A7), "ord", "mbfitsansPsi", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL PSI", nil)
addSymbol(U(0x1D7A8), "ord", "mbfitsansOmega", "MATHEMATICAL SANS-SERIF BOLD ITALIC CAPITAL OMEGA", nil)
addSymbol(U(0x1D7A9), "ord", "mbfitsansnabla", "MATHEMATICAL SANS-SERIF BOLD ITALIC NABLA", nil)
addSymbol(U(0x1D7AA), "ord", "mbfitsansalpha", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL ALPHA", nil)
addSymbol(U(0x1D7AB), "ord", "mbfitsansbeta", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL BETA", nil)
addSymbol(U(0x1D7AC), "ord", "mbfitsansgamma", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL GAMMA", nil)
addSymbol(U(0x1D7AD), "ord", "mbfitsansdelta", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL DELTA", nil)
addSymbol(U(0x1D7AE), "ord", "mbfitsansvarepsilon", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL EPSILON", nil)
addSymbol(U(0x1D7AF), "ord", "mbfitsanszeta", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL ZETA", nil)
addSymbol(U(0x1D7B0), "ord", "mbfitsanseta", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL ETA", nil)
addSymbol(U(0x1D7B1), "ord", "mbfitsanstheta", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL THETA", nil)
addSymbol(U(0x1D7B2), "ord", "mbfitsansiota", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL IOTA", nil)
addSymbol(U(0x1D7B3), "ord", "mbfitsanskappa", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL KAPPA", nil)
addSymbol(U(0x1D7B4), "ord", "mbfitsanslambda", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL LAMDA", nil)
addSymbol(U(0x1D7B5), "ord", "mbfitsansmu", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL MU", nil)
addSymbol(U(0x1D7B6), "ord", "mbfitsansnu", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL NU", nil)
addSymbol(U(0x1D7B7), "ord", "mbfitsansxi", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL XI", nil)
addSymbol(U(0x1D7B8), "ord", "mbfitsansomicron", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL OMICRON", nil)
addSymbol(U(0x1D7B9), "ord", "mbfitsanspi", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL PI", nil)
addSymbol(U(0x1D7BA), "ord", "mbfitsansrho", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL RHO", nil)
addSymbol(U(0x1D7BB), "ord", "mbfitsansvarsigma", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL FINAL SIGMA", nil)
addSymbol(U(0x1D7BC), "ord", "mbfitsanssigma", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL SIGMA", nil)
addSymbol(U(0x1D7BD), "ord", "mbfitsanstau", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL TAU", nil)
addSymbol(U(0x1D7BE), "ord", "mbfitsansupsilon", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL UPSILON", nil)
addSymbol(U(0x1D7BF), "ord", "mbfitsansvarphi", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL PHI", nil)
addSymbol(U(0x1D7C0), "ord", "mbfitsanschi", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL CHI", nil)
addSymbol(U(0x1D7C1), "ord", "mbfitsanspsi", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL PSI", nil)
addSymbol(U(0x1D7C2), "ord", "mbfitsansomega", "MATHEMATICAL SANS-SERIF BOLD ITALIC SMALL OMEGA", nil)
addSymbol(U(0x1D7C3), "ord", "mbfitsanspartial", "MATHEMATICAL SANS-SERIF BOLD ITALIC PARTIAL DIFFERENTIAL", nil)
addSymbol(U(0x1D7C4), "ord", "mbfitsansepsilon", "MATHEMATICAL SANS-SERIF BOLD ITALIC EPSILON SYMBOL", nil)
addSymbol(U(0x1D7C5), "ord", "mbfitsansvartheta", "MATHEMATICAL SANS-SERIF BOLD ITALIC THETA SYMBOL", nil)
addSymbol(U(0x1D7C6), "ord", "mbfitsansvarkappa", "MATHEMATICAL SANS-SERIF BOLD ITALIC KAPPA SYMBOL", nil)
addSymbol(U(0x1D7C7), "ord", "mbfitsansphi", "MATHEMATICAL SANS-SERIF BOLD ITALIC PHI SYMBOL", nil)
addSymbol(U(0x1D7C8), "ord", "mbfitsansvarrho", "MATHEMATICAL SANS-SERIF BOLD ITALIC RHO SYMBOL", nil)
addSymbol(U(0x1D7C9), "ord", "mbfitsansvarpi", "MATHEMATICAL SANS-SERIF BOLD ITALIC PI SYMBOL", nil)
addSymbol(U(0x1D7CA), "ord", "mbfDigamma", "MATHEMATICAL BOLD CAPITAL DIGAMMA", nil)
addSymbol(U(0x1D7CB), "ord", "mbfdigamma", "MATHEMATICAL BOLD SMALL DIGAMMA", nil)
addSymbol(U(0x1D7CE), "ord", "mbfzero", "MATHEMATICAL BOLD DIGIT ZERO", nil)
addSymbol(U(0x1D7CF), "ord", "mbfone", "MATHEMATICAL BOLD DIGIT ONE", nil)
addSymbol(U(0x1D7D0), "ord", "mbftwo", "MATHEMATICAL BOLD DIGIT TWO", nil)
addSymbol(U(0x1D7D1), "ord", "mbfthree", "MATHEMATICAL BOLD DIGIT THREE", nil)
addSymbol(U(0x1D7D2), "ord", "mbffour", "MATHEMATICAL BOLD DIGIT FOUR", nil)
addSymbol(U(0x1D7D3), "ord", "mbffive", "MATHEMATICAL BOLD DIGIT FIVE", nil)
addSymbol(U(0x1D7D4), "ord", "mbfsix", "MATHEMATICAL BOLD DIGIT SIX", nil)
addSymbol(U(0x1D7D5), "ord", "mbfseven", "MATHEMATICAL BOLD DIGIT SEVEN", nil)
addSymbol(U(0x1D7D6), "ord", "mbfeight", "MATHEMATICAL BOLD DIGIT EIGHT", nil)
addSymbol(U(0x1D7D7), "ord", "mbfnine", "MATHEMATICAL BOLD DIGIT NINE", nil)
addSymbol(U(0x1D7D8), "ord", "Bbbzero", "MATHEMATICAL DOUBLE-STRUCK DIGIT ZERO", nil)
addSymbol(U(0x1D7D9), "ord", "Bbbone", "MATHEMATICAL DOUBLE-STRUCK DIGIT ONE", nil)
addSymbol(U(0x1D7DA), "ord", "Bbbtwo", "MATHEMATICAL DOUBLE-STRUCK DIGIT TWO", nil)
addSymbol(U(0x1D7DB), "ord", "Bbbthree", "MATHEMATICAL DOUBLE-STRUCK DIGIT THREE", nil)
addSymbol(U(0x1D7DC), "ord", "Bbbfour", "MATHEMATICAL DOUBLE-STRUCK DIGIT FOUR", nil)
addSymbol(U(0x1D7DD), "ord", "Bbbfive", "MATHEMATICAL DOUBLE-STRUCK DIGIT FIVE", nil)
addSymbol(U(0x1D7DE), "ord", "Bbbsix", "MATHEMATICAL DOUBLE-STRUCK DIGIT SIX", nil)
addSymbol(U(0x1D7DF), "ord", "Bbbseven", "MATHEMATICAL DOUBLE-STRUCK DIGIT SEVEN", nil)
addSymbol(U(0x1D7E0), "ord", "Bbbeight", "MATHEMATICAL DOUBLE-STRUCK DIGIT EIGHT", nil)
addSymbol(U(0x1D7E1), "ord", "Bbbnine", "MATHEMATICAL DOUBLE-STRUCK DIGIT NINE", nil)
addSymbol(U(0x1D7E2), "ord", "msanszero", "MATHEMATICAL SANS-SERIF DIGIT ZERO", nil)
addSymbol(U(0x1D7E3), "ord", "msansone", "MATHEMATICAL SANS-SERIF DIGIT ONE", nil)
addSymbol(U(0x1D7E4), "ord", "msanstwo", "MATHEMATICAL SANS-SERIF DIGIT TWO", nil)
addSymbol(U(0x1D7E5), "ord", "msansthree", "MATHEMATICAL SANS-SERIF DIGIT THREE", nil)
addSymbol(U(0x1D7E6), "ord", "msansfour", "MATHEMATICAL SANS-SERIF DIGIT FOUR", nil)
addSymbol(U(0x1D7E7), "ord", "msansfive", "MATHEMATICAL SANS-SERIF DIGIT FIVE", nil)
addSymbol(U(0x1D7E8), "ord", "msanssix", "MATHEMATICAL SANS-SERIF DIGIT SIX", nil)
addSymbol(U(0x1D7E9), "ord", "msansseven", "MATHEMATICAL SANS-SERIF DIGIT SEVEN", nil)
addSymbol(U(0x1D7EA), "ord", "msanseight", "MATHEMATICAL SANS-SERIF DIGIT EIGHT", nil)
addSymbol(U(0x1D7EB), "ord", "msansnine", "MATHEMATICAL SANS-SERIF DIGIT NINE", nil)
addSymbol(U(0x1D7EC), "ord", "mbfsanszero", "MATHEMATICAL SANS-SERIF BOLD DIGIT ZERO", nil)
addSymbol(U(0x1D7ED), "ord", "mbfsansone", "MATHEMATICAL SANS-SERIF BOLD DIGIT ONE", nil)
addSymbol(U(0x1D7EE), "ord", "mbfsanstwo", "MATHEMATICAL SANS-SERIF BOLD DIGIT TWO", nil)
addSymbol(U(0x1D7EF), "ord", "mbfsansthree", "MATHEMATICAL SANS-SERIF BOLD DIGIT THREE", nil)
addSymbol(U(0x1D7F0), "ord", "mbfsansfour", "MATHEMATICAL SANS-SERIF BOLD DIGIT FOUR", nil)
addSymbol(U(0x1D7F1), "ord", "mbfsansfive", "MATHEMATICAL SANS-SERIF BOLD DIGIT FIVE", nil)
addSymbol(U(0x1D7F2), "ord", "mbfsanssix", "MATHEMATICAL SANS-SERIF BOLD DIGIT SIX", nil)
addSymbol(U(0x1D7F3), "ord", "mbfsansseven", "MATHEMATICAL SANS-SERIF BOLD DIGIT SEVEN", nil)
addSymbol(U(0x1D7F4), "ord", "mbfsanseight", "MATHEMATICAL SANS-SERIF BOLD DIGIT EIGHT", nil)
addSymbol(U(0x1D7F5), "ord", "mbfsansnine", "MATHEMATICAL SANS-SERIF BOLD DIGIT NINE", nil)
addSymbol(U(0x1D7F6), "ord", "mttzero", "MATHEMATICAL MONOSPACE DIGIT ZERO", nil)
addSymbol(U(0x1D7F7), "ord", "mttone", "MATHEMATICAL MONOSPACE DIGIT ONE", nil)
addSymbol(U(0x1D7F8), "ord", "mtttwo", "MATHEMATICAL MONOSPACE DIGIT TWO", nil)
addSymbol(U(0x1D7F9), "ord", "mttthree", "MATHEMATICAL MONOSPACE DIGIT THREE", nil)
addSymbol(U(0x1D7FA), "ord", "mttfour", "MATHEMATICAL MONOSPACE DIGIT FOUR", nil)
addSymbol(U(0x1D7FB), "ord", "mttfive", "MATHEMATICAL MONOSPACE DIGIT FIVE", nil)
addSymbol(U(0x1D7FC), "ord", "mttsix", "MATHEMATICAL MONOSPACE DIGIT SIX", nil)
addSymbol(U(0x1D7FD), "ord", "mttseven", "MATHEMATICAL MONOSPACE DIGIT SEVEN", nil)
addSymbol(U(0x1D7FE), "ord", "mtteight", "MATHEMATICAL MONOSPACE DIGIT EIGHT", nil)
addSymbol(U(0x1D7FF), "ord", "mttnine", "MATHEMATICAL MONOSPACE DIGIT NINE", nil)
addSymbol(U(0x1EEF0), "ord", "arabicmaj", "ARABIC MATHEMATICAL OPERATOR MEEM WITH HAH WITH TATWEEL", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})
addSymbol(U(0x1EEF1), "ord", "arabichad", "ARABIC MATHEMATICAL OPERATOR HAH WITH DAL", {
  { form = "postfix", lspace = 0, priority = 920, rspace = 0, stretchy = true }})

return {
  operatorDict = operatorDict,
  symbols = symbols
}
