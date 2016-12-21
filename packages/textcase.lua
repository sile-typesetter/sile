local icu = require("justenoughicu")
local inputfilter = SILE.require("packages/inputfilter").exports

local uppercase = function (input)
  return icu.case(input, SILE.settings.get("document.language"), "upper")
end

local lowercase = function (input)
  return icu.case(input, SILE.settings.get("document.language"), "lower")
end

local titlecase = function (input)
  return icu.case(input, SILE.settings.get("document.language"), "title")
end

SILE.registerCommand("uppercase", function(options, content)
  SILE.process(inputfilter.transformContent(content, uppercase))
end, "Typeset the enclosed text as uppercase")

SILE.registerCommand("lowercase", function(options, content)
  SILE.process(inputfilter.transformContent(content, lowercase))
end, "Typeset the enclosed text as lowercase")

SILE.registerCommand("titlecase", function(options, content)
  SILE.process(inputfilter.transformContent(content, titlecase))
end, "Typeset the enclosed text as titlecase")

return {
  exports = {
    uppercase = uppercase,
    lowercase = lowercase,
    titlecase = titlecase
  }
}

