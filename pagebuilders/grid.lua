local base = require("pagebuilders.base")

local pagebuilder = pl.class(base)
pagebuilder._name = "grid"

function pagebuilder:_init ()
   base._init(self)
end

function pagebuilder.findBestBreak (_, options)
   local vboxlist = SU.required(options, "vboxlist", "in findBestBreak")
   local target = SU.required(options, "target", "in findBestBreak")
   local i = 0
   local totalHeight = SILE.length()
   local bestBreak = 0
   SU.debug(
      "pagebuilder",
      "Page builder for frame",
      SILE.typesetter.frame.id,
      "called with",
      #vboxlist,
      "nodes,",
      target
   )
   if SU.debugging("vboxes") then
      for j, box in ipairs(vboxlist) do
         SU.debug("vboxes", (j == i and " >" or "  ") .. j .. ": " .. box)
      end
   end
   while i < #vboxlist do
      i = i + 1
      if not vboxlist[i].is_vglue then
         i = i - 1
         break
      end
   end
   while i < #vboxlist do
      i = i + 1
      local node = vboxlist[i]
      SU.debug("pagebuilder", "Dealing with VBox", node)
      if node.is_vbox then
         totalHeight = totalHeight + node.height:absolute() + node.depth:absolute()
      elseif node.is_vglue then
         totalHeight = totalHeight + node.height:absolute()
      elseif node.is_insertion then
         -- TODO: refactor as hook and without side effects!
         target = SILE.insertions.processInsertion(vboxlist, i, totalHeight, target)
         node = vboxlist[i]
      end
      local left = target - totalHeight
      local _left = left:tonumber()
      SU.debug("pagebuilder", "I have", left, "left")
      SU.debug("pagebuilder", "totalHeight", totalHeight, "with target", target)
      local badness = 0
      if _left < 0 then
         badness = 1000000
      end
      if node.is_penalty then
         if node.penalty < -3000 then
            badness = 100000
         else
            badness = -_left * _left - node.penalty
         end
      end
      if badness > 0 then
         local onepage = {}
         for j = 1, bestBreak do
            onepage[j] = table.remove(vboxlist, 1)
         end
         while #onepage > 1 and onepage[#onepage].discardable do
            onepage[#onepage] = nil
         end
         return onepage, 1000
      end
      bestBreak = i
   end
   return false, false
end

return pagebuilder
