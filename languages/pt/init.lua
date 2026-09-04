SILE.nodeMakers.pt = pl.class(SILE.nodeMakers.unicode)

-- According to Portuguese rules, when a break occurs at an explicit hyphen, the hyphen gets repeated on the next line...
SILE.nodeMakers.pt.hasFeatureRepeatedHyphen = true

local hyphens = require("languages.pt.hyphens-tex")
SILE.hyphenator.languages["pt"] = hyphens
