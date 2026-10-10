use std::num::{NonZeroU32, TryFromIntError};

use derive_more::{Deref, Display};
use mlua::prelude::*;

/// A 1-based page number, between 1 and the number of pages in a PDF document.
///
/// The backing [`NonZeroU32`] guarantees the page number is always positive;
/// `TryFrom<u32>` rejects `0`. The [`Default`] page number is `1`, used when
/// casting from a nil Lua value.
#[derive(Clone, Copy, Debug, Deref, Display)]
pub struct PageNo(NonZeroU32);

impl Default for PageNo {
    fn default() -> Self {
        Self(NonZeroU32::MIN)
    }
}

impl From<NonZeroU32> for PageNo {
    fn from(page: NonZeroU32) -> Self {
        Self(page)
    }
}

impl From<PageNo> for u32 {
    fn from(page: PageNo) -> Self {
        page.get()
    }
}

impl TryFrom<u32> for PageNo {
    type Error = TryFromIntError;

    fn try_from(page: u32) -> Result<Self, Self::Error> {
        Ok(Self(NonZeroU32::try_from(page)?))
    }
}

impl FromLua for PageNo {
    fn from_lua(value: LuaValue, _: &Lua) -> LuaResult<Self> {
        let positive = |page: u32| {
            NonZeroU32::new(page)
                .map(PageNo)
                .ok_or_else(|| LuaError::external("page number must be a positive integer"))
        };
        match value {
            LuaValue::Nil => Ok(Self::default()),
            LuaValue::Integer(i) => {
                let page = u32::try_from(i).map_err(LuaError::external)?;
                positive(page)
            }
            LuaValue::Number(n) => positive(n as u32),
            other => Err(LuaError::FromLuaConversionError {
                from: other.type_name(),
                to: "page number".into(),
                message: Some("expected a page number".into()),
            }),
        }
    }
}

/// A measurement in fixed typesetting points (`pt`), 1/72 of an inch.
///
/// Convert to a plain `f64` with [`From<Points> for f64`] when passing it to a
/// library that wants a bare number. When converting to a Lua Value it will
/// automatically be a SILE.types.measurement with points as the unit.
#[derive(Clone, Copy, Debug, Deref, PartialEq)]
pub struct Points(f64);

impl From<f64> for Points {
    fn from(value: f64) -> Self {
        Self(value)
    }
}

impl From<Points> for f64 {
    fn from(value: Points) -> Self {
        value.0
    }
}

impl IntoLua for Points {
    fn into_lua(self, lua: &Lua) -> LuaResult<LuaValue> {
        let table = lua.create_table()?;
        table.set("amount", self.0)?;
        table.set("unit", "pt")?;
        table.set("relative", false)?;
        table.set("_mutable", true)?;
        let measurement: Option<LuaTable> = match lua.globals().get::<Option<LuaTable>>("SILE")? {
            Some(sile) => match sile.get::<Option<LuaTable>>("types")? {
                Some(types) => types.get::<Option<LuaTable>>("measurement")?,
                None => None,
            },
            None => None,
        };
        if let Some(measurement) = measurement {
            table.set_metatable(Some(measurement))?;
        }
        Ok(LuaValue::Table(table))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn page_no_rejects_zero() {
        assert!(PageNo::try_from(0).is_err());
        assert!(PageNo::try_from(1).is_ok());
    }

    #[test]
    fn page_no_defaults_to_one() {
        let page = PageNo::default();
        assert_eq!(page.get(), 1u32);
    }

    #[test]
    fn page_no_derefs_to_non_zero_u32() {
        fn needs_non_zero(n: &NonZeroU32) -> u32 {
            n.get()
        }
        let page = PageNo::try_from(3).unwrap();
        assert_eq!(needs_non_zero(&page), 3);
    }

    #[test]
    fn page_no_from_non_zero_u32() {
        let page = PageNo::from(NonZeroU32::new(3).unwrap());
        assert_eq!(page.get(), 3u32);
    }

    #[test]
    fn page_no_displays_as_its_integer() {
        let page = PageNo::try_from(3).unwrap();
        assert_eq!(page.to_string(), "3");
    }

    #[test]
    fn page_no_from_lua_defaults_to_one() {
        let lua = Lua::new();
        let page = PageNo::from_lua(LuaValue::Nil, &lua).unwrap();
        assert_eq!(page.get(), 1u32);
    }

    #[test]
    fn page_no_from_lua_accepts_a_positive_integer() {
        let lua = Lua::new();
        let page = PageNo::from_lua(LuaValue::Integer(3), &lua).unwrap();
        assert_eq!(page.get(), 3u32);
    }

    #[test]
    fn page_no_from_lua_rejects_zero_and_negative_integers() {
        let lua = Lua::new();
        assert!(PageNo::from_lua(LuaValue::Integer(0), &lua).is_err());
        assert!(PageNo::from_lua(LuaValue::Integer(-1), &lua).is_err());
    }

    #[test]
    fn points_convert_to_and_from_f64() {
        let points = Points::from(3.5);
        assert_eq!(*points, 3.5);
        assert_eq!(f64::from(points), 3.5);
    }

    #[test]
    fn points_into_lua_builds_a_pt_measurement() {
        let lua = Lua::new();
        let value = Points::from(3.5).into_lua(&lua).unwrap();
        let table: LuaTable = LuaTable::from_lua(value, &lua).unwrap();
        assert_eq!(table.get::<f64>("amount").unwrap(), 3.5);
        assert_eq!(table.get::<String>("unit").unwrap(), "pt");
        assert!(!table.get::<bool>("relative").unwrap());
        assert!(table.get::<bool>("_mutable").unwrap());
    }
}
