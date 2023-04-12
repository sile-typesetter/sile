use clap::{Parser, ValueEnum};
use std::path::PathBuf;

/// The SILE typesetter reads a single input file, by default in either SIL or XML format, and
/// processes it to generate a single output file, by default in PDF format. The output file will
/// be written to the same name as the input file with the extension changed to .pdf. Additional
/// input or output formats can be handled by requiring a module that adds support for them first.
#[derive(Parser, Debug)]
#[clap(author, bin_name = "sile")]
pub struct Cli {
    /// Input document, by default in SIL or XML format
    pub input: String,

    /// Choose an alternative output backend
    #[clap(short, long, value_enum, default_value_t=Backend::Libtexpdf)]
    pub backend: Backend,

    /// Override default document class
    #[clap(short, long)]
    pub class: Option<String>,

    /// Show debug information for tagged aspects of SILE’s operation
    #[clap(short, long)]
    pub debug: Option<Vec<String>>,

    /// Evaluate Lua expression before processing input
    #[clap(short, long)]
    pub evaluate: Option<Vec<String>>,

    /// Evaluate Lua expression after processing input
    #[clap(short = 'E', long)]
    pub evaluate_after: Option<Vec<String>>,

    /// Choose an alternative font manager
    #[clap(short, long, value_enum, default_value_t=FontManager::Fontconfig)]
    pub fontmanager: FontManager,

    /// Generate a list of dependencies in Makefile format
    #[clap(short, long)]
    pub makedeps: Option<PathBuf>,

    /// Explicitly set output file name
    #[clap(short, long)]
    pub output: Option<PathBuf>,

    /// Set document class options
    #[clap(short = 'O', long)]
    pub options: Option<Vec<String>>,

    /// Process SIL, XML, or other content before the input document
    #[clap(short, long)]
    pub preamble: Option<Vec<PathBuf>>,

    /// Process SIL, XML, or other content after the input document
    #[clap(short = 'P', long)]
    pub postamble: Option<Vec<PathBuf>>,

    /// Load and initialize a module before processing input
    #[clap(short, long)]
    pub r#use: Option<Vec<String>>,

    /// Discard all non-error output messages
    #[clap(short, long)]
    pub quiet: bool,

    /// Display detailed location trace on errors and warnings
    #[clap(short, long)]
    pub traceback: bool,
}

#[derive(ValueEnum, Debug, Clone)]
pub enum Backend {
    Libtexpdf,
    Debug,
    Text,
    Dummy,
    Cairo,
    Podofo,
}

#[derive(ValueEnum, Debug, Clone)]
pub enum FontManager {
    Fontconfig,
    Macfonts,
}
