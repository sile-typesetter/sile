SILE.nodeMakers.cs = pl.class(SILE.nodeMakers.unicode)

-- According to Czech rules, when a break occurs at an explicit hyphen, the hyphen gets repeated on the next line...
SILE.nodeMakers.cs.handleWordBreak = SILE.nodeMakers.unicode._handleWordBreakRepeatHyphen
SILE.nodeMakers.cs.handlelineBreak = SILE.nodeMakers.unicode._handlelineBreakRepeatHyphen

local hyphens = require("languages.cs.hyphens-tex")
SILE.hyphenator.languages["cs"] = hyphens
