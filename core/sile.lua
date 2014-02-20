SILE = {}
SILE.version = "0.0.1"
SILE.utilities = require("core/utilities")
SU = SILE.utilities
SILE.inputs = {}
SILE.Commands = {};

SILE.documentState = {};
SILE.scratch = {};

std = require("std")
SILE.length = require("core/length")
require("core/frame")
require("core/measurements")
require("core/inputs-texlike")
require("core/inputs-xml")
require("core/inputs-common")
require("core/pango-shaper")
require("core/papersizes")
require("core/typesetter")
require("core/hyphenator-liang")
SILE.frameParser = require("core/frameparser")
SILE.nodefactory = require("core/nodefactory")
SILE.linebreak = require("core/break")
require("core/cairo-output")
require("core/baseclass")

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

_G.arg, _G.opts = parser:parse(_G.arg)
parser:on ('--', parser.finished)
SILE.debugFlags = {}
if opts.debug then
  for k,v in ipairs(std.string.split(opts.debug, ",")) do SILE.debugFlags[v] = 1 end
end
end

function SILE.repl ()
  local repl          = require 'repl.console'
  local has_linenoise = pcall(require, 'linenoise')

  if has_linenoise then
    repl:loadplugin 'linenoise'
  else
    -- XXX check that we're not receiving input from a non-tty
    local has_rlwrap = os.execute('which rlwrap >/dev/null 2>/dev/null') == 0

    if has_rlwrap and not os.getenv 'LUA_REPL_RLWRAP' then
      local lowest_index = -1

      while arg[lowest_index] ~= nil do
        lowest_index = lowest_index - 1
      end
      lowest_index = lowest_index + 1
      os.execute(string.format('LUA_REPL_RLWRAP=1 rlwrap %q %q', arg[lowest_index], arg[0]))
      return
    end
  end

  repl:loadplugin 'history'
  repl:loadplugin 'completion'
  repl:loadplugin 'autoreturn'
  repl:loadplugin 'rcfile'
  repl:run()
end

function SILE.readFile(fn)
  local file, err = io.open(fn)
  if not file then
    print("Could not open "..err)
    return
  end
  io.write("<"..fn..">")
  -- Sniff first few bytes
  local sniff = file:read("*l") or ""
  file:seek("set", 0)
  if sniff:find("^<") then
    SILE.inputs.XML.process(fn)
  else
    SILE.inputs.TeXlike.process(fn)
  end
end
return SILE
