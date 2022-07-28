local base = require("packages.base")

local package = pl.class(base)
package._name = "date"

local localeify = function (lang)
  lang = lang == "en-u-va-posix" and "en" or lang
  return lang .. "_" .. string.upper(lang) ..  ".utf-8"
end

function package.date (_, options)
  options.format = options.format or "%c"
  options.time = options.time or os.time()
  options.locale = options.locale or localeify(SILE.settings:get("document.language"))
  os.setlocale(options.locale, "time")
  return os.date(options.format, options.time)
end

function package:_init ()

  base._init(self)

  self:deprecatedExport("date", self.date)

end

function package:registerCommands ()

  self.class:registerCommand("date", function (options, _)
    local datestring = self:date(options)
    SILE.typesetter:typeset(datestring)
  end, "Output a timestamp using the system date function")

end

package.documentation = [[
\begin{document}
The \autodoc:package{date} package provides the \autodoc:command{\date} command, which simply outputs the date using the system’s date function.
You can customize the format by passing the \autodoc:parameter{format} parameter, following the formatting codes in the Lua manual.
(\url{https://www.lua.org/pil/22.1.html})
\end{document}
]]

return package
