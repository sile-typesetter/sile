use clap::{CommandFactory, FromArgMatches};

use sile::cli::Cli;
use sile::Result;

fn main() -> Result<()> {
    let version = option_env!("VERGEN_GIT_DESCRIBE").unwrap_or_else(|| env!("CARGO_PKG_VERSION"));
    let version = version.replacen('-', ".r", 1);
    let long_version = sile::version()?
        .strip_prefix("SILE ")
        .unwrap_or("")
        .to_string();
    let app = Cli::command().version(version).long_version(long_version);
    let matches = app.get_matches();
    let args = Cli::from_arg_matches(&matches).expect("Unable to parse arguments");
    sile::run(
        args.input,
        args.backend,
        args.class,
        args.debug,
        args.evaluate,
        args.evaluate_after,
        args.fontmanager,
        args.makedeps,
        args.output,
        args.option,
        args.preamble,
        args.postamble,
        args.r#use,
        args.quiet,
        args.traceback,
    )?;
    Ok(())
}
