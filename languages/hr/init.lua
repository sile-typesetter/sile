SILE.nodeMakers.hr = pl.class(SILE.nodeMakers.unicode)

-- According to Croatian rules, when a break occurs at an explicit hyphen, the hyphen gets repeated on the next line...
SILE.nodeMakers.hr.hasFeatureRepeatedHyphen = true

local hyphens = require("languages.hr.hyphens-tex")
SILE.hyphenator.languages["hr"] = hyphens
