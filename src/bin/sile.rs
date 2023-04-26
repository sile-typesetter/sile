use clap::{CommandFactory, FromArgMatches};

use sile::cli::Cli;
use sile::run;

fn main() -> sile::Result<()> {
    let version = option_env!("VERGEN_GIT_SEMVER").unwrap_or_else(|| env!("VERGEN_BUILD_SEMVER"));
    let app = Cli::command().version(version);
    #[allow(unused_variables)]
    let matches = app.get_matches();
    let args = Cli::from_arg_matches(&matches).expect("Unable to parse arguments");
    run(
        args.input,
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
