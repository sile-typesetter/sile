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
  "bit32",
  "cassowary == 2.3.1-2",
  "cldr == 0.1.0",
  "compat53 == 0.8-1",
  "cosmo == 16.06.04-1",
  "fluent == 0.1.1",
  "linenoise == 0.9-1",
  "lpeg == 1.0.2-1",
  "lua-zlib == 1.2-1",
  "lua_cliargs == 3.0-2",
  "luaepnf == 0.3-2",
  "luaexpat == 1.3.3-1",
  "luafilesystem == 1.8.0-1",
  "luarepl == 0.9-1",
  "luasec == 1.0-1",
  "luasocket == 3.0rc1-2",
  "luautf8 == 0.1.3",
  "penlight == 1.12.0-1",
  "stdlib == 41.2.2-1",
  "vstruct == 2.1.1-1"
}
build = {
  type = "builtin",
  modules = {}
}
