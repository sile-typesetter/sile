local date = function (options)
  options.format = options.format or "%c"
  options.time = options.time or os.time()
  options.locale = options.locale or localeify(SILE.settings.get("document.language"))
  os.setlocale(options.locale, "time")
  return os.date(options.format, options.time)
end

local localeify = function (lang)
  lang = lang == "en-u-va-posix" and "en" or lang
  return lang .. "_" .. string.upper(lang) ..  ".utf-8"
end

SILE.registerCommand("date", function(options, content)
  SILE.typesetter:typeset(date(options))
end, "Output a timestamp using the system date function")

return {
  exports = {
    date = date
  }
}
