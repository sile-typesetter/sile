local typesetMark = function (open, setback, scale, color, mark)
  SILE.settings:temporarily(function ()
    SILE.call("pullquote:mark-font")
    SILE.call("raise", { height = -(open and (scale+1) or scale) .. "ex" }, function ()
      SILE.settings:set("font.size", SILE.settings:get("font.size")*scale)
      SILE.call("color", { color = color }, function ()
        if open then
          SILE.typesetter:pushGlue({ width = -setback })
          SILE.call("rebox", { width = setback, height = 0 }, { mark })
        else
          SILE.typesetter:pushGlue(SILE.nodefactory.hfillglue())
          local hbox = SILE.call("hbox", {}, { mark })
          table.remove(SILE.typesetter.state.nodes) -- steal it back
          SILE.typesetter:pushGlue({ width = setback - hbox.width })
          SILE.call("rebox", { width = hbox.width, height = 0 }, { mark })
          SILE.typesetter:pushGlue({ width = -setback })
        end
      end)
    end)
  end)
end

local function init (class, _)

  class:loadPackage("color")
  class:loadPackage("raiselower")
  class:loadPackage("rebox")

end

local function registerCommands (class)

  class:registerCommand("pullquote:font", function (_, _)
  end, "The font chosen for the pullquote environment")

  class:registerCommand("pullquote:author-font", function (_, _)
    SILE.settings:set("font.style", "italic")
  end, "The font style with which to typeset the author attribution.")

  class:registerCommand("pullquote:mark-font", function (_, _)
    SILE.settings:set("font.family", "Libertinus Serif")
  end, "The font from which to pull the quotation marks.")

  class:registerCommand("pullquote", function (options, content)
    local author = options.author or nil
    local scale = options.scale or 3
    local color = options.color or "#999999"
    SILE.settings:temporarily(function ()
      SILE.call("pullquote:font")
      local setback = SU.cast("length", options.setback or "2em"):absolute()
      SILE.settings:set("document.rskip", SILE.nodefactory.glue(setback))
      SILE.settings:set("document.lskip", SILE.nodefactory.glue(setback))
      SILE.call("noindent")
      typesetMark(true, setback, scale, color, "“")
      SILE.call("indent")
      SILE.process(content)
      typesetMark(false, setback, scale, color, "”")
      if author then
        SILE.settings:temporarily(function ()
          SILE.typesetter:leaveHmode()
          SILE.call("pullquote:author-font")
          SILE.call("raggedleft", {}, function ()
            SILE.typesetter:typeset("— " .. author)
          end)
        end)
      else
        SILE.call("par")
      end
    end)
  end, "Typesets its contents in a formatted blockquote with decorative quotation\
        marks in the margins.")

end

return {
  init = init,
  registerCommands = registerCommands,
  documentation = [[\begin{document}

The \autodoc:environment{pullquote} environment formats longer quotations in an indented
blockquote block with decorative quotation marks in the margins.

Here is some text set in a pullquote environment:

\begin[author=Anatole France]{pullquote}%
An education is not how much you have committed to memory, or even how much you
know. It is being able to differentiate between what you do know and what you
do not know.
\end{pullquote}

Optional values are available for:

\begin{itemize}
\item{\autodoc:parameter{author} to add an attribution line,}
\item{\autodoc:parameter{setback} to set the bilateral margins around the block,}
\item{\autodoc:parameter{color} to change the color of the quote marks,}
\item{\autodoc:parameter{scale} to change the relative size of the quote marks.}
\end{itemize}

If you want to specify what font the pullquote environment should use, you
can redefine the \autodoc:command{\pullquote:font} command. By default it will be the same
as the surrounding document. The font style used for the attribution line
can likewise be set redefining \autodoc:command{\pullquote:author-font} and the font used for
the quote marks can be set redefining \autodoc:command{\pullquote:mark-font}.

\end{document}]] }
