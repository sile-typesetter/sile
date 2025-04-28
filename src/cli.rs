use clap::Parser;
use std::path::PathBuf;

/// The SILE Typesetter reads input file(s) and typesets the content into a rendered document
/// format, typically PDF.
///
/// By default, input files may be in declarative SIL markup, structured XML, or programmatic Lua.
/// The input format is automatically detected by the active modules. By default, the output will
/// be a file with the same name as the first input file with the extension changed to .pdf. The
/// output filename can be overridden with the `--output` argument. Using `--backend` one can
/// change to a different output format (or a different driver for the same format). Additional
/// input or output formats can be handled by loading a 3rd party module that supports them by
/// adding `--use` argument on the command line (which will load prior to attempting to read input
/// documents).
#[derive(Parser, Debug)]
#[clap(author, name = "SILE", bin_name = "sile")]
pub struct Cli {
    /// Input document filename(s), by default in SIL, XML, or Lua formats.
    ///
    /// One or more input files from which to process content.
    /// The first listed file is considered the master document, others are procced in sequence.
    /// Other inputter formats may be enabled via`--use`.
    /// Use `-` to read a content stream from STDIN.
    pub input: Option<Vec<PathBuf>>,

    /// Specify the output backend.
    ///
    /// The default is `libtexpdf` and suitible for most PDF output.
    /// Alternatives supported out of the box include `text`, `debug`, `dummy`, `cairo`, and `podofo`.
    /// Other outputters may be enabled via `--use`.
    #[clap(short, long, value_name = "BACKEND")]
    pub backend: Option<String>,

    /// Override the default or specified document class.
    ///
    /// The default class for documents that do not specify one in the root tag is `plain`.
    /// This can be used to either change the default class or to override the class actually specified in a document.
    /// Other bundled classes include `base`, `bible`, `book`, `diglot`, `docbook`, `docbook`, `jbook`, `jplain`, `letter`, `pecha`, `tbook`, `tplain`, and `triglot`.
    /// Others will be loaded dynamically from the module path.
    #[clap(short, long)]
    pub class: Option<String>,

    /// Show debug information for tagged aspects of SILE’s operation.
    ///
    /// Multiple debug flags may be given as a comma separated list.
    /// While packages may define their own debug flags, the most commonly used ones are `typesetter`, `pagebuilder`, `vboxes`, `break`, `frames`, `profile`, and `versions`.
    /// May be specified more than once.
    #[clap(short, long, value_name = "DEBUGFLAG[,DEBUGFLAG]")]
    // TODO: switch to num_args(0..) to allow space separated inputs
    pub debug: Option<Vec<String>>,

    /// Evaluate Lua expression before processing input.
    ///
    /// May be specified more than once.
    #[clap(short, long, value_name = "EXRPESION")]
    pub evaluate: Option<Vec<String>>,

    /// Evaluate Lua expression after processing input.
    ///
    /// May be specified more than once.
    #[clap(short = 'E', long, value_name = "EXRPESION")]
    pub evaluate_after: Option<Vec<String>>,

    /// Specify which font manager to use.
    ///
    /// The font manager is responsible for discovering the locations on font files on the system given a font name.
    /// The default font manager is a multipurpose one that checks for a font via `macfonts`, then falls back to `fontconfig`.
    /// This can be used to force a specific loader when more than one is available.
    #[clap(short, long, value_name = "FONTMANAGER")]
    pub fontmanager: Option<String>,

    /// Add a path to the list of LuaRocks trees searched for modules.
    ///
    /// When installing 3rd party SILE modules via LuaRocks there are several possible installation locations.
    /// They may be installed to the host system, the user's home directory, a project-local path, or any arbitrary location.
    /// In the case of the system or a project-local path called exactly `lua_modules` they will be found automatically.
    /// In the case of any other path, SILE needs to be told where to find them.
    /// This can be done by exporting a LUA_PATH environment variable before running SILE, or by using this option.
    #[clap(long, value_name = "LUAROCKS_TREE")]
    pub luarocks_tree: Option<Vec<PathBuf>>,

    /// Generate a Makefile format list of dependencies and white them to a file.
    ///
    /// This tracks all the files (input files, Lua libraries, fonts, images, etc.) use during the
    /// typesetting process.
    /// After completion, the list is written to FILE in the format of a dependency list for
    /// a target in a Makefile.
    /// This can be used later to determine if a PDF needs re-rendering based on whether any inputs
    /// have changed.
    #[clap(short, long, value_name = "FILE")]
    pub makedeps: Option<PathBuf>,

    /// Explicitly set the output file name.
    ///
    /// By default the basename of the first input file will be used as the output filename.
    /// An extension will be chosen based on the output backend, typically .pdf.
    /// With this option any arbitrary name and path can be given.
    /// Additionally `-` can be used to write the output to STDOUT.
    #[clap(short, long, value_name = "FILE", required_if_eq("input", "-"))]
    pub output: Option<PathBuf>,

    /// Set or override document class options.
    ///
    /// Can be used to change default options or override the ones specified in a document.
    /// For example setting `--option papersize=letter` would override both the default `papersize` of A4 and any specific one set in the document’s options.
    /// May be specified more than once.
    #[clap(short = 'O', long, alias = "options")]
    pub option: Option<Vec<String>>,

    /// Include the contents of a SIL, XML, or other resource file before the input document content.
    ///
    /// The value should be a full filename with a path relative to PWD or an absolute path.
    /// May be specified more than once.
    #[clap(short, long, value_name = "FILE")]
    pub preamble: Option<Vec<PathBuf>>,

    /// Include the contents of a SIL, XML, or other resource file after the input document content.
    ///
    /// The value should be a full filename with a path relative to PWD or an absolute path.
    /// May be specified more than once.
    #[clap(short = 'P', long, value_name = "FILE")]
    pub postamble: Option<Vec<PathBuf>>,

    /// Load and initialize a class, inputter, shaper, or other module before processing the main input.
    ///
    /// The value should be a loadable module name (with no extension, using `.` as a path separator) and will be loaded using SILE’s module search path.
    /// Options may be passed to the module by enclosing `key=value` pairs in square brackets following the module name.
    /// This is particularly useful when the input document is not SIL or a natively recognized XML scheme
    /// and SILE needs to be taught new tricks before even trying to read the input file.
    /// If the module is a document class, it will replace `plain` as the default class for processing
    /// documents that do not specifically identify one to use.
    /// Because this executes before loading the document, it may even add an input parser or modify an existing one to support new file formats.
    /// Package modules will be added to the preamble to be loaded after the class is initialized.
    /// May be specified more than once.
    #[clap(
        short,
        long,
        value_name = "MODULE[[PARAMETER=VALUE[,PARAMETER=VALUE]]]"
    )]
    pub r#use: Option<Vec<String>>,

    /// Suppress warnings and informational messages during processing.
    #[clap(short, long)]
    pub quiet: bool,

    /// Display detailed location trace on errors and warnings.
    #[clap(short, long)]
    pub traceback: bool,
}
