SILE.require("packages/color")
SILE.require("packages/raiselower")
SILE.require("packages/rebox")

SILE.registerCommand("pullquote:font", function (options, content)
end, "The font chosen for the pullquote environment")

SILE.registerCommand("pullquote:author-font", function (options, content)
  SILE.settings.set("font.style", "italic")
end, "The font style with which to typeset the author attribution.")

SILE.registerCommand("pullquote:mark-font", function (options, content)
  SILE.settings.set("font.family", "Libertinus Serif")
end, "The font from which to pull the quotation marks.")

local typesetMark = function (open, setback, scale, color, mark)
  SILE.settings.temporarily(function ()
    SILE.call("pullquote:mark-font")
    local setwidth = SILE.length.new({ length = SILE.toPoints(setback) })
    SILE.typesetter:pushGlue({ width = open and 0-setwidth or setwidth })
    SILE.call("raise", { height = -(open and (scale+1) or scale) .. "ex" }, function ()
      SILE.settings.set("font.size", SILE.settings.get("font.size")*scale)
      SILE.call("color", { color = color }, function ()
        SILE.call("rebox", { width = 0, height = 0 }, { mark })
      end)
    end)
    SILE.typesetter:pushGlue({width = open and setwidth or 0-setwidth })
  end)
end

SILE.registerCommand("pullquote", function (options, content)
  local author = options.author or nil
  local setback = options.setback or "2em"
  local scale = options.scale or 3
  local color = options.color or "#999999"
  SILE.settings.temporarily(function ()
    SILE.settings.set("document.rskip", SILE.nodefactory.newGlue(setback))
    SILE.settings.set("document.lskip", SILE.nodefactory.newGlue(setback))
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
    SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
    SILE.call("pullquote:font")
    typesetMark(true, setback, scale, color, "“")
    SILE.process(content)
    SILE.typesetter:pushGlue(SILE.nodefactory.hfillGlue)
    typesetMark(false, setback, scale, color, "”")
    if author then
      SILE.settings.temporarily(function ()
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

return { documentation = [[\begin{document}

The \code{pullquote} command formats longer quotations in an indented
blockquote block with decorative quotation marks in the margins.

Here is some text set in a pullquote environment:

\begin[author=Anatole France]{pullquote}
An education is not how much you have committed to memory, or even how much you
know. It is being able to differentiate between what you do know and what you
do not know.
\end{pullquote}

Optional values are available for:

\listitem \code{author} to add an attribution line
\listitem \code{setback} to set the bilateral margins around the block
\listitem \code{color} to change the color of the quote marks
\listitem \code{scale} to change the relative size of the quote marks

If you want to specify what font the pullquote environment should use, you
can redefine the \code{pullquote:font} command. By default it will be the same
as the surrounding document. The font style used for the attribution line
can likewise be set using \code{pullquote:author-font} and the font used for
the quote marks can be set using \code{pullquote:mark-font}.

\end{document}]] }
