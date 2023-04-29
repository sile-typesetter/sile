use clap::Parser;
use std::path::PathBuf;

/// The SILE typesetter reads a single input file, by default in either SIL or XML format, and
/// processes it to generate a single output file, by default in PDF format. The output file will
/// be written to the same name as the input file with the extension changed to .pdf. Additional
/// input or output formats can be handled by requiring a module that adds support for them first.
#[derive(Parser, Debug)]
#[clap(author, name = "SILE", bin_name = "sile")]
pub struct Cli {
    /// Input document, by default in SIL or XML format
    pub input: Option<PathBuf>,

    /// Choose an alternative output backend
    #[clap(short, long, value_name = "BACKEND")]
    pub backend: Option<String>,

    /// Override default document class
    #[clap(short, long)]
    pub class: Option<String>,

    /// Show debug information for tagged aspects of SILE’s operation
    #[clap(short, long, value_name = "DEBUGFLAG[,DEBUGFLAG]")]
    // TODO: switch to num_args(0..) to allow space separated inputs
    pub debug: Option<Vec<String>>,

    /// Evaluate Lua expression before processing input
    #[clap(short, long, value_name = "EXRPESION")]
    pub evaluate: Option<Vec<String>>,

    /// Evaluate Lua expression after processing input
    #[clap(short = 'E', long, value_name = "EXRPESION")]
    pub evaluate_after: Option<Vec<String>>,

    /// Choose an alternative font manager
    #[clap(short, long, value_name = "FONTMANAGER")]
    pub fontmanager: Option<String>,

    /// Generate a list of dependencies in Makefile format
    #[clap(short, long, value_name = "FILE")]
    pub makedeps: Option<PathBuf>,

    /// Explicitly set output file name
    #[clap(short, long, value_name = "FILE")]
    pub output: Option<PathBuf>,

    /// Set document class options
    #[clap(short = 'O', long)]
    pub options: Option<Vec<String>>,

    /// Process SIL, XML, or other content before the input document
    #[clap(short, long, value_name = "FILE")]
    pub preamble: Option<Vec<PathBuf>>,

    /// Process SIL, XML, or other content after the input document
    #[clap(short = 'P', long, value_name = "FILE")]
    pub postamble: Option<Vec<PathBuf>>,

    /// Load and initialize a module before processing input
    #[clap(
        short,
        long,
        value_name = "MODULE[[PARAMETER=VALUE[,PARAMETER=VALUE]]]"
    )]
    pub r#use: Option<Vec<String>>,

    /// Discard all non-error output messages
    #[clap(short, long)]
    pub quiet: bool,

    /// Display detailed location trace on errors and warnings
    #[clap(short, long)]
    pub traceback: bool,
}
