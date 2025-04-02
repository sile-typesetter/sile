local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "ca"

function language:setupNodeMaker ()
   self.nodemaker = require("languages.ca.nodemaker")
end

function language:setupHyphenator ()
   self.hyphenator = require("languages.ca.hyphenator")(self)
end

return language
