local base = require("packages.base")

local package = pl.class(base)
package._name = "textcase"

local icu = require("justenoughicu")

function package:uppercase (input, extraArgs)
   if type(self) ~= "table" or (self.type ~= "class" and self.type ~= "package") then
      self, input, extraArgs = package, self, input
   end
   if not extraArgs then
      extraArgs = {}
   end
   if not extraArgs.options then
      extraArgs.options = {}
   end
   local lang = extraArgs.options.language or SILE.settings:get("document.language")
   return icu.case(input, lang, "upper")
end

function package:lowercase (input, extraArgs)
   if type(self) ~= "table" or (self.type ~= "class" and self.type ~= "package") then
      self, input, extraArgs = package, self, input
   end
   if not extraArgs then
      extraArgs = {}
   end
   if not extraArgs.options then
      extraArgs.options = {}
   end
   local lang = extraArgs.options.language or SILE.settings:get("document.language")
   return icu.case(input, lang, "lower")
end

function package:titlecase (input, extraArgs)
   if type(self) ~= "table" or (self.type ~= "class" and self.type ~= "package") then
      self, input, extraArgs = package, self, input
   end
   if not extraArgs then
      extraArgs = {}
   end
   if not extraArgs.options then
      extraArgs.options = {}
   end
   local lang = extraArgs.options.language or SILE.settings:get("document.language")
   return icu.case(input, lang, "title")
end

function package:_init ()
   base._init(self)
   self:loadPackage("inputfilter")
end

function package:registerCommands ()
   self:registerCommand("uppercase", function (options, content)
      SILE.process(self.class.packages.inputfilter:transformContent(content, self.uppercase, options))
   end, "Typeset the enclosed text as uppercase")

   self:registerCommand("lowercase", function (options, content)
      SILE.process(self.class.packages.inputfilter:transformContent(content, self.lowercase, options))
   end, "Typeset the enclosed text as lowercase")

   self:registerCommand("titlecase", function (options, content)
      SILE.process(self.class.packages.inputfilter:transformContent(content, self.titlecase, options))
   end, "Typeset the enclosed text as titlecase")
end

package.documentation = [[
\begin{document}
\use[module=packages.textcase]
The \autodoc:package{textcase} package provides commands for language-aware case conversion of input text.
For example, when language is set to English, then \autodoc:command{\uppercase{hij}} will return \autodoc:example{\uppercase{hij}}.
However, when language is set to Turkish, it will return \autodoc:example{\font[language=tr]{\uppercase{hij}}}.

As well as \autodoc:command{\uppercase}, the package provides the commands \autodoc:command{\lowercase} and \autodoc:command{\titlecase}.
\end{document}
]]

return package
