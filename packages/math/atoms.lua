-- Shorthands for atom types, used in the `atom` command option
-- and also in the unicode symbols table / operator dictionary
local atomType = {
   -- The 8 atom types defined in the TeXbook's spacing table
   ord = 0,
   op = 1,
   bin = 2,
   rel = 3,
   open = 4,
   close = 5,
   punct = 6,
   inner = 7, -- Unused for now (used for fractions in The TeXbook)
   -- Other atom types (considered as "ord" for spacing)
   over = 8, -- Unused for now (used for overlines etc. in The TeXbook)
   under = 9, -- Unused for now (used for underlines etc. in The TeXbook)
   accent = 10,
   botaccent = 11, -- Unused for now but botaccent is encoded in our dictionary
}

return { types = atomType }
