#![crate_type = "cdylib"]
#![crate_type = "rlib"]
#![crate_type = "staticlib"]

use mlua::prelude::*;
use sile::rusile_demo;

#[mlua::lua_module]
fn rusile(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table().unwrap();
    let foo: LuaFunction = lua.create_function(foo).unwrap();
    exports.set("foo", foo)?;
    Ok(exports)
}

fn foo(lua: &Lua, (): ()) -> LuaResult<LuaString> {
    let s = rusile_demo();
    lua.create_string(s)
}
