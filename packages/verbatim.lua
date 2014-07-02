
SILE.registerCommand("verbatim", function(options, content)
  local t = SILE.typesetter;
  t:pushVglue({ height = SILE.length.new({ length = 15 }) })
  t:leaveHmode()
  SILE.typesetter = SILE.typesetter {}
  -- Keep lines
  SILE.typesetter.parSepPattern = "\n"

  -- Set ragged right
  SILE.settings.temporarily(function()
    SILE.settings.set("document.rskip", SILE.nodefactory.newGlue("0 plus 10000pt"))
    SILE.settings.set("document.parindent", SILE.nodefactory.newGlue("0"))
    SILE.settings.set("document.baselineskip", SILE.nodefactory.newVglue("0"))
    SILE.settings.set("document.lineskip", SILE.nodefactory.newVglue("2pt"))
    SILE.settings.set("document.spaceskip", SILE.length.parse("1en"))
    SILE.settings.set("font.family", "Monaco") -- XXX
    SILE.settings.set("font.size", SILE.settings.get("font.size") - 3)
    SILE.settings.set("document.language", "xx")
    SILE.process(content)
  end)

  t:pushVglue({ height = SILE.length.new({ length = 15 }) })
  SILE.typesetter = t
end)