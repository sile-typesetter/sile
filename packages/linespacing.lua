local metrics = require("fontmetrics")

SILE.settings.declare({
  name = "linespacing.method",
  default = "tex",
  type = "string",
  help = "How to set the line spacing (tex, fixed, fit-font, fit-glyph, css)"
})

SILE.settings.declare({
  name = "linespacing.fixed.baselinedistance",
  default = SILE.length.parse("1.2em"),
  type = "Length",
  help = "Distance from baseline to baseline in the case of fixed line spacing"
})

SILE.settings.declare({
  name = "linespacing.minimumfirstlineposition",
  default = SILE.length.parse("0"),
  type = "Length"
})

SILE.settings.declare({
  name = "linespacing.fit-glyph.extra-space",
  default = SILE.length.parse("0"),
  type = "Length"
})

SILE.settings.declare({
  name = "linespacing.fit-font.extra-space",
  default = SILE.length.parse("0"),
  type = "Length"
})

SILE.settings.declare({
  name = "linespacing.css.line-height",
  default = SILE.length.parse("1.2em"),
  type = "Length"
})

local metricscache = {}

local getLineMetrics = function (l)
  local linemetrics = {ascender = 0, descender = 0, lineheight = 0}
  if not l or not l.nodes then return linemetrics end
  for i = 1,#(l.nodes) do n = l.nodes[i]; if n:isNnode() then
    local m = metricscache[SILE.font._key(n.options)]
    if not m then
      local face = SILE.font.cache(n.options, SILE.shaper.getFace)
      m = metrics.get_typographic_extents(face.data, face.index)
      m.ascender = m.ascender * n.options.size
      m.descender = m.descender * n.options.size
      metricscache[SILE.font._key(n.options)] = m
    end
    SILE.settings.temporarily(function()
      SILE.call("font", n.options, {})
      m.lineheight = SILE.settings.get("linespacing.css.line-height"):absolute().length
    end)
    if m.ascender > linemetrics.ascender then linemetrics.ascender = m.ascender end
    if m.descender > linemetrics.descender then linemetrics.descender = m.descender end
    if m.lineheight > linemetrics.lineheight then linemetrics.lineheight = m.lineheight end
  end end
  return linemetrics
end

SILE.typesetter.leadingFor = function (self, v, previous)
  local method = SILE.settings.get("linespacing.method")

  local firstline = SILE.settings.get("linespacing.minimumfirstlineposition"):absolute()
  if not previous and firstline.length > 0 then
    toAdd = SILE.length.new({ length = firstline.length -v.height })
    return SILE.nodefactory.newVKern({ height = toAdd })
  end

  if method == "tex" then
    return SILE.defaultTypesetter:leadingFor(v,previous)
  end

  if method == "fit-glyph" then
    local extra = SILE.settings.get("linespacing.fit-glyph.extra-space"):absolute()
    local toAdd = SILE.length.new(extra)
    return SILE.nodefactory.newVglue({ height = toAdd })
  end

  if method == "fixed" then
    local btob = SILE.settings.get("linespacing.fixed.baselinedistance"):absolute()
    local toAdd = SILE.length.new({ length = btob.length - (v.height + (previous and previous.depth or 0)) })
    local vg = SILE.nodefactory.newVglue({ height = toAdd })
	if previous == nil then
      vg.discardable = false
      vg.isVglue = function() return false end
    end
    return vg
  end

  -- For these methods, we need to read the font metrics
  if not metrics then
    SU.error("'"..method.."' line spacing method requires freetype, which is not available.")
  end

  local thismetrics = getLineMetrics(v)
  local prevmetrics = getLineMetrics(previous)
  if method == "fit-font" then
    -- Distance to next baseline is max(descender) of fonts on previous +
    -- max(ascender) of fonts on next
    local extra = SILE.settings.get("linespacing.fit-font.extra-space"):absolute()
    local btob = prevmetrics.descender + thismetrics.ascender + extra
    local toAdd = btob - (v.height + (previous and previous.depth or 0))
    return SILE.nodefactory.newVglue({ height = SILE.length.make(toAdd)})
  end

  if method == "css" then
    local lh = prevmetrics.lineheight
    local leading = (lh - (prevmetrics.ascender + prevmetrics.descender))
    if previous then
      previous.height = previous.height + leading / 2
      previous.depth = previous.depth + leading / 2
    end
    return SILE.nodefactory.newVglue({ height = SILE.length.new({ length = 0  }) })

  end

  SU.error("Unknown line spacing method "..method)
end
