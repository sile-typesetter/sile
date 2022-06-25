--
-- Struts (rules with no width but a certain height) for SILE
-- License: MIT
--

local function init (class, _)
  class:loadPackage("rebox")
end

local function declareSettings (_)
  SILE.settings:declare({
    parameter = "strut.character",
    type = "string",
    default = "|",
    help = "Strut character"
  })

  SILE.settings:declare({
    parameter = "strut.ruledepth",
    type = "measurement",
    default = SILE.measurement("0.3bs"),
    help = "Strut rule depth"
  })

  SILE.settings:declare({
    parameter = "strut.ruleheight",
    type = "measurement",
    default = SILE.measurement("1bs"),
    help = "Strut rule height"
  })
end

local function registerCommands (_)
  -- A strut character (for a given font selection) will be used a lot.
  -- It would be a bit dumb to recompute it each time, so let's cache it.
  local strutCache = {}
  local _key = function (options)
    return table.concat({ options.family, ("%d"):format(options.weight), options.style,
                          options.variant, options.features, options.filename }, ";")
  end
  local characterStrut = function ()
    local key = _key(SILE.font.loadDefaults({}))
    local strutCached = strutCache[key]
    if strutCached then return strutCached end
    local hbox = SILE.call("hbox", {}, { SILE.settings:get("strut.character") })
    table.remove(SILE.typesetter.state.nodes) -- steal it back
    strutCache[key] = {
      height = hbox.height,
      depth = hbox.depth,
    }
    return strutCache[key]
  end

  SILE.registerCommand("strut", function (options, _)
    local method = options.method or "character"
    local show = SU.boolean(options.show, true)
    local strut
    if method == "rule" then
      strut = {
        height = SILE.length(SILE.settings:get("strut.ruleheight")):absolute(),
        depth = SILE.length(SILE.settings:get("strut.ruledepth")):absolute(),
      }
      if show then
        -- The "x" there could be anything, we just want to be sure we get a box
        SILE.call("rebox", { phantom = true, height = strut.height, depth = strut.depth, width = SILE.length() }, {})
      end
    else
      strut = characterStrut()
      if show then
        SILE.call("rebox", { phantom = true, width = SILE.length() }, { SILE.settings:get("strut.character") })
      end
    end
    return strut
  end, "Formats a strut box, shows it if requested, returns its height and depth dimentions.")
end

return {
  init = init,
  declareSettings = declareSettings,
  registerCommands = registerCommands,
  documentation = [[\begin{document}
In professional typesetting, a “strut” is a rule with no width but a certain height
and depth, to help guaranteeing that an element has a certain minimal height and depth,
e.g. in tabular environments or in boxes.

Two possible implementations are proposed, one based on a character, defined
via the \autodoc:setting{strut.character} setting, by default the vertical bar (|),
and one relative to the current baseline skip, via the \autodoc:setting{strut.ruledepth}
and \autodoc:setting{strut.ruleheight} settings, by default respectively 0.3bs and 1bs,
following the same definition as in LaTeX. So they do not achieve exactly the same effect:
the former should ideally be a character that covers the maximum ascender and descender
heights in the current font; the latter uses an alignment at the baseline skip level
assuming it is reasonably fixed.

The standalone user command is \autodoc:command{\strut[method=<method>]},
where the method can be “character” (default) or “rule”. It returns the dimensions (for possible use
in Lua code). If needed, the \autodoc:parameter{show} option indicates whether the rule should inserted at this
point (defaults to true, again this is mostly intended at Lua code, where you could want to compute
the current strut dimensions without adding it to the text flow).

\end{document}]]
}
