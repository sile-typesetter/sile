use clap::{CommandFactory, FromArgMatches};

use sile::cli::Cli;

fn main() -> sile::Result<()> {
    let version = option_env!("VERGEN_GIT_SEMVER").unwrap_or_else(|| env!("VERGEN_BUILD_SEMVER"));
    let version = version.replacen('-', ".r", 1);
    let long_version = sile::version()?
        .strip_prefix("SILE ")
        .unwrap_or("")
        .to_string();
    let app = Cli::command().version(version).long_version(long_version);
    #[allow(unused_variables)]
    let matches = app.get_matches();
    let args = Cli::from_arg_matches(&matches).expect("Unable to parse arguments");
    sile::run(
        args.inputs,
        args.backend,
        args.class,
        args.debug,
        args.evaluate,
        args.evaluate_after,
        args.fontmanager,
        args.makedeps,
        args.output,
        args.options,
        args.preamble,
        args.postamble,
        args.r#use,
        args.quiet,
        args.traceback,
    )?;
    Ok(())
}
