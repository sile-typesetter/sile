use mlua::prelude::*;
use semver::Version;
use std::ops::Deref;

#[derive(Debug)]
pub struct Semver {
    pub version: Version,
}

impl Semver {
    pub fn new(version: &str) -> crate::Result<Self> {
        Ok(Self {
            version: Version::parse(version)?,
        })
    }
}

// TODO: cfg gate this so it only ends up in Lua module?
pub fn semver(version: String) -> crate::Result<Semver> {
    Ok(Semver::new(&version)?)
}

fn use_registered_metatable(lua: &Lua) -> LuaResult<LuaTable> {
    let key = "semver_type_metatable";
    let metatable: LuaTable = match lua.named_registry_value(key)? {
        LuaValue::Table(metatable) => metatable,
        LuaValue::Nil => {
            let metatable = lua.create_table()?;
            let to_string = lua.create_function(|_, luaself: LuaTable| {
                let major: u8 = luaself.get("major")?;
                let minor: u8 = luaself.get("minor")?;
                let patch: u8 = luaself.get("patch")?;
                Ok(format!("{}.{}.{}", major, minor, patch))
            })?;
            metatable.set("__tostring", to_string)?;
            let equal_to = lua.create_function(|_, args: (LuaTable, LuaTable)| {
                dbg!(args);
                //let major: u8 = args.0.get("major")?;
                //let minor: u8 = args.0.get("minor")?;
                //let patch: u8 = args.0.get("patch")?;
                Ok(false)
            })?;
            metatable.set("__eq", equal_to)?;
            let less_equal = lua.create_function(|_, args: (LuaTable, LuaTable)| {
                dbg!(args);
                Ok(false)
            })?;
            metatable.set("__le", less_equal)?;
            let less_than = lua.create_function(|_, args: (LuaTable, LuaTable)| {
                dbg!(args);
                Ok(false)
                //let major1: u8 = args.0.get("major")?;
                //let major2: u8 = args.1.get("major")?;
                //Ok(major1 < major2)
            })?;
            metatable.set("__lt", less_than)?;
            lua.set_named_registry_value(key, &metatable)?;
            metatable
        }
        _ => panic!("Unexpected type return from registry lookup"),
    };
    Ok(metatable)
}

impl Deref for Semver {
    type Target = Version;
    fn deref(&self) -> &Version {
        &self.version
    }
}

impl IntoLua for Semver {
    #[inline]
    fn into_lua(self, lua: &Lua) -> LuaResult<LuaValue> {
        let semver = lua.create_table()?;
        semver.set("major", self.version.major)?;
        semver.set("minor", self.version.minor)?;
        semver.set("patch", self.version.patch)?;
        let metatable: mlua::Table = use_registered_metatable(&lua)?;
        semver.set_metatable(Some(metatable));
        Ok(LuaValue::Table(semver))
    }
}
