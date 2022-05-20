SILE.nodeMakers["x-spaces-are-nodes"] = pl.class({
    _base = SILE.nodeMakers.unicode,
    makeGlue = function (self, item)
      self:addToken(" ", item)
      self:makeToken()
    end
})

SILE.languageSupport.languages["x-spaces-are-nodes"] = true

SILE.settings:declare({
  parameter = "shaper.complexspaces",
  default = true,
  type = "boolean",
  help = "Whether the font's space glyph should be emitted, rather than a glue"
})

if SILE.shaper then
  local origSpaceNode = SILE.shaper.makeSpaceNode

  SILE.shaper.makeSpaceNode = function (_, options, item)
    if SILE.settings:get("shaper.complexspaces") then
      local myoptions = pl.tablex.deepcopy(options)
      myoptions.language = "x-spaces-are-nodes"
      local nnodes = SILE.shaper:createNnodes( " ", myoptions)
      return SILE.nodefactory.discretionary({replacement=nnodes})
    end
    return origSpaceNode(_, options, item)
  end
end

return {
  documentation = [[\begin{document}
SILE normally assumes that the "space" character in a font is empty, and that it
can be replaced with a stretchable and shrinkable space. In some fonts
(particularly color fonts), this is not a reliable assumption, and the space
character may actually contain ink. Loading this package will allow such space
glyphs to be correctly rendered. (At some point in the future, SILE will detect
fonts with complex spaces and load this package automatically, but for now it
needs to be manually loaded.)
\end{document}]] }
