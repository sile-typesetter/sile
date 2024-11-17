local atomType = {
   ordinary = 0,
   bigOperator = 1, -- Misnamed used for TeX's "mathop"
   binaryOperator = 2,
   relationalOperator = 3,
   openingSymbol = 4,
   closeSymbol = 5,
   punctuationSymbol = 6,
   inner = 7, -- Unused for now (used for fractions in The TeXbook)
   overSymbol = 8, -- Unused for now (used for overlines etc. in The TeXbook)
   underSymbol = 9, -- Unused for now (used for underlines etc. in The TeXbook)
   accentSymbol = 10,
   botAccentSymbol = 11, -- Unused for now but botaccent is encoded in our dictionary
}

-- Shorthands for atom types, used in the `atom` command option
-- and also in the unicode symbols table / operator dictionary
local atomTypeShort = {
   ord = atomType.ordinary,
   op = atomType.bigOperator,
   bin = atomType.binaryOperator,
   rel = atomType.relationalOperator,
   open = atomType.openingSymbol,
   close = atomType.closeSymbol,
   punct = atomType.punctuationSymbol,
   inner = atomType.inner,
   over = atomType.overSymbol,
   under = atomType.underSymbol,
   accent = atomType.accentSymbol,
   botaccent = atomType.botAccentSymbol,
}

return {
   atomType = atomType,
   atomTypeShort = atomTypeShort,
}
