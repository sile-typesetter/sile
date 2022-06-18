std = "max"
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
  "lua_modules",
  "lua-libraries",
  ".lua",
  ".luarocks",
  ".install"
}
files["spec"] = {
  std = "+busted"
}
globals = {
  "SILE",
  "SU",
  "luautf8",
  "pl",
  "SYSTEM_SILE_PATH",
  "SHARED_LIB_EXT",
  "ProFi"
}
max_line_length = false
ignore = {
  "581"
}
