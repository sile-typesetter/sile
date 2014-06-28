
    SILE.registerCommand("font", function(options, content)
      local prevState = SILE.documentState;
      if (content[1]) then
        SILE.documentState = std.tree.clone( prevState )
      end
      if (options.family)  then SILE.documentState.fontFamily = options.family end
      if (options.size)  then SILE.documentState.fontSize = options.size end
      if (options.weight)  then SILE.documentState.fontWeight = options.weight end
      if (options.rise)  then SILE.documentState.fontRise = options.rise end
      if (options.style)  then SILE.documentState.fontStyle = options.style end
      if (options.variant)  then SILE.documentState.fontVariant = options.variant end
      if (options.underline)  then SILE.documentState.fontUnderline = options.underline end
      if (options.language)  then SILE.documentState.language = options.language end
      if (options.color)  then SILE.documentState.color = SILE.colorparser(options.color) end
      if (content[1]) then 
        SILE.process(content)
        SILE.documentState = prevState
      end
    end)

SILE.documentState.fontFamily = "Gentium";
SILE.documentState.fontSize = 10;
SILE.documentState.fontWeight = 200;
SILE.documentState.fontStyle = "normal";
SILE.documentState.language = "en";
SILE.documentState.color = "black";

SILE.font = {loadDefaults = function(options)
  if not options.font then options.font = SILE.documentState.fontFamily end
  if not options.size then options.size = SILE.documentState.fontSize end
  if not options.rise then options.rise = SILE.documentState.fontRise end
  if not options.weight then options.weight = SILE.documentState.fontWeight end
  if not options.style then options.style = SILE.documentState.fontStyle end
  if not options.variant then options.variant = SILE.documentState.fontVariant end
  if not options.language then options.language = SILE.documentState.language end
  if not options.underline then options.underline = SILE.documentState.fontUnderline end
  if not options.color then options.color = SILE.documentState.color end

  return options
end
}