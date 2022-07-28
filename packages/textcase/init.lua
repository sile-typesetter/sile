local base = require("packages.base")

local package = pl.class(base)
package._name = "tetxcase"

local icu = require("justenoughicu")

local uppercase = function (class, input, extraArgs)
  if type(class) ~= "table" or class.type ~= "class" then
    input, extraArgs = class, input
  end
  if not extraArgs then extraArgs = {} end
  if not extraArgs.options then extraArgs.options = {} end
  local lang = extraArgs.options.language or SILE.settings:get("document.language")
  return icu.case(input, lang, "upper")
end

local lowercase = function (class, input, extraArgs)
  if type(class) == "table" and class.type ~= "class" then
    input, extraArgs = class, input
  end
  if not extraArgs then extraArgs = {} end
  if not extraArgs.options then extraArgs.options = {} end
  local lang = extraArgs.options.language or SILE.settings:get("document.language")
  return icu.case(input, lang, "lower")
end

local titlecase = function (class, input, extraArgs)
  if type(class) == "table" and class.type ~= "class" then
    input, extraArgs = class, input
  end
  if not extraArgs then extraArgs = {} end
  if not extraArgs.options then extraArgs.options = {} end
  local lang = extraArgs.options.language or SILE.settings:get("document.language")
  return icu.case(input, lang, "title")
end

function package:_init ()
  base._init(self)
  self.class:loadPackage("inputfilter")
  self:deprecatedExport("uppercase", uppercase)
  self:deprecatedExport("lowercase", lowercase)
  self:deprecatedExport("titlecase", titlecase)
end

function package:registerCommands ()

  self:registerCommand("uppercase", function(options, content)
    SILE.process(self.class.packages.inputfilter:transformContent(content, uppercase, options))
  end, "Typeset the enclosed text as uppercase")

  self:registerCommand("lowercase", function(options, content)
    SILE.process(self.class.packages.inputfilter:transformContent(content, lowercase, options))
  end, "Typeset the enclosed text as lowercase")

  self:registerCommand("titlecase", function(options, content)
    SILE.process(self.class.packages.inputfilter:transformContent(content, titlecase, options))
  end, "Typeset the enclosed text as titlecase")

end

package.documentation = [[
\begin{document}
\use[module=packages.textcase]
The \autodoc:package{textcase} package provides commands for language-aware case conversion of input text.
For example, when language is set to English, then \autodoc:command{\uppercase{hij}} will return \examplefont{\uppercase{hij}}.
However, when language is set to Turkish, it will return \examplefont{\font[language=tr]{\uppercase{hij}}}.

As well as \autodoc:command{\uppercase}, the package provides the commands \autodoc:command{\lowercase} and \autodoc:command{\titlecase}.
\end{document}
]]

return package
