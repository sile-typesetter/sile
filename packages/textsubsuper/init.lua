--
-- Text superscript and subscript package for SILE
-- using OpenType features when available.
-- 2021-2022, Didier Willis
-- Derived from an idea sketched by Simon Cozens
-- in https://github.com/sile-typesetter/sile/issues/1258
-- License: MIT
--
local inputfilter = require("packages/inputfilter").exports

local textFeatCache = {}

local _key = function (options, text)
  -- We don't use the size in the cache key, as we don't expect it to
  -- change whether features are supported or not...
  return table.concat({
      text,
      options.family,
      ("%d"):format(options.weight or 0),
      options.style,
      options.variant,
      options.features,
      options.filename,
    }, ";")
end

local function textFeatCaching (options, text, status)
  local key = _key(options, text)
  if textFeatCache[key] == nil then
    textFeatCache[key] = status
  end
  return status
end

local function checkFontFeatures (features, content)
  local text = SU.contentToString(content)
  if tonumber(text) ~= nil then
    -- Avoid caching any sequence of digits. Plus, we want
    -- consistency here.
    text="0123456789"
  end
  local fontOptions = SILE.font.loadDefaults({ features = features })
  local supported = textFeatCache[_key(fontOptions, text)]
  if supported ~= nil then
    return supported
  end

  local items1 = SILE.shaper:shapeToken(text, fontOptions)
  local items2 = SILE.shaper:shapeToken(text, SILE.font.loadDefaults({}))

  -- Don't mix up characters supporting the features with those
  -- not supporting them, as it would be ugly in most cases.
  if #items1 ~= #items2 then
    return textFeatCaching(fontOptions, text, false)
  end
  for i = 1, #items1 do
    if items1[i].width == items2[i].width and items1[i].height == items2[i].height then
      return textFeatCaching(fontOptions, text, false)
    end
  end
  return textFeatCaching(fontOptions, text, true)
end

local function getItalicAngle ()
  local ot = require("core.opentype-parser")
  local fontoptions = SILE.font.loadDefaults({})
  local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
  local font = ot.parseFont(face)
  return font.post.italicAngle
end

local function getWeightClass ()
  -- Provided we return it in the font parser, maybe we could
  -- rather do:
  -- local ot = require("core.opentype-parser")
  -- local fontoptions = SILE.font.loadDefaults({})
  -- local face = SILE.font.cache(fontoptions, SILE.shaper.getFace)
  -- local font = ot.parseFont(face)
  -- return font.os2.usWeightClass
  return SILE.settings:get("font.weight")
end

local function rescaleFilter (node, content, args)
  if type(node) == "table" then return node end
  local result = {}
  local chars = SU.splitUtf8(node)
  for _, char in ipairs(chars) do
    if not tonumber(char) then
      result[#result+1] = inputfilter.createCommand(
        content.pos, content.col, content.line,
        "textsubsuper:scale", {
          xRatio = args.xScale,
          yRatio = args.yScaleOther
        }, { char }
      )
    else
      result[#result+1] = inputfilter.createCommand(
        content.pos, content.col, content.line,
        "textsubsuper:scale", {
          xRatio = args.xScale,
          yRatio = args.yScaleNumber
        }, { char }
      )
    end
  end
  return result
end

local function rescaleContent(content)
  local transformed
  if SILE.outputter ~= SILE.outputters.libtexpdf then
    -- Not supported
    transformed = content
  else
    transformed = inputfilter.transformContent(content, rescaleFilter, {
      xScale = 1,
      yScaleNumber = SILE.settings:get("textsubsuper.vscale.number"),
      yScaleOther = SILE.settings:get("textsubsuper.vscale.other"),
    })
  end
  SILE.process(transformed)
 end

local function declareSettings (_)
  SILE.settings:declare({
    parameter = "textsubsuper.scale",
    type = "integer",
    default = 0.66,
    help = "Size scaling ratio of a fake superscript or subsscript"
  })

  SILE.settings:declare({
    parameter = "textsubsuper.bolder",
    type = "integer",
    default = 200,
    help = "Weight increase of a fake superscript or subsscript (e.g. 200 for normal to semibold)"
  })

  SILE.settings:declare({
    parameter = "textsubsuper.vscale.number",
    type = "number",
    default = 0.90,
    help = "Vertical ratio applied to numbers in fake superscript or subsscript"
  })

  SILE.settings:declare({
    parameter = "textsubsuper.vscale.other",
    type = "number",
    default = 0.95,
    help = "Vertical ratio applied to numbers in fake superscript or subsscript"
  })

  SILE.settings:declare({
    parameter = "textsubsuper.offset.superscript",
    type = "measurement",
    default = SILE.measurement("0.70ex"),
    help = "Offset of a fake superscript above the baseline (logically in a font-relative unit such as ex)"
  })

  SILE.settings:declare({
    parameter = "textsubsuper.offset.subscript",
    type = "measurement",
    default = SILE.measurement("0.25ex"),
    help = "Offset of a fake subscript below the baseline (logically in a font-relative unit such as ex)"
  })
end

local function registerCommands (_)
  -- REAL SUPERSCRIPT / SUBSCRIPT WHEN AVAILABLE

  SILE.registerCommand("textsuperscript", function (options, content)
    if type(content) ~= "table" then SU.error("Expected a table content in textsuperscript") end
    if SU.boolean(options.fake, false) then
      SILE.call("textsuperscript:fake", {}, content)
      return
    end
    if checkFontFeatures("+sups", content) then
      SILE.call("font", { features="+sups" }, content)
    else
      SU.debug("textsubsuper", "No true superscripts for '"..SU.contentToString(content).."', fallback to scaling")
      SILE.call("textsuperscript:fake", {}, content)
    end
  end, "Typeset a superscript text content.")

  SILE.registerCommand("textsubscript", function (options, content)
    if type(content) ~= "table" then SU.error("Expected a table content in textsubscript") end
    if SU.boolean(options.fake, false) then
      SILE.call("textsubscript:fake", {}, content)
      return
    end
    if checkFontFeatures("+subs", content) then
      SILE.call("font", { features="+subs" }, content)
    elseif checkFontFeatures("+sinf", content) then
      SU.debug("textsubsuper", "No true subscripts for '"..SU.contentToString(content).."', fallback to scientific inferiors")
      SILE.call("font", { features="+sinf" }, content)
    else
      SU.debug("textsubsuper", "No true subscripts for '"..SU.contentToString(content).."', fallback to scaling")
      SILE.call("textsubscript:fake", {}, content)
    end
  end, "Typeset a subscript text content.")

  -- FAKE (SCALED AND RAISED) SUPERSCRIPT OR SUBSCRIPT

  SILE.registerCommand("textsuperscript:fake", function (_, content)
    SILE.require("packages/raiselower")
    local italicAngle = getItalicAngle()
    local weight = getWeightClass()

    local ratio = SILE.settings:get("textsubsuper.scale")
    local ySize = ratio * SILE.settings:get("font.size")
    local yOffset = SILE.settings:get("textsubsuper.offset.superscript")
    local xOffset = -math.sin(italicAngle * math.pi / 180) * yOffset
    SILE.call("kern", { width = xOffset:absolute() + SILE.measurement("0.1pt") })
    SILE.call("raise", { height = yOffset }, function ()
      -- Some font have +onum enabled by default...
      -- Some don't even have it (e.g. Brill), but support +lnum for enforcing lining
      -- figures. We try to ensure we are not using oldstyle numbers...
      SILE.call("font", {
        size = ySize,
        weight = weight == 400 and (weight + SILE.settings:get("textsubsuper.bolder")) or weight,
        features = "+lnum -onum",
      }, function ()
        rescaleContent(content)
      end)
    end)
    SILE.call("kern", { width = -xOffset / 2 })
  end, "Typeset a fake (raised, scaled) superscript content.")

  SILE.registerCommand("textsubscript:fake", function (_, content)
    SILE.require("packages/raiselower")
    local italicAngle = getItalicAngle()
    local weight = getWeightClass()

    local ratio = SILE.settings:get("textsubsuper.scale")
    local ySize = ratio * SILE.settings:get("font.size")
    local yOffset = SILE.settings:get("textsubsuper.offset.subscript")
    local xOffset = -math.sin(italicAngle * math.pi / 180) * yOffset:absolute()
    SILE.call("kern", { width = -xOffset })
    SILE.call("lower", { height = yOffset }, function ()
      SILE.call("font", {
        size = ySize,
        weight = weight == 400 and (weight + SILE.settings:get("textsubsuper.bolder")) or weight,
        features = "+lnum +onum",
      }, function ()
        rescaleContent(content)
      end)
    end)
    SILE.call("kern", { width = xOffset })
  end, "Typeset a fake (lowered, scaled) subscript content.")

  -- RE-SCALING BY SOME RATIOS

  SILE.registerCommand("textsubsuper:scale", function (options, content)
    -- Here assume the ouputter to be libtexpdf
    -- This is supposed to be checked earlier above.
    local pdf = require("justenoughlibtexpdf")

    local hbox = SILE.call("hbox", {}, content)
    table.remove(SILE.typesetter.state.nodes) -- Remove the box from queue

    local xRatio, yRatio = options.xRatio, options.yRatio
    SILE.typesetter:pushHbox({
      width = hbox.width * xRatio,
      height = SILE.length(),
      depth = SILE.length(),
      outputYourself = function(self, typesetter, line)
        local X = typesetter.frame.state.cursorX
        local Y = typesetter.frame.state.cursorY
        local x0 = X:tonumber()
        local y0 = -Y:tonumber()
        typesetter.frame.state.cursorY = Y
        pdf:gsave()
        pdf.setmatrix(1, 0, 0, 1, x0, y0)
        pdf.setmatrix(xRatio, 0, 0, yRatio, 0, 0)
        pdf.setmatrix(1, 0, 0, 1, -x0, -y0)
        hbox.outputYourself(hbox, typesetter, line)
        pdf:grestore()
        typesetter.frame.state.cursorX = X
        typesetter.frame.state.cursorY = Y
        typesetter.frame:advanceWritingDirection(self.width)
      end
    })
  end, "Scale content by some horizontal and vertical ratios")
end

return {
  declareSettings = declareSettings,
  registerCommands = registerCommands,
  documentation = [[\begin{document}
\script[src=packages/textsubsuper]% SILE 0.13 needs a big big FIXME, it's 0xDEADBEEF
Superscripts are sometimes needed for numbers (e.g. in footnote calls),
but also for letters (e.g. in French, century references such as
\font[features=+smcp]{xiv}\textsuperscript{e}, issue numbers such
as n\textsuperscript{os} 5–6; likewise in English, sequences such
as 14\textsuperscript{th}).
As of subscripts, chemical formulas are the most familiar example, for example
H\textsubscript{2}O or C\textsubscript{6}H\textsubscript{12}O\textsubscript{6}.

In his \em{Elements of Typographic Style} (3\textsuperscript{rd} edition, §4.3.2),
Robert Bringhurst writes: “Many fonts include sets of superscript numbers, but
these are not always of satisfactory size and design. Text numerals set at a
reduced size and elevated baseline are sometimes the best or only choice.”

Most of the time, however, assuming the font designers did their job well, such
“real” characters ought to look much better than scaled and raised characters.
SILE thrives at good typography. The \autodoc:package{textsubsuper} package
provides two commands, \autodoc:command{\textsuperscript{<content>}} and
\autodoc:command{\textsubscript{<content>}}, which aim at using these characters,
when available.

These commands achieve their goal by trying the \code{+sups} font feature for
superscripts, and the \code{+subs} or \code{+sinf} feature for subscripts.
If the output is not different than \em{without} the feature, it implies that
the corresponding OpenType feature is not supported by the font (such as the
default Gentium font, which does not have these features\footnote{Though it does
include some of the Unicode superscript and subscript characters, but this very
package does not try to address such a case.}). In that case, it relies on
scaling and raising (or lowering) the characters, so as to build “fake”
superscripts (or subscripts).

By nature, this package is \em{not} intended to work with multiple levels of
superscripts or subscripts. Also note that it tries not to mix up characters
supporting the features with those not supporting them, as it would be somewhat
ugly in most cases. Fake superscripts or superscripts will also be used if such
a case occurs.

Would you actually prefer this fake variant, the \autodoc:parameter{fake=true}
option on the above-mentioned commands enforces it.

In his afterword, Bringhurst also notes: “It remains the case that I have
never yet tested a perfect font, no matter whether it came in the form of
foundry metal, a matrix case, a strip of film or digital information.”
In our case here, if font designers had done their job all right again,
the OpenType OS2 table could have been used to retrieve the recommended
offset, scaling and sizing parameters for a given font face. However, these
parameters are seldom properly set and they lead to a poor (not to say
utterly wrong) result for many fonts, including well-known ones…

This package therefore relies on its own settings,
\autodoc:setting{textsubsuper.scale},
\autodoc:setting{textsubsuper.offset.superscript}
and \autodoc:setting{textsubsuper.offset.subscript}.
Their default values are, by nature, empirical.

Bringhurst goes on: “In many faces, smaller numbers in semibold look better
than larger numbers of regular weight.” Hence,
the \autodoc:setting{textsubsuper.bolder} setting defaults to 200,
so that in a text in normal weight (400), superscripts and subscripts
are set in semibold (600). This setting is ignored if the input text
is not in normal weight.

Would the text be set in italic, the package relies on the italic
angle from the font properties to improve the superscript or
subscript placement.

Still, this is not sufficient to give the best possible output.
Smaller numbers are usually scaled vertically to a proportion of the
full height they would take at regular size. This is also often the case
for letters, albeit to a smaller amount.
Settings \autodoc:setting{textsubsuper.vscale.number} and
\autodoc:setting{textsubsuper.vscale.other} are thus available
to obtain that effect\footnote{This feature is currently only supported
with the \code{libtexpdf} backend.}.
Their default values, again, are obviously empirical.
\end{document}]]
}
