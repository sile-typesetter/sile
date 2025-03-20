use sile::cli::Cli;

use snafu::prelude::*;

use clap::{CommandFactory, FromArgMatches};

#[derive(Snafu)]
enum Error {
    #[snafu(display("{}", source))]
    Args { source: clap::error::Error },

    #[snafu(display("{}", source))]
    Runtime { source: anyhow::Error },

    #[snafu(display("{}", source))]
    Version { source: anyhow::Error },
}

// Deeper error types are reported using the Debug trait, but we handle them via Snafu and the Display trait.
// So we delegate. c.f. https://github.com/shepmaster/snafu/issues/110
impl std::fmt::Debug for Error {
    fn fmt(&self, fmt: &mut std::fmt::Formatter) -> std::fmt::Result {
        std::fmt::Display::fmt(self, fmt)
    }
}

type Result<T, E = Error> = std::result::Result<T, E>;

fn main() -> Result<()> {
    let version = option_env!("VERGEN_GIT_DESCRIBE").unwrap_or_else(|| env!("CARGO_PKG_VERSION"));
    let version = version.replacen('-', ".r", 1);
    let long_version = sile::version()
        .context(VersionSnafu)?
        .strip_prefix("SILE ")
        .unwrap_or("")
        .to_string();
    let app = Cli::command().version(version).long_version(long_version);
    let matches = app.get_matches();
    let args = Cli::from_arg_matches(&matches).context(ArgsSnafu)?;
    sile::run(
        args.input,
        args.backend,
        args.class,
        args.debug,
        args.evaluate,
        args.evaluate_after,
        args.fontmanager,
        args.luarocks_tree,
        args.makedeps,
        args.output,
        args.option,
        args.preamble,
        args.postamble,
        args.r#use,
        args.quiet,
        args.traceback,
    )
    .context(RuntimeSnafu)?;
    Ok(())
}
