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
   SILE.fontmanager = SILE.fontmanager or SILE.fontmanagers[SILE.input.fontmanager or "default"]()
   if SILE.input.backend then
      if SILE.input.backend == "cairo" then
         SILE.shaper = SILE.shapers[SILE.input.shaper or "pango"]()
      end
      SILE.outputter = SILE.outputters[SILE.input.outputter or SILE.input.backend]()
   end
   SILE.shaper = SILE.shaper or SILE.shapers[SILE.input.shaper or "default"]()
   SILE.outputter = SILE.outputter or SILE.outputters[SILE.input.outputter or "libtexpdf"]()
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
   SILE.frames:dump()
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
