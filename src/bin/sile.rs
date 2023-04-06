use clap::CommandFactory;
use mlua::prelude::*;

use sile::cli::Cli;

fn main() -> sile::Result<()> {
    let version = option_env!("VERGEN_GIT_SEMVER").unwrap_or_else(|| env!("VERGEN_BUILD_SEMVER"));
    let app = Cli::command().version(version);
    #[allow(unused_variables)]
    let matches = app.get_matches();
    sile()?;
    Ok(())
}

fn sile() -> LuaResult<()> {
    let lua = unsafe { Lua::unsafe_new() };
    lua.load(
        r#"
        package.path = ";;./?.lua;./?/init.lua;./lua-libraries/?.lua;./lua-libraries/?/init.lua;./lua_modules/share/lua/5.4/?.lua;./lua_modules/share/lua/5.4/?/init.lua"
        package.cpath = ";;./?.so;./lua_modules/lib/lua/5.4/?.so"
        require("core.sile")
        SU.dump(SILE)
        "#,
    )
    .exec()?;
    Ok(())
}
