--- The core SILE library
-- @module SILE

-- Placeholder for SILE internals
SILE = {}

--- Fields
-- @section fields

--- Machine friendly short-form version.
-- Semver, prefixed with "v", possible postfixed with ".r" followed by VCS version information.
-- @string version
SILE.version = require("core.version")

--- Status information about what options SILE was compiled with.
-- @table SILE.features
-- @tfield boolean appkit
-- @tfield boolean font_variations
-- @tfield boolean fontconfig
-- @tfield boolean harfbuzz
-- @tfield boolean icu
SILE.features = require("core.features")

-- Initialize Lua environment and global utilities

--- ABI version of Lua VM.
-- For example may be `"5.1"` or `"5.4"` or others. Note that the ABI version for most LuaJIT implementations is 5.1.
-- @string lua_version
SILE.lua_version = _VERSION:sub(-3)


--- Whether or not Lua VM is a JIT compiler.
-- @boolean lua_isjit
-- luacheck: ignore jit
SILE.lua_isjit = type(jit) == "table"

--- User friendly long-form version string.
-- For example may be "SILE v0.14.17 (Lua 5.4)".
-- @string full_version
SILE.full_version = string.format("SILE %s (%s)", SILE.version, SILE.lua_isjit and jit.version or _VERSION)

-- Backport of lots of Lua 5.3 features to Lua 5.[12]
if not SILE.lua_isjit and SILE.lua_version < "5.3" then require("compat53") end

-- Penlight on-demand module loader, provided for SILE and document usage
pl = require("pl.import_into")()

-- For developer testing only, usually in CI
if os.getenv("SILE_COVERAGE") then require("luacov") end

-- Lua 5.3+ has a UTF-8 safe string function module but it is somewhat
-- underwhelming. This module includes more functions and supports older Lua
-- versions. Docs: https://github.com/starwing/luautf8
luautf8 = require("lua-utf8")

-- Localization library, provided as global
fluent = require("fluent")()

-- Includes for _this_ scope
local lfs = require("lfs")

-- Developer tooling profiler
local ProFi

-- For warnings and shims scheduled for removal that are easier to keep track
-- of when they are not spread across so many locations...
-- Loaded early to make it easier to manage migrations in core code.
require("core/deprecations")

--- Modules
-- @section modules

--- Utilities module, aliased as `SU`.
SILE.utilities = require("core.utilities")
SU = SILE.utilities -- regrettable global alias

-- On demand loader, allows modules to be loaded into a specific scope but
-- only when/if accessed.
local function core_loader (scope)
  return setmetatable({}, {
    __index = function (self, key)
      -- local var = rawget(self, key)
      local m = require(("%s.%s"):format(scope, key))
      self[key] = m
      return m
    end
  })
end

--- Data tables
--- @section data

--- Stash of all Lua functions used to power typesetter commands.
-- @table Commands
SILE.Commands = {}

--- Short usage messages corresponding to typesetter commands.
-- @table Help
SILE.Help = {}

--- List of currently enabled debug flags.
-- E.g. `{ typesetter = true, frames, true }`.
-- @table debugFlags
SILE.debugFlags = {}

SILE.nodeMakers = {}
SILE.tokenizers = {}
SILE.status = {}

--- The wild-west of stash stuff.
-- No rules, just right (or usually wrong). Everything in here *should* be somewhere else, but lots of early SILE code
-- relied on this as a global key/value store for various class, document, and package values. Since v0.14.0 with many
-- core SILE components being instances of classes –and especially with each package having it's own variable namespace–
-- there are almost always better places for things. This scratch space will eventually be completely deprecated, so
-- don't put anything new in here and only use things in it if there are no other current alternatives.
-- @table scratch
SILE.scratch = {}

--- Data storage for typesetter, frame, and class information.
-- Current document class instances, node queues, and other "hot" data can be found here. As with `SILE.scratch`
-- everything in here probably belongs elsewhere, but for now it is what it is.
-- @table documentState
-- @tfield table documentClass The instantiated document processing class.
-- @tfield table thisPageTemplate The frameset used for the current page.
-- @tfield table paperSize The current paper size.
-- @tfield table orgPaperSize The original paper size if the current one is modified via packages.
SILE.documentState = {}

--- Callback functions for handling types of raw content.
-- All registered handlers for raw content blocks have an entry in this table with the type as the key and the
-- processing function as the value.
-- @ table rawHandlers
SILE.rawHandlers = {}

--- User input
-- @section input

--- All user-provided input collected before beginning document processing.
-- User input values, currently from CLI options, potentially all the inuts
-- needed for a user to use a SILE-as-a-library version to produce documents
-- programmatically.
-- @table input
-- @tfield table filenames Path names of file(s) intended for processing. Files are processed in the order provided.
-- File types may be mixed of any formaat for which SILE has an inputter module.
-- @tfield table evaluates List of strings to be evaluated as Lua code snippets *before* processing inputs.
-- @tfield table evaluteAfters List of strings to be evaluated as Lua code snippets *after* processing inputs.
-- @tfield table uses List of strings specifying module names (and optionally optionns) for modules to load *before*
-- processing inputs. For example this accomodates loading inputter modules before any input of that type is encountered.
-- Additionally it can be used to process a document using a document class *other than* the one specified in the
-- document itself. Document class modules loaded here are instantiated after load, meaning the document will not be
-- queried for a class at all.
-- @tfield table options Extra document class options to set or override in addition to ones found in the first input
-- document.
SILE.input = {
  filenames = {},
  evaluates = {},
  evaluateAfters = {},
  uses = {},
  options = {},
  preambles = {},
  postambles = {},
}

-- Internal libraries that are idempotent and return classes that need instantiation
SILE.inputters = core_loader("inputters")
SILE.shapers = core_loader("shapers")
SILE.outputters = core_loader("outputters")
SILE.classes = core_loader("classes")
SILE.packages = core_loader("packages")
SILE.typesetters = core_loader("typesetters")
SILE.pagebuilders = core_loader("pagebuilders")
SILE.types = core_loader("types")

-- Internal libraries that don't try to use anything on load, only provide something
SILE.parserBits = require("core.parserbits")
SILE.frameParser = require("core.frameparser")
SILE.fontManager = require("core.fontmanager")
SILE.papersize = require("core.papersize")

-- NOTE:
-- See remainaing internal libraries loaded at the end of this file because
-- they run core SILE functions on load instead of waiting to be called (or
-- depend on others that do).

local function runEvals (evals, arg)
  for _, snippet in ipairs(evals) do
    local pId = SILE.traceStack:pushText(snippet)
    local status, func = pcall(load, snippet)
    if status then
      func()
    else
      SU.error(("Error parsing code provided in --%s snippet: %s"):format(arg, func))
    end
    SILE.traceStack:pop(pId)
  end
end

--- Core functions
-- @section functions

--- Initialize a SILE instance.
-- Presumes CLI args have already been processed and/or library inputs are set.
--
-- 1. If no backend has been loaded already (e.g. via `--use`) then assumes *libtexpdf*.
-- 2. Loads and instantiates a shaper and outputter module appropriate for the chosen backend.
-- 3. Instantiates a pagebuilder.
-- 4. Starts a Lua profiler if the profile debug flag is set.
-- 5. Instantiates a dependency tracker if we've been asked to write make dependencies.
-- 6. Runs any code snippents passed with `--eval`.
--
-- Does not move on to processing input document(s).
function SILE.init ()
  if not SILE.backend then
    SILE.backend = "libtexpdf"
  end
  if SILE.backend == "libtexpdf" then
    SILE.shaper = SILE.shapers.harfbuzz()
    SILE.outputter = SILE.outputters.libtexpdf()
  elseif SILE.backend == "cairo" then
    SILE.shaper = SILE.shapers.pango()
    SILE.outputter = SILE.outputters.cairo()
  elseif SILE.backend == "debug" then
    SILE.shaper = SILE.shapers.harfbuzz()
    SILE.outputter = SILE.outputters.debug()
  elseif SILE.backend == "text" then
    SILE.shaper = SILE.shapers.harfbuzz()
    SILE.outputter = SILE.outputters.text()
  elseif SILE.backend == "dummy" then
    SILE.shaper = SILE.shapers.harfbuzz()
    SILE.outputter = SILE.outputters.dummy()
  end
  SILE.pagebuilder = SILE.pagebuilders.base()
  io.stdout:setvbuf("no")
  if SU.debugging("profile") then
    ProFi = require("ProFi")
    ProFi:start()
  end
  if SILE.makeDeps then
    SILE.makeDeps:add(_G.executablePath)
  end
  runEvals(SILE.input.evaluates, "evaluate")
end

local function suggest_luarocks (module)
  local guessed_module_name = module:gsub(".*%.", "") .. ".sile"
  return ([[

    If the expected module is a 3rd party extension you may need to install it
    using LuaRocks. The details of how to do this are highly dependent on
    your system and preferred installation method, but as an example installing
    a 3rd party SILE module to a project-local tree where might look like this:

        luarocks --lua-version %s --tree lua_modules install %s

    This will install the LuaRocks to your project, then you need to tell your
    shell to pass along that info about available LuaRocks paths to SILE. This
    only needs to be done once in each shell.

        eval $(luarocks --lua-version %s --tree lua_modules path)

    Thereafter running SILE again should work as expected:

       sile %s

    ]]):format(
        SILE.lua_version,
        guessed_module_name,
        SILE.lua_version,
        pl.stringx.join(" ", _G.arg or {})
        )
end

--- Multi-purpose loader to load and initialize modules.
-- This is used to load and intitialize core parts of SILE and also 3rd party modules.
-- Module types supported bay be an *inputter*, *outputer*, *shaper*, *typesetter*, *pagebuilder*, or *package*.
-- @tparam string|table module The module spec name to load (dot-separated, e.g. `"packages.lorem"`) or a table with
--   a module that has already been loaded.
-- @tparam[opt] table options Startup options as key/value pairs passed to the module when initialized.
-- @tparam[opt=false] boolean reload whether or not to reload a module that has been loaded and initialized before.
function SILE.use (module, options, reload)
  local status, pack
  if type(module) == "string" then
    status, pack = pcall(require, module)
    if not status then
      SU.error(("Unable to use '%s':\n%s%s")
        :format(module, SILE.traceback and ("    Lua ".. pack) or "", suggest_luarocks(module)))
    end
  elseif type(module) == "table" then
    pack = module
  end
  local name = pack._name
  local class = SILE.documentState.documentClass
  if not pack.type then
    SU.error("Modules must declare their type")
  elseif pack.type == "class" then
    SILE.classes[name] = pack
    if class then
      SU.error("Cannot load a class after one is already instantiated")
    end
    SILE.scratch.class_from_uses = pack
  elseif pack.type == "inputter" then
    SILE.inputters[name] = pack
    SILE.inputter = pack(options)
  elseif pack.type == "outputter" then
    SILE.outputters[name] = pack
    SILE.outputter = pack(options)
  elseif pack.type == "shaper" then
    SILE.shapers[name] = pack
    SILE.shaper = pack(options)
  elseif pack.type == "typesetter" then
    SILE.typesetters[name] = pack
    SILE.typesetter = pack(options)
  elseif pack.type == "pagebuilder" then
    SILE.pagebuilders[name] = pack
    SILE.pagebuilder = pack(options)
  elseif pack.type == "package" then
    SILE.packages[pack._name] = pack
    if class then
       class:loadPackage(pack, options, reload)
    else
      table.insert(SILE.input.preambles, { pack = pack, options = options })
    end
  end
end

-- --- Content loader like Lua's `require()` but whith special path handling for loading SILE resource files.
-- -- Used for example by commands that load data via a `src=file.name` option.
-- -- @tparam string dependency Lua spec
function SILE.require (dependency, pathprefix, deprecation_ack)
  if pathprefix and not deprecation_ack then
    local notice = string.format([[
  Please don't use the path prefix mechanism; it was intended to provide
  alternate paths to override core components but never worked well and is
  causing portability problems. Just use Lua idiomatic module loading:
      SILE.require("%s", "%s") → SILE.require("%s.%s")]],
      dependency, pathprefix, pathprefix, dependency)
    SU.deprecated("SILE.require", "SILE.require", "0.13.0", nil, notice)
  end
  dependency = dependency:gsub(".lua$", "")
  local status, lib
  if pathprefix then
    -- Note this is not a *path*, it is a module identifier:
    -- https://github.com/sile-typesetter/sile/issues/1861
    status, lib = pcall(require, pl.stringx.join('.', { pathprefix, dependency }))
  end
  if not status then
    local prefixederror = lib
    status, lib = pcall(require, dependency)
    if not status then
      SU.error(("Unable to find module '%s'%s")
        :format(dependency, SILE.traceback and ((pathprefix and "\n  " .. prefixederror or "") .. "\n  " .. lib) or ""))
    end
  end
  local class = SILE.documentState.documentClass
  if not class and not deprecation_ack then
    SU.warn(string.format([[
  Use of SILE.require() is only supported in documents, packages, or class
  init functions. It will not function fully before the class is instantiated.
  Please just use the Lua require() function directly:
      SILE.require("%s") → require("%s")]], dependency, dependency))
  end
  if type(lib) == "table" and class then
    if lib.type == "package" then
      lib(class)
    else
      class:initPackage(lib)
    end
  end
  return lib
end

--- Process content.
-- This is the main 'action' SILE does. Once input files are parsed into an abstract syntax tree, then we recursively
-- iterate through the tree handling each item in the order encountered.
-- @tparam table ast SILE content in abstract syntax tree format (a table of strings, functions, or more AST trees).
function SILE.process (ast)
  if not ast then return end
  if SU.debugging("ast") then
    SU.debugAST(ast, 0)
  end
  if type(ast) == "function" then return ast() end
  for _, content in ipairs(ast) do
    if type(content) == "string" then
      SILE.typesetter:typeset(content)
    elseif type(content) == "function" then
      content()
    elseif SILE.Commands[content.command] then
      SILE.call(content.command, content.options, content)
    elseif content.id == "content"
      or (not content.command and not content.id) then
      local pId = SILE.traceStack:pushContent(content, "content")
      SILE.process(content)
      SILE.traceStack:pop(pId)
    elseif type(content) ~= "nil" then
      local pId = SILE.traceStack:pushContent(content)
      SU.error("Unknown command "..(tostring(content.command or content.id)))
      SILE.traceStack:pop(pId)
    end
  end
end

local preloadedinputters = { "xml", "lua", "sil" }

local function detectFormat (doc, filename)
  -- Preload default reader types so content detection has something to work with
  if #SILE.inputters == 0 then
    for _, format in ipairs(preloadedinputters) do
      local _ = SILE.inputters[format]
    end
  end
  local contentDetectionOrder = {}
  for _, inputter in pairs(SILE.inputters) do
    if inputter.order then table.insert(contentDetectionOrder, inputter) end
  end
  table.sort(contentDetectionOrder, function (a, b) return a.order < b.order end)
  local initialround = filename and 1 or 2
  for round = initialround, 3 do
    for _, inputter in ipairs(contentDetectionOrder) do
      SU.debug("inputter", "Running content type detection round", round, "with", inputter._name)
      if inputter.appropriate(round, filename, doc) then
        return inputter._name
      end
    end
  end
  SU.error(("Unable to pick inputter to process input from '%s'"):format(filename))
end

--- Process an input string.
-- First converts the string to an AST, then runs `process` on it.
-- @tparam string doc Input string to be coverted to SILE content.
-- @tparam[opt] nil|string format The name of the formatter. If nil, defaults to using each intputter's auto detection.
-- @tparam[opt] nil|string filename Pseudo filename to identify the content with, useful for error messages stack traces.
-- @tparam[opt] nil|table options Options to pass to the inputter instance when instantiated.
function SILE.processString (doc, format, filename, options)
  local cpf
  if not filename then
    cpf = SILE.currentlyProcessingFile
    local caller = debug.getinfo(2, "Sl")
    SILE.currentlyProcessingFile = caller.short_src..":"..caller.currentline
  end
  -- In the event we're processing the master file *and* the user gave us
  -- a specific inputter to use, use it at the exclusion of all content type
  -- detection
  local inputter
  if filename and pl.path.normcase(pl.path.normpath(filename)) == pl.path.normcase(SILE.input.filenames[1]) and SILE.inputter then
    inputter = SILE.inputter
  else
    format = format or detectFormat(doc, filename)
    if not SILE.quiet then
      io.stderr:write(("<%s> as %s\n"):format(SILE.currentlyProcessingFile, format))
    end
    inputter = SILE.inputters[format](options)
    -- If we did content detection *and* this is the master file, save the
    -- inputter for posterity and postambles
    if filename and pl.path.normcase(filename) == pl.path.normcase(SILE.input.filenames[1]:gsub("^-$", "STDIN")) then
      SILE.inputter = inputter
    end
  end
  local pId = SILE.traceStack:pushDocument(SILE.currentlyProcessingFile, doc)
  inputter:process(doc)
  SILE.traceStack:pop(pId)
  if cpf then SILE.currentlyProcessingFile = cpf end
end

--- Process an input file
-- Opens a file, converts the contents to an AST, then runs `process` on it.
-- Roughly equivalent to listing the file as an input, but easier to embed in code.
-- @tparam string filename Path of file to open string to be coverted to SILE content.
-- @tparam[opt] nil|string format The name of the formatter. If nil, defaults to using each intputter's auto detection.
-- @tparam[opt] nil|table options Options to pass to the inputter instance when instantiated.
function SILE.processFile (filename, format, options)
  local doc
  if filename == "-" then
    filename = "STDIN"
    doc = io.stdin:read("*a")
  else
    -- Turn slashes around in the event we get passed a path from a Windows shell
    filename = filename:gsub("\\", "/")
    if not SILE.masterFilename then
      SILE.masterFilename = pl.path.splitext(pl.path.normpath(filename))
    end
    if SILE.input.filenames[1] and not SILE.masterDir then
      SILE.masterDir = pl.path.dirname(SILE.input.filenames[1])
    end
    if SILE.masterDir and SILE.masterDir:len() >= 1 then
      _G.extendSilePath(SILE.masterDir)
      _G.extendSilePathRocks(SILE.masterDir .. "/lua_modules")
    end
    filename = SILE.resolveFile(filename) or SU.error("Could not find file")
    local mode = lfs.attributes(filename).mode
    if mode ~= "file" and mode ~= "named pipe" then
      SU.error(filename.." isn't a file or named pipe, it's a ".. mode .."!")
    end
    if SILE.makeDeps then
      SILE.makeDeps:add(filename)
    end
    local file, err = io.open(filename)
    if not file then
      print("Could not open "..filename..": "..err)
      return
    end
    doc = file:read("*a")
  end
  local cpf = SILE.currentlyProcessingFile
  SILE.currentlyProcessingFile = filename
  local pId = SILE.traceStack:pushDocument(filename, doc)
  local ret = SILE.processString(doc, format, filename, options)
  SILE.traceStack:pop(pId)
  SILE.currentlyProcessingFile = cpf
  return ret
end

-- TODO: this probably needs deprecating, moved here just to get out of the way so
-- typesetters classing works as expected
function SILE.typesetNaturally (frame, func)
  local saveTypesetter = SILE.typesetter
  if SILE.typesetter.frame then SILE.typesetter.frame:leave(SILE.typesetter) end
  SILE.typesetter = SILE.typesetters.base(frame)
  SILE.settings:temporarily(func)
  SILE.typesetter:leaveHmode()
  SILE.typesetter:chuck()
  SILE.typesetter.frame:leave(SILE.typesetter)
  SILE.typesetter = saveTypesetter
  if SILE.typesetter.frame then SILE.typesetter.frame:enter(SILE.typesetter) end
end

--- Resolve relative file paths to identify absolute resources locations.
-- Makes it possible to load resources from relative paths, relative to a document or project or SILE itself.
-- @tparam string filename Name of file to find using the same order of precidence logic in `require()`.
-- @tparam[opt] nil|string pathprefix Optional prefix in which to look for if the file isn't found otherwise.
function SILE.resolveFile (filename, pathprefix)
  local candidates = {}
  -- Start with the raw file name as given prefixed with a path if requested
  if pathprefix then candidates[#candidates+1] = pl.path.join(pathprefix, "?") end
  -- Also check the raw file name without a path
  candidates[#candidates+1] = "?"
  -- Iterate through the directory of the master file, the SILE_PATH variable, and the current directory
  -- Check for prefixed paths first, then the plain path in that fails
  if SILE.masterDir then
    for path in SU.gtoke(SILE.masterDir..";"..tostring(os.getenv("SILE_PATH")), ";") do
      if path.string and path.string ~= "nil" then
        if pathprefix then candidates[#candidates+1] = pl.path.join(path.string, pathprefix, "?") end
        candidates[#candidates+1] = pl.path.join(path.string, "?")
      end
    end
  end
  -- Return the first candidate that exists, also checking the .sil suffix
  local path = table.concat(candidates, ";")
  local resolved, err = package.searchpath(filename, path, "/")
  if resolved then
    if SILE.makeDeps then SILE.makeDeps:add(resolved) end
  elseif SU.debugging("paths") then
    SU.debug("paths", ("Unable to find file '%s': %s"):format(filename, err))
  end
  return resolved
end

--- Execute a registered SILE command.
-- Uses a function previously registered by any modules explicitly loaded by the user at runtime via `--use`, the SILE
-- core, the document class, or any loaded package.
-- @tparam string command Command name.
-- @tparam[opt={}] nil|table options Options to pass to the command.
-- @tparam[opt] nil|table content Any valid AST node to be processed by the command.
function SILE.call (command, options, content)
  options = options or {}
  content = content or {}
  if SILE.traceback and type(content) == "table" and not content.lno then
    -- This call is from code (no content.lno) and we want to spend the time
    -- to determine everything we need about the caller
    local caller = debug.getinfo(2, "Sl")
    content.file, content.lno = caller.short_src, caller.currentline
  end
  local pId = SILE.traceStack:pushCommand(command, content, options)
  if not SILE.Commands[command] then SU.error("Unknown command " .. command) end
  local result = SILE.Commands[command](options, content)
  SILE.traceStack:pop(pId)
  return result
end

--- (Deprecated) Register a function as a SILE command.
-- Takes any Lua function and registers it for use as a SILE command (which will in turn be used to process any content
-- nodes identified with the command name.
--
-- Note that alternative versions of this action are available as methods on document classes and packages. Those
-- interfaces should be prefered to this global one.
-- @tparam string name Name of cammand to register.
-- @tparam function func Callback function to use as command handler.
-- @tparam[opt] nil|string help User friendly short usage string for use in error messages, documentation, etc.
-- @tparam[opt] nil|string pack Information identifying the module registering the command for use in error and usage
-- messages. Usually auto-detected.
function SILE.registerCommand (name, func, help, pack, cheat)
  local class = SILE.documentState.documentClass
  if not cheat then
    SU.deprecated("SILE.registerCommand", "class:registerCommand", "0.14.0", "0.16.0",
    [[Commands are being scoped to the document classes they are loaded into rather than being globals.]])
  end
  -- Shimming until we have all scope cheating removed from core
  if not cheat or not class or class.type ~= "class" then
    return SILE.classes.base.registerCommand(nil, name, func, help, pack)
  end
  return class:registerCommand(name, func, help, pack)
end

--- Wrap an existing command with new default options.
-- Modifies an already registered SILE command with a new table of options to be used as default values any time it is
-- called. Calling options still take precidence.
-- @tparam string command Name of command to overwride.
-- @tparam table options Options to set as updated defaults.
function SILE.setCommandDefaults (command, options)
  local oldCommand = SILE.Commands[command]
  SILE.Commands[command] = function (defaults, content)
    for k, v in pairs(options) do
      defaults[k] = defaults[k] or v
    end
    return oldCommand(defaults, content)
  end
end

-- TODO: Move to new table entry handler in types.unit
function SILE.registerUnit (unit, spec)
  -- If a unit exists already, clear it first so we get fresh meta table entries, see #1607
  if SILE.types.unit[unit] then
    SILE.types.unit[unit] = nil
  end
  SILE.types.unit[unit] = spec
end

function SILE.paperSizeParser (size)
  SU.deprecated("SILE.paperSizeParser", "SILE.papersize", "0.15.0", "0.16.0")
  return SILE.papersize(size)
end

--- Finalize document processing
-- Signals that all the `SILE.process()` calls have been made and SILE should move on to finish up the output
--
-- 1. Tells the document class to run its `:finish()` method. This method is typically responsible for calling the
-- `:finish()` method of the outputter module in the appropriate sequence.
-- 2. Closes out anything in active memory we don't need like font instances.
-- 3. Evaluate any snippets in SILE.input.evalAfter table.
-- 4. Stops logging dependecies and writes them to a makedepends file if requested.
-- 5. Close out the Lua profiler if it was running.
-- 6. Output version information if versions debug flag is set.
function SILE.finish ()
  SILE.documentState.documentClass:finish()
  SILE.font.finish()
  runEvals(SILE.input.evaluateAfters, "evaluate-after")
  if SILE.makeDeps then
    SILE.makeDeps:write()
  end
  if not SILE.quiet then
    io.stderr:write("\n")
  end
  if SU.debugging("profile") then
    ProFi:stop()
    ProFi:writeReport(pl.path.splitext(SILE.input.filenames[1]) .. '.profile.txt')
  end
  if SU.debugging("versions") then
    SILE.shaper:debugVersions()
  end
end

-- Internal libraries that return classes, but we only ever use one instantiation
SILE.traceStack = require("core.tracestack")()
SILE.settings = require("core.settings")()

-- Internal libraries that run core SILE functions on load
require("core.hyphenator-liang")
require("core.languages")
SILE.linebreak = require("core.break")
require("core.frame")
SILE.font = require("core.font")

return SILE
