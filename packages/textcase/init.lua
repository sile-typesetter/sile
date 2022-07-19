local icu = require("justenoughicu")

local uppercase = function (input, extraArgs)
  if not extraArgs then extraArgs = {} end
  if not extraArgs.options then extraArgs.options = {} end
  local lang = extraArgs.options.language or SILE.settings:get("document.language")
  return icu.case(input, lang, "upper")
end

local lowercase = function (input, extraArgs)
  if not extraArgs then extraArgs = {} end
  if not extraArgs.options then extraArgs.options = {} end
  local lang = extraArgs.options.language or SILE.settings:get("document.language")
  return icu.case(input, lang, "lower")
end

local titlecase = function (input, extraArgs)
  if not extraArgs then extraArgs = {} end
  if not extraArgs.options then extraArgs.options = {} end
  local lang = extraArgs.options.language or SILE.settings:get("document.language")
  return icu.case(input, lang, "title")
end

local function init (class, _)

  class:loadPackage("inputfilter")

end

local function registerCommands (class)

  class:registerCommand("uppercase", function(options, content)
    SILE.process(class.transformContent(content, uppercase, options))
  end, "Typeset the enclosed text as uppercase")

  class:registerCommand("lowercase", function(options, content)
    SILE.process(class.transformContent(content, lowercase, options))
  end, "Typeset the enclosed text as lowercase")

  class:registerCommand("titlecase", function(options, content)
    SILE.process(class.transformContent(content, titlecase, options))
  end, "Typeset the enclosed text as titlecase")

end

return {
  init = init,
  registerCommands = registerCommands,
  exports = {
    uppercase = uppercase,
    lowercase = lowercase,
    titlecase = titlecase
  },
  documentation = [[
\begin{document}
\script[src=packages/textcase]
The \autodoc:package{textcase} package provides commands for language-aware case conversion
of input text. For example, when language is set to English, then
\autodoc:command{\uppercase{hij}} will return \examplefont{\uppercase{hij}}. However,
when language is set to Turkish, it will return
\examplefont{\font[language=tr]{\uppercase{hij}}}.

As well as \autodoc:command{\uppercase}, the package provides the commands \autodoc:command{\lowercase}
and \autodoc:command{\titlecase}.
\end{document}
]]
}

