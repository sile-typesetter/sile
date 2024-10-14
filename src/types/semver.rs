use mlua::prelude::*;
use semver::Version;
use std::ops::Deref;

#[derive(Clone, Debug)]
pub struct Semver {
    version: Version,
}

impl Semver {
    pub fn new(version: &str) -> crate::Result<Self> {
        Ok(Self {
            version: Version::parse(version)?,
        })
    }
}

//// TODO: cfg gate this so it only ends up in Lua module?
pub fn semver(version: String) -> crate::Result<Semver> {
    Ok(Semver::new(&version)?)
}

//fn use_registered_metatable(lua: &Lua) -> LuaResult<LuaTable> {
//    let key = "semver_type_metatable";
//    let metatable: LuaTable = match lua.named_registry_value(key)? {
//        LuaValue::Table(metatable) => metatable,
//        LuaValue::Nil => {
//            let metatable = lua.create_table()?;
//            metatable.set(
//                "__tostring",
//                lua.create_function(|_, arg: LuaTable| {
//                    let major: u16 = arg.get("major")?;
//                    let minor: u16 = arg.get("minor")?;
//                    let patch: u16 = arg.get("patch")?;
//                    Ok(format!("{}.{}.{}", major, minor, patch))
//                })?,
//            )?;
//            metatable.set(
//                "__eq",
//                lua.create_function(|_, _args: (LuaTable, LuaTable)| {
//                    //dbg!(args);
//                    //let major: u16 = args.0.get("major")?;
//                    //let minor: u16 = args.0.get("minor")?;
//                    //let patch: u16 = args.0.get("patch")?;
//                    Ok(false)
//                })?,
//            )?;
//            metatable.set(
//                "__le",
//                lua.create_function(|_, _args: (LuaTable, LuaTable)| {
//                    //dbg!(args);
//                    Ok(false)
//                })?,
//            )?;
//            metatable.set(
//                "__lt",
//                lua.create_function(|_, (a, b): (LuaTable, LuaTable)| {
//                    //let major_is_less: bool =
//                    //    args.0.get::<u16>("major")? < args.1.get::<u16>("major")?;
//                    //let m: Semver = args.0;
//                    dbg!(a);
//                    //let _minor_is_less: bool =
//                    //    args.0.get::<u16>("minor")? < args.1.get::<u16>("minor")?;
//                    //let _patch_is_less: bool =
//                    //    args.0.get::<u16>("patch")? < args.1.get::<u16>("patch")?;
//                    //Ok(major_is_less)
//                    Ok(false)
//                })?,
//            )?;
//            lua.set_named_registry_value(key, &metatable)?;
//            metatable
//        }
//        _ => unreachable!(),
//    };
//    Ok(metatable)
//}

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

        methods.add_meta_method(LuaMetaMethod::Lt, |_, this, other: Self| {
            Ok(this.version < other.version)
        });
    }
}

//impl IntoLua for Semver {
//    fn into_lua(self, lua: &Lua) -> LuaResult<LuaValue> {
//        let semver = lua.create_table()?;
//        semver.set("major", self.version.major)?;
//        semver.set("minor", self.version.minor)?;
//        semver.set("patch", self.version.patch)?;
//        //let metatable: mlua::Table = use_registered_metatable(&lua)?;
//        //semver.set_metatable(Some(metatable));
//        Ok(LuaValue::Table(semver))
//    }
//}

impl FromLua for Semver {
    fn from_lua(value: LuaValue, _: &Lua) -> LuaResult<Self> {
        match value {
            LuaValue::UserData(ud) => Ok(ud.borrow::<Semver>()?.deref().clone()),
            LuaValue::Table(_t) => todo!("implement for legacy Lua table based implementation"),
            _ => unreachable!(),
        }
    }
}
