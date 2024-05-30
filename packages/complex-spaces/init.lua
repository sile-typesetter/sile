local base = require("packages.base")

local package = pl.class(base)
package._name = "complex-spaces"

function package:_init ()
   base._init(self)
   if not SILE.languageSupport.languages["x-spaces-are-nodes"] then
      local xsan = pl.class(SILE.nodeMakers.unicode)
      function xsan.makeGlue (node, item)
         node:addToken(" ", item)
         node:makeToken()
      end
      SILE.nodeMakers["x-spaces-are-nodes"] = xsan
      SILE.languageSupport.languages["x-spaces-are-nodes"] = true
   end
   if SILE.shaper and not SILE.shaper.noncomplex_SpaceNode then
      SILE.shaper.noncomplex_SpaceNode = SILE.shaper.makeSpaceNode
      SILE.shaper.makeSpaceNode = function (_, options, item)
         if SILE.settings:get("shaper.complexspaces") then
            local myoptions = pl.tablex.deepcopy(options)
            myoptions.language = "x-spaces-are-nodes"
            local nnodes = SILE.shaper:createNnodes(" ", myoptions)
            return SILE.nodefactory.discretionary({ replacement = nnodes })
         end
         return SILE.shaper.noncomplex_SpaceNode(_, options, item)
      end
   end
end

function package.declareSettings (_)
   SILE.settings:declare({
      parameter = "shaper.complexspaces",
      default = true,
      type = "boolean",
      help = "Whether the font's space glyph should be emitted, rather than a glue",
   })
end

package.documentation = [[
\begin{document}
SILE normally assumes that the "space" character in a font is empty, and that it can be replaced with a stretchable and shrinkable space.
In some fonts (particularly color fonts), this is not a reliable assumption, and the space character may actually contain ink.
Loading this package will allow such space glyphs to be correctly rendered.
(At some point in the future, SILE will detect fonts with complex spaces and load this package automatically, but for now it needs to be manually loaded.)
\end{document}
]]

return package
