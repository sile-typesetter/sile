SILE = {}
SILE.version = "0.0.1"
SILE.utilities = require("core/utilities")
SU = SILE.utilities
SILE.inputs = {}
SILE.Commands = {};

SILE.documentState = {};
SILE.scratch = {};


SILE.length = require("core/length")
require("core/frame")
require("core/measurements")
require("core/inputs-texlike")
require("core/inputs-xml")
require("core/pango-shaper")
require("core/papersizes")
require("core/typesetter")
SILE.frameParser = require("core/frameparser")
SILE.nodefactory = require("core/nodefactory")
SILE.linebreak = require("core/break")
require("core/cairo-output")
require("core/baseclass")

SILE.require = function(d)
  -- path?
  return require(d)
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
  local sniff = file:read("*l")
  file:seek("set", 0)
  if sniff:find("^<") then
    SILE.inputs.XML.process(fn)
  else
    SILE.inputs.TeXlike.process(file)
  end
end
return SILE
