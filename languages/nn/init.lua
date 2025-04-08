local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "nn"

function language:setupHyphenator ()
   self.hyphenator = require("languages.base-hyphenator")(self)
   -- We're cheating and only have full hyphenation rules for 'no' (which the languages.nn.hyphens module will return)
   -- but 'nn' actually has some additional exceptions.
   self.hyphenator:registerException("att-en-de")
   self.hyphenator:registerException("bet-re")
end

return language
