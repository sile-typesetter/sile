local base = require("packages.base")

local package = pl.class(base)
package._name = "date"

local localeify = function (lang)
   lang = lang == "en-u-va-posix" and "en" or lang
   return lang .. "_" .. string.upper(lang) .. ".utf-8"
end

function package:date (options)
   options.format = options.format or "%c"
   options.time = options.time or os.time()
   options.locale = options.locale or localeify(SILE.settings:get("document.language"))
   os.setlocale(options.locale, "time")
   return os.date(options.format, options.time)
end

function package:_init ()
   base._init(self)
end

function package:registerCommands ()
   self:registerCommand("date", function (options, _)
      local datestring = self:date(options)
      SILE.typesetter:typeset(datestring)
   end, "Output a timestamp using the system date function")
end

package.documentation = [[
\begin{document}
The \autodoc:package{date} package provides the \autodoc:command{\date} command, which simply outputs a date using the system’s date function.
It defaults to the current date and time, but can be used to format any other input time as well using the \autodoc:parameter{time} parameter.
You can customize the format by passing the \autodoc:parameter{format} parameter, following the formatting codes in the Lua manual
(\href{https://www.lua.org/pil/22.1.html}).
\end{document}
]]

return package
