-- Initial capitals ("Drop Caps") for SILE
-- This implementation relies on the hangafter/hangindent feature of Knuth's line-breaking algorithm.
-- Usage:
--   \dropcaps[lines=N, family=Font Family, joined=true|false, letter=L]{Paragraph content}

SILE.registerCommand("dropcaps", function (options, content)
  local lines = SU.cast("integer", options.lines or 3)
  local joined = SU.boolean(options.joined, false)
  local letter = SU.required(options, "letter", "dropcaps")
  if string.len(letter) ~= 1 then SU.error("Parameter letter for dropcaps must have exactly one character.") end

  -- We want the drop cap to span over N lines, but what does it mean? Actually, N-1 baseline skips
  -- plus a little extra for the top text line.
  -- We arbitrarily choosed the height of an "i" in the current font, so to have something slightly
  -- greater (in theory) than an "x", but conceivably smaller than letters with ascenders.
  local bsHeight = SILE.length((lines - 1).."bs")
  local size = bsHeight:tonumber() + SILE.shaper:measureChar('i').height

  -- Now we need to pick a font size where the target letter takes that size but in height.
  -- So we temporarily set the font to 50pt, measure the character's height, and apply the ratio.
  local SZ = 50
  local m
  SILE.settings.temporarily(function ()
    SILE.settings.set("font.size", SZ)
    if options.family then SILE.settings.set("font.family", options.family) end
    m = SILE.shaper:measureChar(letter)
  end)
  local targetSize = SZ / m.height * size

  SILE.settings.temporarily(function ()
    -- We are are ready to typeset.
    -- Put the letter in a box, but remove it from the node queue
    local hbox = SILE.call("hbox", {}, function()
      SILE.call("noindent")
      SILE.call("font", { family = options.family, size = targetSize}, function ()
        SILE.typesetter:typeset(letter)
      end)
    end)
    table.remove(SILE.typesetter.state.nodes)

    -- Measure the width it takes
    local width = hbox.width:tonumber()

    -- Activate the hang parameters.
    -- With the jointed=true option, we want the initial line to be slightly closer to the
    -- drop cap than the subsequent indented lines.
    -- We arbitrarily choosed a space width.
    local joinOffset = joined and SILE.length("1spc") or SILE.length(0)
    SILE.settings.set("current.parindent", -joinOffset)
    SILE.settings.set("linebreak.hangAfter", -lines)
    SILE.settings.set("linebreak.hangIndent", width + joinOffset:tonumber())

    -- Now the paragraph are idented so as to leave enough space for the drop cap.
    -- We "trick" the typesetter with a zero-dimension box wrapping our original box.
    SILE.typesetter:pushHbox({
      width = 0,
      height = 0,
      depth = 0,
      value = hbox,
      outputYourself= function (self, typesetter, line)
        local saveX = typesetter.frame.state.cursorX
        local saveY = typesetter.frame.state.cursorY
        typesetter.frame.state.cursorX = saveX - width
        typesetter.frame.state.cursorY = saveY + bsHeight
        self.value:outputYourself(typesetter, line)
        typesetter.frame.state.cursorX = saveX
        typesetter.frame.state.cursorY = saveY
      end
    })

    -- And finally process the content and finish the pragraph
    SILE.process(content)
    SILE.typesetter:leaveHmode()
   end)
end, "Shows an 'initial capital' (also known as 'drop cap') at the start of the content paragraph.")

return { documentation = [[\begin{document}
The \code{dropcaps} package allows you to format paragraphs with an 'initial capital' (also commonly
referred as a 'drop' cap), that is, a large capital letter used as a decorative element at the beginning
of a paragraph.

It just provides the \code{\\dropcaps} command, which takes as options the number of lines the initial
should span over, the font family to use and the initial letter. Provide the rest of the text as
argument to the command, and you are done. Old-style typographers also have the possibility to
enable, at their convenience, the join option, for use when the initial belongs to the first word of
the sentence. In that case, the first line is closer to the initial than subsequent indented lines.
\end{document}]] }
