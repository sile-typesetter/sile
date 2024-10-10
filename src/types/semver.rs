use mlua::prelude::*;
use semver::Version;

pub struct Semver {
    version: Version,
}

impl IntoLua for Semver {
    #[inline]
    fn into_lua(self, lua: &Lua) -> LuaResult<LuaValue> {
        let semver = lua.create_table()?;
        Ok(LuaValue::Table(semver))
        //"just an str".into_lua(lua)
    }
}

pub fn foo() -> crate::Result<()> {
    eprintln!("Run");
    Ok(())
}
