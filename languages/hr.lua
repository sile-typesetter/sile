SILE.nodeMakers.hr = pl.class(SILE.nodeMakers.unicode)

-- According to Croatian rules, when a break occurs at an explicit hyphen, the hyphen gets repeated on the next line...
SILE.nodeMakers.hr.handleWordBreak = SILE.nodeMakers.unicode._handleWordBreakRepeatHyphen
SILE.nodeMakers.hr.handlelineBreak = SILE.nodeMakers.unicode._handlelineBreakRepeatHyphen

local hyphens = require("hyphens.misc.hr")
SILE.hyphenator.languages["hr"] = hyphens

