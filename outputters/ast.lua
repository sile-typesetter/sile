local base = require("outputters.base")
local serpent = require("serpent")

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
   local serialized = serpent.serialize(
      ast,
      {
         comment = false,
         compact = true,
         fatal = true,
         indent = "   ",
         metatostring = false,
         sortkeys = true,
         sparse = true,
      }
   )
   outfile:write(serialized)
end

function outputter:finish ()
   self:runHooks("prefinish")
   outfile:close()
end

return outputter
