std = "lua53"
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
  "lua_modules_dist",
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
  "std",
  "pl",
  "bit",
  "SYSTEM_SILE_PATH",
  "SHARED_LIB_EXT",
  "ProFi"
}
max_line_length = false
