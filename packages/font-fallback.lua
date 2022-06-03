local fallbackQueue = pl.class({

    _init = function (self, text, fallbacks)
      self.q = {}
      self.fallbacks = fallbacks
      self.text = text
      self.q[1] = { start =1, stop = #text }
      self.q[#(self.q)+1] = { popFallbacks = true }
    end,

    pop = function (self)
      table.remove(self.fallbacks, 1)
      table.remove(self.q, 1)
      self.q[#(self.q)+1] = { popFallbacks = true }
    end,

    shift       = function (self)
      return table.remove(self.q, 1)
    end,

    continuing  = function (self)
      return #self.q > 0 and #self.fallbacks > 0
    end,

    currentFont = function (self)
      return self.fallbacks[1]
    end,

    currentJob  = function (self)
      return self.q[1]
    end,

    lastJob     = function (self)
      return self.q[#(self.q)]
    end,

    currentText = function (self)
      return self.text:sub(self.q[1].start, self.q[1].stop)
    end,

    addJob = function (self, start, stop)
      self.q[#(self.q)+1] = { start = start, stop = stop }
    end

  })

local fontlist = {}

SILE.shapers.harfbuzzWithFallback = pl.class(SILE.shapers.harfbuzz)

function SILE.shapers.harfbuzzWithFallback:shapeToken (text, options)
  local items = {}
  local optionSet = { options }
  for i = 1, #fontlist do
    local moreOptions = pl.tablex.deepcopy(options)
    for k, v in pairs(fontlist[i]) do moreOptions[k] = v end
    optionSet[#optionSet+1] = moreOptions
  end
  local shapeQueue = fallbackQueue(text, optionSet)
  while shapeQueue:continuing() do
    SU.debug("fonts", "Queue: " .. tostring(shapeQueue.q))
    options = shapeQueue:currentFont()
    if not (options.family or options.filename) then return end
    SU.debug("fonts", shapeQueue:currentJob())
    if shapeQueue:currentJob().popFallbacks then shapeQueue:pop()
    else
      local chunk = shapeQueue:currentText()
      SU.debug("fonts", "Trying font '"..options.family.."' for '"..chunk.."'")
      local newItems = self._base.shapeToken(self, chunk, options)
      local startOfNotdefRun = -1
      for i = 1, #newItems do
        if newItems[i].gid > 0 then
          SU.debug("fonts", "Found glyph '"..newItems[i].text.."'")
          local start = shapeQueue:currentJob().start
          if startOfNotdefRun > -1 then
            shapeQueue:addJob(start + newItems[startOfNotdefRun].index,
            start + newItems[i].index - 1)
            SU.debug("fonts", "adding run " .. tostring(shapeQueue:lastJob()))
            startOfNotdefRun = -1
          end
          newItems[i].fontOptions = options
          -- There might be multiple glyphs for the same index
          if not items[start + newItems[i].index] then
            items[start + newItems[i].index] = newItems[i]
          else
            local lastInPlace = items[start + newItems[i].index]
            while lastInPlace.next do lastInPlace = lastInPlace.next end
            lastInPlace.next = newItems[i]
          end
        else
          if startOfNotdefRun == -1 then startOfNotdefRun = i end
          SU.debug("font-fallback", "Glyph " .. newItems[i].text .. " not found in " .. options.family)
        end
      end
      if startOfNotdefRun > -1 then
        shapeQueue:addJob(
        shapeQueue:currentJob().start + newItems[startOfNotdefRun].index,
        shapeQueue:currentJob().stop
        )
        SU.warn("Some glyph(s) not available in any fallback font, run with '-d font-fallback' for more detail")
      end
      shapeQueue:shift()
    end
  end
  local nItems = {} -- Remove holes
  for i = 1, math.max(0, table.unpack(pl.tablex.keys(items))) do
    if items[i] then
      nItems[#nItems+1] = items[i]
      while items[i].next do
        local nextG = items[i].next
        items[i].next = nil
        nItems[#nItems+1] = nextG
        items[i] = nextG
      end
    end
  end
  SU.debug("fonts", nItems)
  return nItems
end

function SILE.shapers.harfbuzzWithFallback:createNnodes (token, options)
  local items, _ = self:shapeToken(token, options)
  if #items < 1 then return {} end
  local lang = options.language
  SILE.languageSupport.loadLanguage(lang)
  local nodeMaker = SILE.nodeMakers[lang] or SILE.nodeMakers.unicode
  local run = { [1] = { slice = {}, fontOptions = items[1].fontOptions, chunk = "" } }
  for i = 1, #items do
    if items[i].fontOptions ~= run[#run].fontOptions then
      run[#run+1] = { slice = {}, chunk = "", fontOptions = items[i].fontOptions }
      if i <#items then
        run[#run].fontOptions = items[i].fontOptions
      end
    end
    run[#run].chunk = run[#run].chunk .. items[i].text
    run[#run].slice[#(run[#run].slice)+1] = items[i]
  end
  local nodes = {}
  for i=1, #run do
    options = run[i].fontOptions
    SU.debug("fonts", "Shaping ".. run[i].chunk.. " in ".. options.family)
    for node in nodeMaker(options):iterator(run[i].slice, run[i].chunk) do
      nodes[#nodes+1] = node
    end
  end
  SU.debug("fonts", nodes)
  return nodes
end

SILE.shaper = SILE.shapers.harfbuzzWithFallback()

local function registerCommands (_)

  SILE.registerCommand("font:clear-fallbacks", function ()
    fontlist = {}
  end)

  SILE.registerCommand("font:add-fallback", function (options, _)
    fontlist[#fontlist+1] = options
  end)

  SILE.registerCommand("font:remove-fallback", function ()
    fontlist[#fontlist] = nil
  end, "Pop last added fallback from fallback stack")

end

return {
  registerCommands = registerCommands,
  documentation = [[
\begin{document}

What happens when SILE is asked to typeset a character which is not in the
current font? For instance, we are currently using the “Gentium” font, which
covers a wide range of European scripts; however, it doesn’t contain any
Japanese character. So what if I ask SILE to typeset \code{abc
\font[family=Noto Sans CJK JP]{あ}}?

Many applications will find another font on the system containing the
appropriate character and use that font instead. But which font should
be chosen? SILE is designed for typesetting situations where the document
or class author wants complete control over the typographic appearance
of the output, so it’s not appropriate for it to make a guess—besides,
you asked for Gentium. So where the glyph is not defined, SILE will give
you the current font’s “glyph not defined” symbol (a glyph called \code{.notdef})
instead.

But there are times when this is just too strict. If you’re typesetting
a document in English and Japanese, you should be able to choose your
English font and choose your Japanese font, and if the glyph isn’t available
in one, SILE should try the other. The \autodoc:package{font-fallback} package gives you
a way to specify a list of font specifications, and it will try each one in
turn if glyphs cannot be found.

It provides two commands, \autodoc:command{\font:add-fallback} and
\autodoc:command{\font:clear-fallbacks}.
The parameters to \autodoc:command{\font:add-fallback} are the same as the
parameters to \autodoc:command{\font}. So this code:

\begin{verbatim}
\line
\\font:add-fallback[family=Symbola]
\\font:add-fallback[family=Noto Sans CJK JP]
\line
\end{verbatim}

will add two fonts to try if characters are not found in the current font.
Now we can say:

\font:add-fallback[family=Symbola]
\font:add-fallback[family=Noto Sans CJK JP]

\begin{verbatim}
あば x 😼 Hello world. あ
\end{verbatim}

and SILE will produce:

\examplefont{あば x 😼 Hello world. あ}

\font:remove-fallback
\font:remove-fallback

\autodoc:command{\font:clear-fallbacks} removes all font fallbacks from the list
of fonts to try.

\autodoc:command{\font:remove-fallback} removes the last added fallback from the
list of fonts to try.

\end{document}
]]}
