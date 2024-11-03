SILE.nodeMakers.pl = pl.class(SILE.nodeMakers.unicode)

-- According to Polish rules, when a break occurs at an explicit hyphen, the hyphen gets repeated on the next line...
SILE.nodeMakers.pl.handleWordBreak = SILE.nodeMakers.unicode._handleWordBreakRepeatHyphen
SILE.nodeMakers.pl.handlelineBreak = SILE.nodeMakers.unicode._handlelineBreakRepeatHyphen

local hyphens = require("languages.pl.hyphens-tex")
SILE.hyphenator.languages["pl"] = hyphens
