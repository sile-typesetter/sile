std = "max"
include_files = {
  "**/*.lua",
  "sile.in",
  "*.rockspec",
  ".luacheckrc"
}
exclude_files = {
  "lua_modules",
  "lua-libraries"
}
globals = {
  "SILE",
  "SU",
  "std",
  "pl",
  "bit32",
  "SYSTEM_SILE_PATH",
  "SHARED_LIB_EXT",
  "ProFi"
}
max_line_length = false
