#![crate_type = "cdylib"]
#![crate_type = "rlib"]
#![crate_type = "staticlib"]

use mlua::prelude::*;

#[mlua::lua_module]
fn rusile(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table().unwrap();
    Ok(exports)
}
