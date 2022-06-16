local function init (_, _)

  require("core.harfbuzz-shaper")

  SILE.shapers.harfbuzzWithColor = pl.class(SILE.shapers.harfbuzz)

  function SILE.shapers.harfbuzzWithColor:shapeToken (str, options)
    local ot = require("core.opentype-parser")
    if not options.family then return {} end
    local face = SILE.font.cache(options, SILE.shaper.getFace)
    local font = ot.parseFont(face)
    local items = self._base.shapeToken(self, str, options)
    if font.colr and font.cpal then
      local newItems = {}
      for i = 1, #items do
        local layers = font.colr[items[i].gid]
        if layers then
          for j = 1, #layers do
            local item = items[i]
            local layer = layers[j]
            local width = 0
            local height = 0
            local text = ""
            if j == #layers then
              width = item.width
              height = item.height
              text = item.text
            end
            -- XXX: handle multiple palette, add a font option?
            local color = font.cpal[1][layer.paletteIndex]
            local newItem = {
              gid = layer.gid,
              glyphAdvance = item.glyphAdvance,
              width = width,
              height = height,
              depth = item.depth,
              index = item.index,
              x_offset = item.x_offset,
              y_offset = item.y_offset,
              text = text,
              color = color,
            }
            newItems[#newItems+1] = newItem
          end
        else
          newItems[#newItems+1] = items[i]
        end
      end
      return newItems
    end
    return items
  end

  function SILE.shapers.harfbuzzWithColor:createNnodes (token, options)
    local items, _ = self:shapeToken(token, options)
    if #items < 1 then return {} end
    local lang = options.language
    SILE.languageSupport.loadLanguage(lang)
    local nodeMaker = SILE.nodeMakers[lang] or SILE.nodeMakers.unicode
    local run = { [1] = { slice = {}, color = items[1].color, chunk = "" } }
    for i = 1, #items do
      if items[i].color ~= run[#run].color then
        run[#run+1] = { slice = {}, chunk = "", color = items[i].color }
        if i <#items then
          run[#run].color = items[i].color
        end
      end
      run[#run].chunk = run[#run].chunk .. items[i].text
      run[#run].slice[#(run[#run].slice)+1] = items[i]
    end
    local nodes = {}
    for i=1, #run do
      options = pl.tablex.deepcopy(options)
      if run[i].color then
        nodes[#nodes+1] = SILE.nodefactory.hbox({
          outputYourself = function () SILE.outputter:pushColor(run[i].color) end
        })
      end
      for node in nodeMaker(options):iterator(run[i].slice, run[i].chunk) do
        nodes[#nodes+1] = node
      end
      if run[i].color then
        nodes[#nodes+1] = SILE.nodefactory.hbox({
          outputYourself = function () SILE.outputter:popColor() end
        })
      end
    end
    return nodes
  end

  SILE.shaper = SILE.shapers.harfbuzzWithColor()

end

return {
  init = init,
  documentation = [[
\begin{document}
  The \autodoc:package{color-fonts} package adds support for fonts with a \code{COLR}
  OpenType table. This package is automatically loaded when such a font is
  detected.
\end{document}
]]
}
