SILE.inputs.TeXlike.passthroughTags.lilypond = true

SILE.registerCommand("lilypond", function(options, content)
  if options.src then
    local src = SILE.resolveFile(options.src)
  end
end)
