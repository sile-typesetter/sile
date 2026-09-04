SILE.nodeMakers.es = pl.class(SILE.nodeMakers.unicode)

-- According to Spanish rules, when a break occurs at an explicit hyphen, the hyphen gets repeated on the next line...
SILE.nodeMakers.es.hasFeatureRepeatedHyphen = true

local hyphens = require("languages.es.hyphens-tex")
SILE.hyphenator.languages["es"] = hyphens
