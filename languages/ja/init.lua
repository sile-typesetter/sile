-- "jlreq" refers to http://www.w3.org/TR/jlreq/
-- "JIS" refers to JIS X 4051

local base = require("languages.base")

local language = pl.class(base)
language._name = "ja"

function language:setupNodeMaker ()
   self.nodeMaker = require("languages.ja.nodemaker")
end

function language.registerCommands (_)
   SILE.registerCommand("book:chapter:post:ja", function (_, _)
      SILE.call("medskip")
   end, nil, nil, true)
end

return language
