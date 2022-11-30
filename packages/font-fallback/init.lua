local base = require("packages.base")

local package = pl.class(base)
package._name = "font-fallback"

local lastshaper

local fallbackQueue = pl.class({

    _init = function (self, text, fallbacks)
      self.fallbacks = fallbacks
      self.runs = {
        {
          options = self:currentOptions(),
          offset = 0,
          start = 1,
          -- WARNING: shaper index is in bytes, not UTF8 aware character
          -- lengths so do *not* use luautf8.len() here
          stop = text:len()
        },
      }
      self._fallbacks = fallbacks
      self.text = text
      self.pending = nil
    end,

    popFallback = function (self)
      return table.remove(self.fallbacks, 1)
    end,

    popRun = function (self)
      self:popFallback()
      return table.remove(self.runs, 1)
    end,

    currentOptions = function (self)
      return self.fallbacks[1]
    end,

    nextFallback = function (self)
      return self.fallbacks[2]
    end,

    currentRun = function (self)
      return self.runs[1]
    end,

    currentText = function (self)
      local run = self:currentRun()
      -- WARNING: shaper index is in bytes, not UTF8 aware character
      -- lengths so do *not* use luautf8.sub() here
      return self.text:sub(run.start, run.stop)
    end,

    addRun = function (self, offset, start)
      if not self.pending then
        SU.debug("font-fallback", function ()
          return ("New run pending for %s starting byte %s insert at %s"):format(self:currentText(), start, offset)
        end)
        local options = self:nextFallback()
        if not options then return false end
        options.size = SILE.measurement(options.size):tonumber()
        self.pending = {
          options = options,
          offset = offset,
          start = start
        }
      end
      return true
    end,

    pushNextRun = function (self, stop)
      if self.pending then
        SU.debug("font-fallback", function ()
          return ("Push pending run for %s ending at %s"):format(self:currentText(), stop)
        end)
        self.pending.stop = stop
        table.insert(self.runs, self.pending)
        self.pending = nil
      end
    end

  })

local activeFallbacks = {}

function package:_init ()
  base._init(self)

  local harfbuzz = require("shapers.harfbuzz")

  SILE.shapers.harfbuzzWithFallback = pl.class(harfbuzz)
  SILE.shapers.harfbuzzWithFallback._name = "harfbuzzWithFallback"

  function SILE.shapers.harfbuzzWithFallback.shapeToken (self_, text, options)
    local items = {}
    local fallbackOptions = { options }
    for _, font in ipairs(activeFallbacks) do
      table.insert(fallbackOptions, pl.tablex.merge(options, font, true))
    end
    local shapeQueue = fallbackQueue(text, fallbackOptions)
    repeat -- iterate fallbacks
      SU.debug("font-fallback", function ()
        return ("Start fallback iteration for text '%s'"):format(text)
      end)
      local run = shapeQueue:currentRun()
      local face = run.options.family:len() > 0 and run.options.family or run.options.filename
      local chunk = shapeQueue:currentText()
      SU.debug("font-fallback", function ()
        return ("Try shaping chunk '%s' with '%s'"):format(chunk, face)
      end)
      local candidate_items = self_._base.shapeToken(self_, chunk, run.options)
      local _index
      for _, item in ipairs(candidate_items) do
        item.fontOptions = run.options
        if item.gid == 0 or item.name == ".null" or item.name == ".notdef" then
          SU.debug("font-fallback", function ()
            return ("Glyph %s not found in %s"):format(item.text, face)
          end)
          local newstart = run.start + item.index
          local pending = shapeQueue:addRun(run.offset, newstart)
          if not pending then
            SU.warn(("Glyph(s) '%s' not available in any fallback font,\n  run with '-d font-fallback' for more detail.\n"):format(item.text))
            run.offset = run.offset + 1
            table.insert(items, run.offset, item) -- output tofu if we're out of fallbacks
          end
        else
          SU.debug("font-fallback", function ()
            return ("Found glyph '%s' in '%s'"):format(item.text, face)
          end)
          shapeQueue:pushNextRun(run.start + item.index - 1) -- if notdef run pending, end it
          if item.index == _index then
            local previous = items[run.offset]
            while previous.next do previous = previous.next end
            previous.next = item
          else
            _index = run.index
            run.offset = run.offset + 1
            table.insert(items, run.offset, item)
          end
        end
      end
      shapeQueue:pushNextRun(run.stop) -- if notdef run pending, end it
      shapeQueue:popRun()
    until not shapeQueue:currentRun()
    return items
  end

  function SILE.shapers.harfbuzzWithFallback.createNnodes (self_, token, options)
    local items, _ = self_:shapeToken(token, options)
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
      SU.debug("font-fallback", "Shaping", run[i].chunk, "in", options.family)
      for node in nodeMaker(options):iterator(run[i].slice, run[i].chunk) do
        nodes[#nodes+1] = node
      end
    end
    SU.debug("font-fallback", nodes)
    return nodes
  end

end

function package:registerCommands ()

  self:registerCommand("font:clear-fallbacks", function ()
    activeFallbacks = {}
    if SILE.shaper._name == "harfbuzzWithFallback" and lastshaper then
      SU.debug("font-fallback", "Clearing fallbacks, switching from fallback enabled back to previous shaper")
      SILE.typesetter:leaveHmode(true)
      SILE.shaper, lastshaper = lastshaper, nil
    end
  end)

  self:registerCommand("font:add-fallback", function (options, _)
    if SILE.shaper._name ~= "harfbuzzWithFallback" then
      SU.debug("font-fallback", "Switching to fallback enabaled shaper")
      SILE.typesetter:leaveHmode(true)
      lastshaper, SILE.shaper = SILE.shaper, SILE.shapers.harfbuzzWithFallback()
    end
    table.insert(activeFallbacks, options)
  end)

  self:registerCommand("font:remove-fallback", function ()
    table.remove(activeFallbacks)
    if #activeFallbacks == 0 and SILE.shaper._name == "harfbuzzWithFallback" and lastshaper then
      SU.debug("font-fallback", "Fallback list empty, switching from fallback enabled back to previous shaper")
      SILE.typesetter:leaveHmode(true)
      SILE.shaper, lastshaper = lastshaper, nil
    end
  end, "Pop last added fallback from fallback stack")

end

package.documentation = [[
\begin{document}
What happens when SILE is asked to typeset a character which is not in the current font?
For instance, we are currently using the “Gentium” font, which covers a wide range of European scripts; however, it doesn’t contain any Japanese character.
  So what if I ask SILE to typeset \code{abc \font[family=Noto Sans CJK JP]{あ}}?

Many applications will find another font on the system containing the appropriate character and use that font instead.
But which font should be chosen?
SILE is designed for typesetting situations where the document or class author wants complete control over the typographic appearance of the output, so it’s not appropriate for it to make a guess—besides, you asked for Gentium.
So where the glyph is not defined, SILE will give you the current font’s “glyph not defined” symbol (a glyph called \code{.notdef}) instead.

But there are times when this is just too strict.
If you’re typesetting a document in English and Japanese, you should be able to choose your English font and choose your Japanese font, and if the glyph isn’t available in one, SILE should try the other.
  The \autodoc:package{font-fallback} package gives you a way to specify a list of font specifications, and it will try each one in turn if glyphs cannot be found.

It provides two commands, \autodoc:command{\font:add-fallback} and \autodoc:command{\font:clear-fallbacks}.
The parameters to \autodoc:command{\font:add-fallback} are the same as the parameters to \autodoc:command{\font}.
So this code:

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

\autodoc:command{\font:clear-fallbacks} removes all font fallbacks from the list of fonts to try.

\autodoc:command{\font:remove-fallback} removes the last added fallback from the list of fonts to try.
\end{document}
]]

return package
