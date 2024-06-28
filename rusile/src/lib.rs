#![crate_type = "cdylib"]
#![crate_type = "rlib"]
#![crate_type = "staticlib"]

use mlua::prelude::*;

#[mlua::lua_module]
fn rusile(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table().unwrap();
    let foo: LuaFunction = lua.create_function(foo).unwrap();
    exports.set("foo", foo)?;
    Ok(exports)
}

fn foo(lua: &Lua, (): ()) -> LuaResult<LuaString> {
    lua.create_string("Hello from rusile")
}
