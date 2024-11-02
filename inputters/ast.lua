local base = require("inputters.base")
local serpent = require("serpent")

local inputter = pl.class(base)
inputter._name = "ast"

inputter.order = 35

function inputter.appropriate (round, filename, doc)
   if round == 1 then
      return filename:match(".ast$")
   elseif round == 2 then
      local sniff = doc:sub(1, 100)
      local promising = sniff:match("^{\n   [^ ]") or sniff:match("command =") or sniff:match("loadstring or load")
      return promising and inputter.appropriate(3, filename, doc) or false
   elseif round == 3 then
      local status, _ = serpent.load(doc, { safe = true })
      return status and true or false
   end
end

function inputter.parse (_, doc)
   local status, result = serpent.load(doc, { safe = true })
   if not status then
      SU.error(result)
   end
   return result
end

function inputter:process (doc)
   local tree = self:parse(doc)
   if not tree.type then
      -- hoping tree is an AST
      self:requireClass(tree)
      return SILE.process(tree)
   else
      SILE.use(tree, self.options)
   end
end

return inputter

