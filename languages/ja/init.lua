-- "jlreq" refers to http://www.w3.org/TR/jlreq/
-- "JIS" refers to JIS X 4051

local unicode = require("languages.unicode")

local language = pl.class(unicode)
language._name = "ja"

function language:setupNodeMaker ()
   self.nodemaker = require("languages.ja.nodemaker")
end

function language.registerCommands (_)
   SILE.registerCommand("book:chapter:post:ja", function (_, _)
      SILE.call("medskip")
   end, nil, nil, true)
end

return language
