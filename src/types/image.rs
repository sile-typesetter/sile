use mlua::prelude::*;

/// The bounding box of an image or PDF page, in PDF points (1/72 inch).
///
/// For raster images the lower-left corner is always `(0, 0)` and the upper-right
/// corner is the pixel size scaled to points. `xdpi`/`ydpi` carry the density
/// when it is known, and are `None` for PDF documents.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ImageBBox {
    pub llx: f64,
    pub lly: f64,
    pub urx: f64,
    pub ury: f64,
    pub xdpi: Option<f64>,
    pub ydpi: Option<f64>,
}

/// Convert [`ImageBBox`] to six unpacked Lua values `llx`, `lly`, `urx`, `ury`, `xdpi`, `ydpi`,
/// with `None` resolutions arriving as `nil`.
impl IntoLuaMulti for ImageBBox {
    fn into_lua_multi(self, lua: &Lua) -> LuaResult<LuaMultiValue> {
        let mut values = LuaMultiValue::new();
        for v in [self.llx, self.lly, self.urx, self.ury] {
            values.push_back(v.into_lua(lua)?);
        }
        values.push_back(self.xdpi.into_lua(lua)?);
        values.push_back(self.ydpi.into_lua(lua)?);
        Ok(values)
    }
}
