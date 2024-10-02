// rust-embed include attributes have issues with lots of matches...
#![recursion_limit = "2048"]

use mlua::chunk;
use mlua::prelude::*;
#[cfg(not(feature = "static"))]
use std::env;
use std::path::PathBuf;
#[cfg(feature = "cli")]
pub mod cli;

#[cfg(feature = "static")]
pub mod embed;

pub type Result<T> = anyhow::Result<T>;

pub fn start_luavm() -> crate::Result<Lua> {
    let lua = unsafe { Lua::unsafe_new() };
    #[cfg(feature = "static")]
    crate::embed::inject_embedded_loader(&lua);
    inject_paths(&lua);
    load_sile(&lua);
    inject_version(&lua);
    Ok(lua)
}

pub fn inject_paths(lua: &Lua) {
    #[cfg(feature = "static")]
    lua.load(r#"require("core.pathsetup")"#).exec().unwrap();
    #[cfg(not(feature = "static"))]
    {
        let datadir = env!("CONFIGURE_DATADIR").to_string();
        let sile_path = match env::var("SILE_PATH") {
            Ok(val) => format!("{datadir};{val}"),
            Err(_) => datadir,
        };
        let sile_path: LuaString = lua.create_string(&sile_path).unwrap();
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
        .exec()
        .unwrap();
    }
}

pub fn inject_version(lua: &Lua) {
    let sile: LuaTable = lua.globals().get("SILE").unwrap();
    let mut full_version: String = sile.get("full_version").unwrap();
    full_version.push_str(" [Rust]");
    sile.set("full_version", full_version).unwrap();
}

pub fn load_sile(lua: &Lua) {
    let entry: LuaString = lua.create_string("core.sile").unwrap();
    let require: LuaFunction = lua.globals().get("require").unwrap();
    require.call::<LuaTable>(entry).unwrap();
}

pub fn version() -> crate::Result<String> {
    let lua = start_luavm()?;
    let sile: LuaTable = lua.globals().get("SILE").unwrap();
    let full_version: String = sile.get("full_version").unwrap();
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
        sile.set("backend", backend)?;
    }
    if let Some(fontmanager) = fontmanager {
        sile.set("fontmanager", fontmanager)?;
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
        sile_input.set("options", options)?;
    }
    if let Some(modules) = uses {
        // let parser_bits: LuaTable = sile.get("parserBits")?;
        // let cliuse: LuaAnyUserData = parser_bits.get("cliuse")?;
        // sile_input.get("uses")?;
        for module in modules.iter() {
            let module = lua.create_string(module)?;
            lua.load(chunk! {
                local spec = SILE.parserBits.cliuse:match($module);
                table.insert(SILE.input.uses, spec)
            })
            .eval::<()>()?;
            // let spec = cliuse.call_function::<_, _, _>("match", module);
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
            r#use.call::<(LuaString, LuaTable)>((module, options))?;
        }
        let input_filenames: LuaTable = sile_input.get("filenames")?;
        let process_file: LuaFunction = sile.get("processFile")?;
        for file in input_filenames.sequence_values::<LuaString>() {
            process_file.call::<LuaString>(file?)?;
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

pub fn rusile_demo() -> Result<String> {
    Ok("Hello from rusile".to_string())
}
