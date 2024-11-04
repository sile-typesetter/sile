local base = require("inputters.base")

local inputter = pl.class(base)
inputter._name = "lua"

inputter.order = 99

function inputter.appropriate (round, filename, doc)
   if round == 1 then
      return filename:match(".lua$")
   elseif round == 2 then
      local sniff = doc:sub(1, 100)
      local promising = sniff:match("^%-%-") or sniff:match("^local") or sniff:match("^return")
      return promising and inputter.appropriate(3, filename, doc) or false
   elseif round == 3 then
      local status, _ = load(doc)
      return status and true or false
   end
end

function inputter.parse (_, doc)
   local result, err = load(doc, SILE.currentlyProcessingFile)
   if not result then
      SU.error(err)
   end
   return result
end

function inputter:process (doc)
   local tree = self:parse(doc)()
   if type(tree) == "string" then
      return SILE.processString(tree, nil, nil, self.options)
   elseif type(tree) == "function" then
      SILE.process(tree)
   elseif type(tree) == "table" then
      if not tree.type then
         -- hoping tree is an AST
         self:requireClass(tree)
         return SILE.process(tree)
      else
         SILE.use(tree, self.options)
      end
   end
end

return inputter
