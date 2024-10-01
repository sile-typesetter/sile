SILE.nodeMakers.sk = pl.class(SILE.nodeMakers.unicode)

-- According to Slovak rules, when a break occurs at an explicit hyphen, the hyphen gets repeated on the next line...
SILE.nodeMakers.sk.handleWordBreak = SILE.nodeMakers.unicode._handleWordBreakRepeatHyphen
SILE.nodeMakers.sk.handlelineBreak = SILE.nodeMakers.unicode._handlelineBreakRepeatHyphen

local hyphens = require("languages.sk.hyphens-tex")
SILE.hyphenator.languages["sk"] = hyphens
