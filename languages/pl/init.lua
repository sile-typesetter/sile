SILE.nodeMakers.pl = pl.class(SILE.nodeMakers.unicode)
-- According to Polish rules, when a break occurs at an explicit hyphen, the hyphen gets repeated on the next line...
SILE.nodeMakers.pl.hasFeatureRepeatedHyphen = true

local hyphens = require("languages.pl.hyphens-tex")
SILE.hyphenator.languages["pl"] = hyphens
