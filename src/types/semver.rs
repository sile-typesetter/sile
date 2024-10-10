use mlua::prelude::*;
use semver::Version;
use std::ops::Deref;

#[derive(Clone, Debug)]
pub struct Semver {
    version: Version,
}

impl Semver {
    pub fn new(version: &str) -> crate::Result<Self> {
        let version = version.strip_prefix("v").unwrap_or(version);
        Ok(Self {
            version: Version::parse(version)?,
        })
    }
}

// TODO: cfg gate this so it only ends up in Lua module?
pub fn semver(version: String) -> crate::Result<Semver> {
    Ok(Semver::new(&version)?)
}

impl Deref for Semver {
    type Target = Version;
    fn deref(&self) -> &Version {
        &self.version
    }
}

impl LuaUserData for Semver {
    fn add_fields<F: LuaUserDataFields<Self>>(fields: &mut F) {
        fields.add_field_method_get("major", |_, this| Ok(this.version.major));
        fields.add_field_method_get("minor", |_, this| Ok(this.version.minor));
        fields.add_field_method_get("patch", |_, this| Ok(this.version.patch));
    }

    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(this.version.to_string())
        });

        methods.add_meta_method(LuaMetaMethod::Eq, |_, this, other: Self| {
            Ok(this.version == other.version)
        });

        methods.add_meta_method(LuaMetaMethod::Le, |_, this, other: Self| {
            Ok(this.version <= other.version)
        });

        methods.add_meta_method(LuaMetaMethod::Lt, |_, this, other: Self| {
            Ok(this.version < other.version)
        });
    }
}

impl FromLua for Semver {
    fn from_lua(value: LuaValue, _: &Lua) -> LuaResult<Self> {
        match value {
            LuaValue::UserData(ud) => Ok(ud.borrow::<Self>()?.clone()),
            LuaValue::Table(_t) => todo!("implement for legacy Lua table based implementation"),
            _ => unreachable!(),
        }
    }
}
