use clap::CommandFactory;
use mlua::prelude::*;

use sile::cli::Cli;

fn main() -> sile::Result<()> {
    let version = option_env!("VERGEN_GIT_SEMVER").unwrap_or_else(|| env!("VERGEN_BUILD_SEMVER"));
    let app = Cli::command().version(version);
    #[allow(unused_variables)]
    let matches = app.get_matches();
    sile_lua()?;
    Ok(())
}

fn sile_lua() -> LuaResult<()> {
    let lua = Lua::new();
    lua.load("print('Hello, world!')").exec()?;
    Ok(())
}
