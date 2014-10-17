SILE = {}
SILE.version = "0.9.0"
SILE.utilities = require("core/utilities")
SU = SILE.utilities
SILE.inputs = {}
SILE.Commands = {};
SILE.debugFlags = {}

std = require("std")

SILE.documentState = std.object {};
SILE.scratch = {};
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
require("core/font")

SILE.frameParser = require("core/frameparser")
SILE.linebreak = require("core/break")

require("core/frame")

if pcall(function () require("justenoughharfbuzz") end) then
  require("core/harfbuzz-shaper")
  require("core/podofo-output")
else
  require("core/pango-shaper")
  require("core/cairo-output")
end

SILE.require = function(d)
  -- path?
  return require(d)
end

SILE.parseArguments = function()
local parser = std.optparse ("This is SILE "..SILE.version..[[

 Usage: sile

 Banner text.

 Optional long description text to show when the --help
 option is passed.

 Several lines or paragraphs of long description are permitted.

 Options:

   -d, --debug=VALUE        debug SILE's operation
   -I, --include=[FILE]     accept an optional argument
       --version            display version information, then exit
       --help               display this help, then exit
]])

  parser:on ('--', parser.finished)
  _G.unparsed, _G.opts = parser:parse(_G.arg)
  SILE.debugFlags = {}
  if opts.debug then
    for k,v in ipairs(std.string.split(opts.debug, ",")) do SILE.debugFlags[v] = 1 end
  end
  if opts.include then
    SILE.preamble = opts.include
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
  if _VERSION:match("5.2") then
    setfenv = function(f, t)
        f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
        local name
        local up = 0
        repeat
            up = up + 1
            name = debug.getupvalue(f, up)
        until name == '_ENV' or name == nil
        if name then
    debug.upvaluejoin(f, up, function() return t end, 1) -- use unique upvalue, set it to f
        end
    end
  end
  if not SILE._repl then SILE.initRepl() end
  SILE._repl:run()
end

function SILE.readFile(fn)
  SILE.currentlyProcessingFile = fn
  fn = SILE.resolveFile(fn)
  local file, err = io.open(fn)
  if not file then
    print("Could not open "..err)
    return
  end
  io.write("<"..fn..">")
  -- Sniff first few bytes
  local sniff = file:read("*l") or ""
  file:seek("set", 0)
  if sniff:find("<") then
    SILE.inputs.XML.process(fn)
  else
    SILE.inputs.TeXlike.process(fn)
  end
end

local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function SILE.resolveFile(fn)
  if file_exists(fn) then return fn end
  if file_exists(fn..".sil") then return fn..".sil" end

  for k in SU.gtoke(os.getenv("SILE_PATH"), ";") do
    if k.string then
      local f = std.io.catfile(k.string, fn)
      if file_exists(f) then return f end
      if file_exists(f..".sil") then return f..".sil" end
    end
  end
end

function SILE.call(cmd,options, content)
  if not SILE.Commands[cmd] then SU.error("Unknown command "..cmd) end
  SILE.Commands[cmd](options or {}, content or {})
end

return SILE
