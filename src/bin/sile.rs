use clap::CommandFactory;

use sile::cli::Cli;

fn main() -> sile::Result<()> {
    let version = option_env!("VERGEN_GIT_SEMVER").unwrap_or_else(|| env!("VERGEN_BUILD_SEMVER"));
    let app = Cli::command().version(version);
    let matches = app.get_matches();
    println!("Hello, world!");
    Ok(())
}
