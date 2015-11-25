local sep = lpeg.S(",;")
local quotedString = (lpeg.P("\"") * lpeg.C((1-lpeg.S("\""))^1) * lpeg.P("\"")) / function(t) return t end
local value = (quotedString + lpeg.C((1-lpeg.S(",;]"))^1))
local list = (value * sep^-1)^0

SILE.shapers.harfbuzzWithFallback = SILE.shapers.harfbuzz {
  shapeToken = function (self, text, options)
    local items = {}
    local shapeQueue = { [1] = { start =1, stop = #text }, [2] = { popFallbacks = true } }
    options = std.tree.clone(options)
    if not options.font then return {} end
    local toTry = { list:match(options.font) }
    while #shapeQueue > 0 and #toTry > 0 do
      SU.debug("fonts", "Queue: ".. shapeQueue)
      options.font = toTry[1]
      local qItem = table.remove(shapeQueue, 1)
      SU.debug("fonts", qItem)
      if qItem.popFallbacks then
        table.remove(toTry, 1)
        shapeQueue[#shapeQueue+1] = { popFallbacks = true }
      else
        if not options.font then SU.error("No fallbacks for text!") end
        local chunk = text:sub(qItem.start, qItem.stop)
        SU.debug("fonts", "Trying font '"..options.font.."' for '"..chunk.."'")
        local newItems = SILE.shapers.harfbuzz:shapeToken(chunk, options)
        local startOfNotdefRun = -1
        for i =1,#newItems do
          if newItems[i].codepoint > 0 then
            SU.debug("fonts", "Found glyph '"..newItems[i].text.."'")
            if startOfNotdefRun > -1 then
              shapeQueue[#shapeQueue+1] = {
                start = qItem.start + newItems[startOfNotdefRun].index,
                stop = qItem.start + newItems[i].index - 1
              }
              SU.debug("fonts", "adding run "..shapeQueue[#shapeQueue])
              startOfNotdefRun = -1
            end
            newItems[i].font = options.font
            items[qItem.start + newItems[i].index] = newItems[i]
          else
            if startOfNotdefRun == -1 then startOfNotdefRun = i end
            SU.warn("Glyph "..newItems[i].text.." not found in "..options.font)
          end
        end
        if startOfNotdefRun > -1 then
          shapeQueue[#shapeQueue+1] = {
            start = qItem.start + newItems[startOfNotdefRun].index,
            stop = qItem.stop
          }
          SU.debug("fonts", "Some unfound at end: ", shapeQueue[#shapeQueue])
        end
      end
    end
    local nItems = {} -- Remove holes
    for i=1,#text do if items[i] then nItems[#nItems+1] = items[i] end end
    SU.debug("fonts", nItems)
    return nItems
  end,
  createNnodes = function (self, token, options)
    local items, width = self:shapeToken(token, options)
    if #items < 1 then return {} end

    local lang = options.language
    SILE.languageSupport.loadLanguage(lang)
    local nodeMaker = SILE.nodeMakers[lang] or SILE.nodeMakers.unicode
    local run = { [1] = {slice = {}, font = items[1].font, chunk = "" } }
    for i = 1,#items do
      if items[i].font ~= run[#run].font then
        run[#run+1] = { slice = {}, chunk = "", font = items[i].font }
        if i <#items then
          run[#run].font = items[i].font
        end
      end
      run[#run].chunk = run[#run].chunk .. items[i].text
      run[#run].slice[#(run[#run].slice)+1] = items[i]
    end
    local nodes = {}
    for i=1,#run do
      options = std.tree.clone(options)
      options.font = run[i].font
      SU.debug("fonts", "Shaping ".. run[i].chunk.. " in ".. options.font)
      for node in (nodeMaker { options=options }):iterator(run[i].slice, run[i].chunk) do
        nodes[#nodes+1] = node
      end
    end
    SU.debug("fonts", nodes)
    return nodes
  end,
}

SILE.shaper = SILE.shapers.harfbuzzWithFallback
