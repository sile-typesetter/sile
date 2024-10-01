SILE.nodeMakers.pt = pl.class(SILE.nodeMakers.unicode)

-- According to Portuguese rules, when a break occurs at an explicit hyphen, the hyphen gets repeated on the next line...
SILE.nodeMakers.pt.handleWordBreak = SILE.nodeMakers.unicode._handleWordBreakRepeatHyphen
SILE.nodeMakers.pt.handlelineBreak = SILE.nodeMakers.unicode._handlelineBreakRepeatHyphen

local hyphens = require("languages.pt.hyphens")
SILE.hyphenator.languages["pt"] = hyphens
