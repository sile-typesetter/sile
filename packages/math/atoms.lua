local atomType = {
   ordinary = 0,
   bigOperator = 1,
   binaryOperator = 2,
   relationalOperator = 3,
   openingSymbol = 4,
   closeSymbol = 5,
   punctuationSymbol = 6,
   inner = 7,
   overSymbol = 8,
   underSymbol = 9,
   accentSymbol = 10,
   radicalSymbol = 11,
   vcenter = 12,
}

-- Shorthands for atom types, used in the `atom` command option
-- and also in the unicode symbols table / operator dictionary
local atomTypeShort = {
   ord = atomType.ordinary,
   big = atomType.bigOperator,
   bin = atomType.binaryOperator,
   rel = atomType.relationalOperator,
   open = atomType.openingSymbol,
   close = atomType.closeSymbol,
   punct = atomType.punctuationSymbol,
   inner = atomType.inner,
   over = atomType.overSymbol,
   under = atomType.underSymbol,
   accent = atomType.accentSymbol,
   radical = atomType.radicalSymbol,
   vcenter = atomType.vcenter,
}

return {
   atomType = atomType,
   atomTypeShort = atomTypeShort,
}
