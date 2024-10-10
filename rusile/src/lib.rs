#![crate_type = "cdylib"]
#![crate_type = "rlib"]
#![crate_type = "staticlib"]

use mlua::prelude::*;

#[mlua::lua_module]
fn rusile(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table().unwrap();
    exports.set("demo", LuaFunction::wrap_raw(sile::rusile_demo))?;
    exports.set("foo", LuaFunction::wrap_raw(sile::types::semver::foo))?;
    Ok(exports)
}
