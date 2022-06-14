package = "sile"
description = {
  summary = "Simon’s Improved Layout Engine",
  license = "MIT"
}
version = "dev-1"
source = {
  url = "..."
}
dependencies = {
  "lua >= 5.1",
  "bit32", -- only required on Lua < 5.2, versions vary between Rock and VM provided
  "cassowary == 2.3.2-1",
  "cldr == 0.2.0-0",
  "compat53 == 0.8-1", -- only required on Lua < 5.3
  "cosmo == 16.06.04-1",
  "fluent == 0.2.0-0",
  "linenoise == 0.9-1",
  "loadkit == 1.1.0-1",
  "lpeg == 1.0.2-1",
  "lua-zlib == 1.2-2",
  "lua_cliargs == 3.0-2",
  "luaepnf == 0.3-2",
  "luaexpat == 1.4.1-1",
  "luafilesystem == 1.8.0-1",
  "luarepl == 0.10-1",
  "luasec == 1.1.0-1",
  "luasocket == 3.0.0-1",
  "luautf8 == 0.1.3-1",
  "penlight == 1.12.0-2",
  "stdlib == 41.2.2-1",
  "vstruct == 2.1.1-1"
}
build = {
  type = "builtin",
  modules = {}
}
