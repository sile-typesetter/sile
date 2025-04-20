local base = require("packages.base")

local orig_makeGlue, orig_makeSpaceNode

local function xsan_makeGlue (node, item)
   node:addToken(" ", item)
   node:makeToken()
end

local function xsan_makeSpaceNode (shaper, options, _)
   orig_makeGlue = SILE.typesetters.language.nodemaker.makeGlue
   SILE.typesetters.language.nodemaker.makeGlue = xsan_makeGlue
   local nnodes = shaper:createNnodes(" ", options)
   local node = SILE.types.node.discretionary({ replacement = nnodes })
   SILE.typesetters.language.nodemaker.makeGlue = orig_makeGlue
   return node
end

local function toggle_complexspace_modifications (enable)
   if enable then
      orig_makeSpaceNode = SILE.shaper.makeSpaceNode
      SILE.shaper.makeSpaceNode = xsan_makeSpaceNode
   else
      SILE.shaper.makeSpaceNode = orig_makeSpaceNode
   end
end

local package = pl.class(base)
package._name = "complex-spaces"

function package:declareSettings ()
   SILE.settings:declare({
      parameter = "shaper.complexspaces",
      default = true,
      type = "boolean",
      hook = toggle_complexspace_modifications,
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
