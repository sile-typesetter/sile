local base = require("outputters.base")

local outputter = pl.class(base)
outputter._name = "ast"
outputter.extension = "ast"

local outfile

function outputter:_ensureInit ()
   if not outfile then
      local fname = self:getOutputFilename()
      outfile = fname == "-" and io.stdout or io.open(fname, "w+")
   end
end

function outputter:preProcess (ast)
   self:_ensureInit()
   local prettyprinted = pl.pretty.write(ast, "   ")
   outfile:write(prettyprinted)
end

function outputter:finish ()
   self:runHooks("prefinish")
   outfile:close()
end

return outputter
