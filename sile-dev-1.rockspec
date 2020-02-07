package = "sile"
version = "dev-1"
source = {
	url = "..."
}
dependencies = {
  "lua >= 5.1",
  "bit32",
  "lpeg == 1.0.2-1",
  "cassowary == 2.2-1",
  "cosmo == 16.06.04-1",
  "compat53 == 0.7-1",
  "linenoise == 0.9-1",
  "lua-zlib == 1.2-0",
  "lua_cliargs == 2.3-3",
  "luaepnf == 0.3-1",
  "luaexpat == 1.3.3-1",
  "luafilesystem == 1.7.0-2",
  "luarepl == 0.9-1",
  "luasec == 0.8.1-1",
  "luasocket == 3.0rc1-2",
  "penlight == 1.7.0-1",
  "stdlib == 41.2.2-1",
  "vstruct == 2.0.1-1"
}
build = {
	type = "builtin",
	modules = {}
}
