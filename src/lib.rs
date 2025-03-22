// rust-embed include attributes have issues with lots of matches...
#![recursion_limit = "2048"]

use mlua::prelude::*;

#[cfg(not(feature = "static"))]
use mlua::chunk;
use std::env;
use std::path::PathBuf;

#[cfg(feature = "cli")]
pub mod cli;

#[cfg(feature = "static")]
pub mod embed;

pub mod types;

pub type Result<T> = anyhow::Result<T>;

pub fn start_luavm() -> crate::Result<Lua> {
    let mut lua = unsafe { Lua::unsafe_new() };
    #[cfg(feature = "static")]
    {
        lua = embed::inject_embedded_loaders(lua)?;
    }
    // For parity with the legacy Lua arg parser, allows inspection of CLI args at runtime in Lua.
    {
        let rt = std::env::args()
            .next()
            .unwrap_or_else(|| "sile".to_string());
        let args: Vec<String> = std::env::args().skip(1).collect();
        let arg_table = lua.create_table()?;
        for (i, arg) in args.iter().enumerate() {
            arg_table.set(i + 1, arg.clone())?;
        }
        // A bit non-orthodox, but the Lua side sets the VM chunk name to what moste CLIs expect $0
        // to be, their own binary name. The Rust side of mlua is setting the chunk name to =[C],
        // making error messages a bit cryptic. By setting a 0 index here we give the later Lua
        // side a chance to replace the chunk name with it.
        arg_table.set(0, rt)?;
        lua.globals().set("arg", arg_table)?;
    }
    lua = inject_paths(lua)?;
    lua = load_sile(lua)?;
    lua = inject_version(lua)?;
    Ok(lua)
}

pub fn inject_paths(lua: Lua) -> crate::Result<Lua> {
    #[cfg(feature = "static")]
    lua.load(r#"require("core.pathsetup")"#)
        .set_name("relative pathsetup loader")
        .exec()?;
    #[cfg(not(feature = "static"))]
    {
        let datadir = env!("CONFIGURE_DATADIR").to_string();
        let sile_path = match env::var("SILE_PATH") {
            Ok(val) => format!("{datadir};{val}"),
            Err(_) => datadir,
        };
        let sile_path: LuaString = lua.create_string(&sile_path)?;
        lua.load(chunk! {
            local status
            for path in string.gmatch($sile_path, "[^;]+") do
                status = pcall(dofile, path .. "/core/pathsetup.lua")
                if status then break end
            end
            if not status then
                dofile("./core/pathsetup.lua")
            end
        })
        .set_name("hard coded pathsetup loader")
        .exec()?;
    }
    Ok(lua)
}

pub fn get_rusile_exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("semver", LuaFunction::wrap_raw(types::semver::semver))?;
    exports.set("setenv", LuaFunction::wrap_raw(setenv))?;
    Ok(exports)
}

fn setenv(key: String, value: String) {
    env::set_var(key, value);
}

pub fn inject_version(lua: Lua) -> crate::Result<Lua> {
    let sile: LuaTable = lua.globals().get("SILE")?;
    let mut full_version: String = sile.get("full_version")?;
    full_version.push_str(" [Rust]");
    sile.set("full_version", full_version)?;
    Ok(lua)
}

pub fn load_sile(lua: Lua) -> crate::Result<Lua> {
    let entry: LuaString = lua.create_string("core.sile")?;
    let require: LuaFunction = lua.globals().get("require")?;
    require.call::<LuaTable>(entry)?;
    Ok(lua)
}

pub fn version() -> crate::Result<String> {
    let lua = start_luavm()?;
    let sile: LuaTable = lua.globals().get("SILE")?;
    let full_version: String = sile.get("full_version")?;
    Ok(full_version)
}

// Yes I know this should be taking a struct, probably 1 with what ends up being SILE.input and one
// with other stuff the CLI may inject, but I'm playing with what a minimum/maximum set of
// parameters would look like here while maintaining compatiblitiy with the Lua CLI.
#[allow(clippy::too_many_arguments)]
pub fn run(
    inputs: Option<Vec<PathBuf>>,
    backend: Option<String>,
    class: Option<String>,
    debugs: Option<Vec<String>>,
    evaluates: Option<Vec<String>>,
    evaluate_afters: Option<Vec<String>>,
    fontmanager: Option<String>,
    luarocks_tree: Option<Vec<PathBuf>>,
    makedeps: Option<PathBuf>,
    output: Option<PathBuf>,
    options: Option<Vec<String>>,
    preambles: Option<Vec<PathBuf>>,
    postambles: Option<Vec<PathBuf>>,
    uses: Option<Vec<String>>,
    quiet: bool,
    traceback: bool,
) -> crate::Result<()> {
    let lua = start_luavm()?;
    let sile: LuaTable = lua.globals().get("SILE")?;
    sile.set("traceback", traceback)?;
    sile.set("quiet", quiet)?;
    let mut has_input_filename = false;
    if let Some(flags) = debugs {
        let debug_flags: LuaTable = sile.get("debugFlags")?;
        for flag in flags {
            debug_flags.set(flag, true)?;
        }
    }
    let full_version: String = sile.get("full_version")?;
    let sile_input: LuaTable = sile.get("input")?;
    if let Some(expressions) = evaluates {
        sile_input.set("evaluates", expressions)?;
    }
    if let Some(expressions) = evaluate_afters {
        sile_input.set("evaluateAfters", expressions)?;
    }
    if let Some(backend) = backend {
        sile_input.set("backend", backend)?;
    }
    if let Some(fontmanager) = fontmanager {
        sile_input.set("fontmanager", fontmanager)?;
    }
    if let Some(trees) = luarocks_tree {
        sile_input.set("luarocksTrees", trees)?;
    }
    if let Some(class) = class {
        sile_input.set("class", class)?;
    }
    if let Some(paths) = preambles {
        sile_input.set("preambles", paths_to_strings(paths))?;
    }
    if let Some(paths) = postambles {
        sile_input.set("postambles", paths_to_strings(paths))?;
    }
    if let Some(path) = makedeps {
        sile_input.set("makedeps", path_to_string(&path))?;
    }
    if let Some(path) = output {
        sile.set("outputFilename", path_to_string(&path))?;
        has_input_filename = true;
    }
    if let Some(options) = options {
        let parameters: LuaAnyUserData = sile.get::<LuaTable>("parserBits")?.get("parameters")?;
        let input_options: LuaTable = sile_input.get("options")?;
        for option in options.iter() {
            let parameters: LuaTable = parameters
                .call_method("match", lua.create_string(option)?)
                .context("failed to call `parameters:match()`")?;
            for parameter in parameters.pairs::<LuaValue, LuaValue>() {
                let (key, value) = parameter?;
                let _ = input_options.set(key, value);
            }
        }
    }
    if let Some(modules) = uses {
        let cliuse: LuaAnyUserData = sile.get::<LuaTable>("parserBits")?.get("cliuse")?;
        let input_uses: LuaTable = sile_input.get("uses")?;
        for module in modules.iter() {
            let module = lua.create_string(module)?;
            let spec: LuaTable = cliuse
                .call_method::<_>("match", module)
                .context("failed to call `cliuse:match()`")?;
            let _ = input_uses.push(spec);
        }
    }
    if !quiet {
        eprintln!("{full_version}");
    }
    let init: LuaFunction = sile.get("init")?;
    init.call::<LuaValue>(())?;
    if let Some(inputs) = inputs {
        let input_filenames: LuaTable = lua.create_table()?;
        for input in inputs.iter() {
            let path = &path_to_string(input);
            if !has_input_filename && path != "-" {
                has_input_filename = true;
            }
            input_filenames.push(lua.create_string(path)?)?;
        }
        if !has_input_filename {
            panic!(
                "\nUnable to derive an output filename (perhaps because input is a STDIO stream)\nPlease use --output to set one explicitly."
            );
        }
        sile_input.set("filenames", input_filenames)?;
        let input_uses: LuaTable = sile_input.get("uses")?;
        let r#use: LuaFunction = sile.get("use")?;
        for spec in input_uses.sequence_values::<LuaTable>() {
            let spec = spec?;
            let module: LuaString = spec.get("module")?;
            let options: LuaTable = spec.get("options")?;
            r#use.call::<LuaValue>((module, options))?;
        }
        let input_filenames: LuaTable = sile_input.get("filenames")?;
        let process_file: LuaFunction = sile.get("processFile")?;
        for file in input_filenames.sequence_values::<LuaString>() {
            process_file.call::<LuaValue>(file?)?;
        }
        let finish: LuaFunction = sile.get("finish")?;
        finish.call::<LuaValue>(())?;
    } else {
        let repl_module: LuaString = lua.create_string("core.repl")?;
        let require: LuaFunction = lua.globals().get("require")?;
        let repl: LuaTable = require.call::<LuaTable>(repl_module)?;
        repl.call_method::<LuaValue>("enter", ())?;
    }
    Ok(())
}

fn path_to_string(path: &PathBuf) -> String {
    path.clone().into_os_string().into_string().unwrap()
}

fn paths_to_strings(paths: Vec<PathBuf>) -> Vec<String> {
    paths.iter().map(path_to_string).collect()
}
