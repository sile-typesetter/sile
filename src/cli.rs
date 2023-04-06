use clap::Parser;

/// The SILE typesetter, Lua wrapped in Rust.
#[derive(Parser, Debug)]
#[clap(author, bin_name = "sile")]
pub struct Cli {}
