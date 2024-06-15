#![crate_type = "cdylib"]
#![crate_type = "rlib"]
#![crate_type = "staticlib"]

use mlua::prelude::*;

#[mlua::lua_module]
fn rusile(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table().unwrap();
    let demo: LuaFunction = lua.create_function(demo).unwrap();
    exports.set("demo", demo)?;
    Ok(exports)
}

fn demo(lua: &Lua, (): ()) -> LuaResult<LuaString> {
    let res = rusile_demo().unwrap();
    lua.create_string(res)
}
