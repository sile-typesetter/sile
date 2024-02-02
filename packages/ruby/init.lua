local base = require("packages.base")

local package = pl.class(base)
package._name = "ruby"

local isLatin = function (char)
  return (char > 0x20 and char <= 0x24F) or (char >= 0x300 and char <= 0x36F)
    or (char >= 0x1DC0 and char <= 0x1EFF) or (char >= 0x2C60 and char <= 0x2c7F)
end

local checkIfSpacerNeeded = function (reading)
  -- First, did we have a ruby node at all?
  if not SILE.scratch.lastRubyBox then return end
  -- Does the current reading start with a latin?
  if not isLatin(SU.codepoint(SU.firstChar(reading))) then return end
  -- Did we have some nodes recently?
  local top = #SILE.typesetter.state.nodes
  if top < 2 then return end
  -- Have we had other stuff since the last ruby node?
  if SILE.typesetter.state.nodes[top] ~= SILE.scratch.lastRubyBox
     and SILE.typesetter.state.nodes[top-1] ~= SILE.scratch.lastRubyBox then
    return
  end
  -- Does the previous reading end with a latin?
  if not isLatin(SU.codepoint(SU.lastChar(SILE.scratch.lastRubyText))) then return end
  -- OK, we need a spacer!
  SILE.typesetter:pushGlue(SILE.settings:get("ruby.latinspacer"))
end

function package:_init ()
  base._init(self)
  -- Japanese language support defines units which are useful here
  self:loadPackage("font-fallback")
  SILE.call("font:add-fallback", { family = "Noto Sans CJK JP" })
  SILE.languageSupport.loadLanguage("ja")
end

function package.declareSettings (_)

  SILE.settings:declare({
    parameter = "ruby.height",
    type = "measurement",
    default = SILE.measurement("1zw"),
    help = "Vertical offset between the ruby and the main text"
  })

  SILE.settings:declare({
    parameter = "ruby.latinspacer",
    type = "glue",
    default = SILE.nodefactory.glue("0.25em"),
    help = "Glue added between consecutive Latin ruby"
  })

  SILE.settings:declare({
    parameter = "ruby.opentype",
    type = "boolean",
    default = true,
    help = "Use OpenType tate feature instead of of a bold weight"
  })

end

function package:registerCommands ()

  self:registerCommand("ruby:font", function (_, _)
    if SILE.settings:get("ruby.opentype") then
      SILE.call("font", { size = "0.6zw", features = "+ruby" })
    else
      SILE.call("font", { size = "0.6zw", weight = 700 })
    end
  end)

  self:registerCommand("ruby", function (options, content)
    local reading = SU.required(options, "reading", "\\ruby")
    SILE.typesetter:setpar("")

    checkIfSpacerNeeded(reading)

    local rubybox = SILE.call("hbox", {}, function ()
      SILE.settings:temporarily(function ()
        SILE.call("noindent")
        SILE.call("ruby:font")
        SILE.typesetter:typeset(reading)
      end)
    end)
    rubybox.outputYourself = function (box, typesetter, line)
      local ox = typesetter.frame.state.cursorX
      local oy = typesetter.frame.state.cursorY
      typesetter.frame:advanceWritingDirection(rubybox.width)
      typesetter.frame:advancePageDirection(-SILE.settings:get("ruby.height"))
      SILE.outputter:setCursor(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
      for i = 1, #(box.value) do
        local node = box.value[i]
        node:outputYourself(typesetter, line)
      end
      typesetter.frame.state.cursorX = ox
      typesetter.frame.state.cursorY = oy
    end
    -- measure the content
    local cbox = SILE.call("hbox", {}, content)
    SU.debug("ruby", "base box is", cbox)
    SU.debug("ruby", "reading is", rubybox)
    if cbox:lineContribution() > rubybox:lineContribution() then
      SU.debug("ruby", "Base is longer, offsetting ruby to fit")
      -- This is actually the offset against the base
      rubybox.width = SILE.length(cbox:lineContribution() - rubybox:lineContribution())/2
    else
      local diff = rubybox:lineContribution() - cbox:lineContribution()
      local to_insert = SILE.length(diff / 2)
      SU.debug("ruby", "Ruby is longer, inserting", to_insert, "either side of base")
      cbox.width = rubybox:lineContribution()
      rubybox.height = 0
      rubybox.width = 0
      -- add spaces at beginning and end
      table.insert(cbox.value, 1, SILE.nodefactory.glue(to_insert))
      table.insert(cbox.value, SILE.nodefactory.glue(to_insert))
    end
    SILE.scratch.lastRubyBox = rubybox
    SILE.scratch.lastRubyText = reading
  end)

end

package.documentation = [[
\begin{document}
\font:add-fallback[family=Noto Sans CJK JP]
\use[module=packages.ruby]
Japanese texts often contain pronunciation hints (called \em{furigana}) for difficult kanji or foreign words.
These hints are traditionally placed either above (in horizontal typesetting) or beside (in vertical typesetting) the word that they explain.
The typesetting term for these glosses is \em{ruby}.

The \autodoc:package{ruby} package provides the \autodoc:command[check=false]{\ruby[reading=<ruby text>]{<base text>}} command which sets a piece of ruby above or beside the base text.
For example:

\set[parameter=ruby.height,value=12pt]
\define[command=ja]{\font[family=Noto Sans CJK JP,language=ja]{\process}}

\begin{autodoc:codeblock}
\\ruby[reading=\ja{れいわ}]\{\ja{令和}\}
\end{autodoc:codeblock}

Produces:
\medskip
\ja{\ruby[reading=れいわ]{令和}}

\font:remove-fallback
\end{document}
]]

return package
