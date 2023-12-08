std = "min"
include_files = {
  "**/*.lua",
  "sile.in",
  "*.rockspec",
  ".busted",
  ".luacheckrc"
}
exclude_files = {
  "benchmark-*",
  "compare-*",
  "sile-*",
  "target",
  "lua_modules",
  "lua-libraries",
  ".lua",
  ".luarocks",
  ".install"
}
files["**/*_spec.lua"] = {
  std = "+busted"
}
globals = {
  package = { fields = { "searchpath" } },
  "SILE",
  "SU",
  "luautf8",
  "pl",
  "fluent",
  "extendSilePath",
  "executablePath",
  "SYSTEM_SILE_PATH",
  "SHARED_LIB_EXT"
}
max_line_length = false
ignore = {
  "581" -- operator order warning doesn't account for custom table metamethods
}
-- vim: ft=lua
