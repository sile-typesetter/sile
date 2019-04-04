SILE = {}
SILE.version = "0.9.5.1"
SILE.utilities = require("core/utilities")
SU = SILE.utilities
SILE.inputs = {}
SILE.Commands = {}
SILE.debugFlags = {}
SILE.nodeMakers = {}
SILE.tokenizers = {}

loadstring = loadstring or load -- 5.3 compatibility
if not unpack then unpack = table.unpack end -- 5.3 compatibility
std = require("std")
lfs = require("lfs")
if (os.getenv("SILE_COVERAGE")) then require("luacov") end

SILE.documentState = std.object {}
SILE.scratch = {}
SILE.length = require("core/length")
require("core/parserbits")
require("core/measurements")
require("core/baseclass")
SILE.nodefactory = require("core/nodefactory")
require("core/settings")
require("core/inputs-texlike")
require("core/inputs-xml")
require("core/inputs-common")
require("core/papersizes")
require("core/colorparser")
require("core/pagebuilder")
require("core/typesetter")
require("core/hyphenator-liang")
require("core/languages")
require("core/font")
require("core/packagemanager")
require("core/math")

SILE.frameParser = require("core/frameparser")
SILE.linebreak = require("core/break")

require("core/frame")

SILE.init = function ()
  if not SILE.backend then
    if pcall(function () require("justenoughharfbuzz") end) then
      SILE.backend = "libtexpdf"
    else
      SU.error("libtexpdf backend not available!")
    end
  end
  if SILE.backend == "libtexpdf" then
    require("core/harfbuzz-shaper")
    require("core/libtexpdf-output")
  end
  if SILE.dolua then
    for _, func in pairs(SILE.dolua) do
      _, err = pcall(func)
      if err then error(err) end
    end
  end
end

SILE.require = function (dependency, pathprefix)
  local file = SILE.resolveFile(dependency..".lua", pathprefix)
  if file then return require(file:gsub(".lua$","")) end
  if pathprefix then
    local status, lib = pcall(require, std.io.catfile(pathprefix, dependency))
    return status and lib or require(dependency)
  end
  return require(dependency)
end

SILE.parseArguments = function()
local parser = std.optparse ("SILE "..SILE.version..[[

Usage: sile [options] file.sil|file.xml

The SILE typesetter reads a single input file in either SIL or XML format to
generate an output in PDF format. The output will be writted to the same name
as the input file with the extention changed to .pdf.

Options:

  -b, --backend=VALUE      choose an alternative output backend
  -d, --debug=VALUE        debug SILE's operation
  -e, --evaluate=VALUE     evaluate some Lua code before processing file
  -o, --output=[FILE]      explicitly set output file name
  -I, --include=[FILE]     include a class or SILE file before processing input
  -h, --help               display this help, then exit
  -v, --version            display version information, then exit
]])

  parser:on ('--', parser.finished)
  _G.unparsed, _G.opts = parser:parse(_G.arg)
  -- Turn slashes around in the event we get passed a path from a Windows shell
  if _G.unparsed[1] then
    SILE.masterFilename = _G.unparsed[1]:gsub("\\", "/")
    -- Strip extension
    SILE.masterFilename = string.match(SILE.masterFilename,"(.+)%..-$") or SILE.masterFilename
  end
  SILE.debugFlags = {}
  if opts.backend then
    SILE.backend = opts.backend
  end
  if opts.debug then
    for k,v in ipairs(std.string.split(opts.debug, ",")) do SILE.debugFlags[v] = 1 end
  end
  if opts.evaluate then
    local statements = type(opts.evaluate) == "table" and opts.evaluate or { opts.evaluate }
    SILE.dolua = {}
    for _, statement in ipairs(statements) do
      local func, err = loadstring(statement)
      if err then SU.error(err) end
      SILE.dolua[#SILE.dolua+1] = func
    end
  end
  if opts.output then
    SILE.outputFilename = opts.output
  end
  if opts.include then
    SILE.preamble = type(opts.include) == "table" and opts.include or { opts.include }
  end
end

function SILE.initRepl ()
  SILE._repl          = require 'repl.console'
  local has_linenoise = pcall(require, 'linenoise')

  if has_linenoise then
    SILE._repl:loadplugin 'linenoise'
  else
    -- XXX check that we're not receiving input from a non-tty
    local has_rlwrap = os.execute('which rlwrap >/dev/null 2>/dev/null') == 0

    if has_rlwrap and not os.getenv 'LUA_REPL_RLWRAP' then
      local command = 'LUA_REPL_RLWRAP=1 rlwrap'
      local index = 0
      while arg[index - 1] do
        index = index - 1
      end
      while arg[index] do
        command = string.format('%s %q', command, arg[index])
        index = index + 1
      end
      os.execute(command)
      return
    end
  end

  SILE._repl:loadplugin 'history'
  SILE._repl:loadplugin 'completion'
  SILE._repl:loadplugin 'autoreturn'
  SILE._repl:loadplugin 'rcfile'
end

function SILE.repl()
  if not SILE._repl then SILE.initRepl() end
  SILE._repl:run()
end

function SILE.readFile(filename)
  SILE.currentlyProcessingFile = filename
  local doc = nil
  if filename == "-" then
    io.stderr:write("<STDIN>\n")
    doc = io.stdin:read("*a")
  else
    filename = SILE.resolveFile(filename)
    if not filename then
      SU.error("Could not find file")
    end
    local mode = lfs.attributes(filename).mode
    if mode ~= "file" and mode ~= "named pipe" then
      SU.error(filename.." isn't a file or named pipe, it's a ".. mode .."!")
    end
    local file, err = io.open(filename)
    if not file then
      print("Could not open "..filename..": "..err)
      return
    end
    io.stderr:write("<"..filename..">\n")
    doc = file:read("*a")
  end
  local sniff = doc:sub(1, 100):gsub("begin.*", "") or ""
  local inputsOrder = {}
  for n in pairs(SILE.inputs) do
    if SILE.inputs[n].order then table.insert(inputsOrder, n) end
  end
  table.sort(inputsOrder,function(a,b) return SILE.inputs[a].order < SILE.inputs[b].order end)
  for i = 1,#inputsOrder do local input = SILE.inputs[inputsOrder[i]]
    if input.appropriate(filename, sniff) then
      input.process(doc)
      return
    end
  end
  SU.error("No input processor available for "..filename.." (should never happen)",1)
end

local function file_exists (filename)
   local file = io.open(filename, "r")
   if file ~= nil then return io.close(file) else return false end
end

-- Sort through possible places files could be
function SILE.resolveFile(filename, pathprefix)
  local candidates = {}
  -- Start with the raw file name as given prefixed with a path if requested
  if pathprefix then candidates[#candidates+1] = std.io.catfile(pathprefix, filename) end
  -- Also check the raw file name without a path
  candidates[#candidates+1] = filename
  -- Iterate through the directory of the master file, the SILE_PATH variable, and the current directory
  -- Check for prefixed paths first, then the plain path in that fails
  if SILE.masterFilename then
    local dirname = SILE.masterFilename:match("(.-)[^%/]+$")
    for path in SU.gtoke(dirname..";"..tostring(os.getenv("SILE_PATH")), ";") do
      if path.string and path.string ~= "nil" then
        if pathprefix then candidates[#candidates+1] = std.io.catfile(path.string, pathprefix, filename) end
        candidates[#candidates+1] = std.io.catfile(path.string, filename)
      end
    end
  end
  -- Return the first candidate that exists, also checking the .sil suffix
  for i, v in pairs(candidates) do
    if file_exists(v) then return v end
    if file_exists(v..".sil") then return v .. ".sil" end
  end
  -- If we got here then no files existed even resembling the requested one
  return nil
end

function SILE.call(cmd, options, content)
  SILE.currentCommand = content
  if not SILE.Commands[cmd] then SU.error("Unknown command "..cmd) end
  SILE.Commands[cmd](options or {}, content or {})
end

return SILE
