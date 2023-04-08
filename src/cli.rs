use clap::Parser;

/// The SILE typesetter, Lua wrapped in Rust.
#[derive(Parser, Debug)]
#[clap(author, bin_name = "sile")]
pub struct Cli {
    // cliargs:option("-b, --backend=VALUE", "choose an alternative output backend")
    // cliargs:option("-c, --class=VALUE", "override default document class")
    // cliargs:option("-d, --debug=VALUE", "show debug information for tagged aspects of SILE’s operation", {})
    /// Evaluate Lua expression before processing input
    #[clap(short, long)]
    pub evaluate: Option<String>,

    /// Evaluate Lua expression after processing input
    #[clap(short = 'E', long)]
    pub evaluate_after: Option<String>,

    // cliargs:option("-E, --evaluate-after=VALUE", "", {})
    // cliargs:option("-f, --fontmanager=VALUE", "choose an alternative font manager")
    // cliargs:option("-I, --include=FILE", "deprecated, see --use, --preamble, or --postamble", {})
    // cliargs:option("-m, --makedeps=FILE", "generate a list of dependencies in Makefile format")
    // cliargs:option("-o, --output=FILE", "explicitly set output file name")
    // cliargs:option("-O, --options=PARAMETER=VALUE[,PARAMETER=VALUE]", "set document class options", {})
    // cliargs:option("-p, --preamble=FILE", "process SIL, XML, or other content before the input document", {})
    // cliargs:option("-P, --postamble=FILE", "process SIL, XML, or other content after the input document", {})
    // cliargs:option("-u, --use=MODULE[[PARAMETER=VALUE][,PARAMETER=VALUE]]", "load and initialize a module before processing input", {})
    /// Discard all non-error output messages
    #[clap(short, long)]
    pub quiet: bool,

    /// Display detailed location trace on errors and warnings
    #[clap(short, long)]
    pub traceback: bool,
}
