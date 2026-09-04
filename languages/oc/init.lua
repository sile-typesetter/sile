local hyphens = require("languages.oc.hyphens-tex")
SILE.hyphenator.languages["oc"] = hyphens

-- In modern revivals, Occitan usually follows the French conventions
-- for punctuation spacing.
require("languages.fr") -- HACK force loading of the French language node maker.
SILE.nodeMakers.oc = SILE.nodeMakers.fr
