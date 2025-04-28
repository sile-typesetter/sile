-- Reserve scope placeholder for profiler (developer tooling)
local ProFi

local function runEvals (evals, arg)
   for _, snippet in ipairs(evals) do
      local pId = SILE.traceStack:pushText(snippet)
      local status, func = pcall(load, snippet)
      if status and type(func) == "function" then
         func()
      else
         SU.error(("Error parsing code provided in --%s snippet: %s"):format(arg, snippet))
      end
      SILE.traceStack:pop(pId)
   end
end

local function init ()
   if SILE.input.makedeps then
      SILE.makeDeps = require("core.makedeps")
      SILE.makeDeps.filename = SILE.input.makedeps
   end
   if SILE.backend then
      SU.deprecated("SILE.backend", "SILE.input.backend", "0.15.7", "0.17.0")
      SILE.input.backend = SILE.backend
   end
   for _, tree in ipairs(SILE.input.luarocksTrees) do
      _G["extendSilePathRocks"](tree)
   end
   if not SILE.input.backend then
      SILE.input.backend = "libtexpdf"
   end
   if SILE.input.backend == "libtexpdf" then
      SILE.outputter = SILE.outputters.libtexpdf()
   elseif SILE.input.backend == "cairo" then
      SILE.outputter = SILE.outputters.cairo()
   elseif SILE.input.backend == "debug" then
      SILE.outputter = SILE.outputters.debug()
   elseif SILE.input.backend == "text" then
      SILE.outputter = SILE.outputters.text()
   elseif SILE.input.backend == "dummy" then
      SILE.outputter = SILE.outputters.dummy()
   end
   if not SILE.shaper then
      SILE.shaper = SILE.shapers.default()
   end
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

local function finish ()
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
      ProFi:writeReport(pl.path.splitext(SILE.input.filenames[1]) .. ".profile.txt")
   end
   if SU.debugging("versions") then
      SILE.shaper:debugVersions()
   end
end

return {
   init = init,
   finish = finish,
}
