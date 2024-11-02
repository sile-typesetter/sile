// Thin wrapper around user facing functions implemented in Rust to expose them in a loadable Lua
// module separate from the Rust CLI.

#![crate_type = "cdylib"]
#![crate_type = "rlib"]
#![crate_type = "staticlib"]

use mlua::prelude::*;

#[mlua::lua_module]
fn rusile(lua: &Lua) -> LuaResult<LuaTable> {
    sile::get_rusile_exports(lua)
}
