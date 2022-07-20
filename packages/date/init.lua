local base = require("packages.base")

local package = pl.class(base)
package._name = "date"

local localeify = function (lang)
  lang = lang == "en-u-va-posix" and "en" or lang
  return lang .. "_" .. string.upper(lang) ..  ".utf-8"
end

local date = function (class, options)
  if not options then
    SU.deprecated("class.date", "class:date", "0.13.0", "0.15.0")
    options = class
  end
  options.format = options.format or "%c"
  options.time = options.time or os.time()
  options.locale = options.locale or localeify(SILE.settings:get("document.language"))
  os.setlocale(options.locale, "time")
  return os.date(options.format, options.time)
end

function package:_init (class)

  base._init(self, class)

  --exports
  date = date

end

function package:registerCommands ()

  self.class:registerCommand("date", function (options, _)
    local datestring = self.class:date(options)
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
