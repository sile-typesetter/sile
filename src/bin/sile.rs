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
        package.path = "./?.lua"
        require("core.pathsetup")()
        SILE = require("core.sile")
        io.stderr:write(" [ Rust ]" .. SILE.full_version .. '\n')
        SILE.init()
        SILE.masterFilename = "tests/absmin"
        SILE.masterDir = "tests"
        SILE.input.filename = "tests/absmin.xml"
        SILE.processFile(SILE.input.filename)
        SILE.outputter:finish()
        SILE.finish()
        "#,
    )
    .exec()?;
    Ok(())
}
