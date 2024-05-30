local base = require("packages.base")

local package = pl.class(base)
package._name = "pullquote"

local typesetMark = function (open, setback, scale, color, mark)
   SILE.settings:temporarily(function ()
      SILE.call("pullquote:mark-font")
      SILE.call("raise", { height = -(open and (scale + 1) or scale) .. "ex" }, function ()
         SILE.settings:set("font.size", SILE.settings:get("font.size") * scale)
         SILE.call("color", { color = color }, function ()
            if open then
               SILE.typesetter:pushGlue({ width = -setback })
               SILE.call("rebox", { width = setback, height = 0 }, { mark })
            else
               SILE.typesetter:pushGlue(SILE.nodefactory.hfillglue())
               local hbox = SILE.typesetter:makeHbox({ mark }) -- for measuring
               SILE.typesetter:pushGlue({ width = setback - hbox.width })
               SILE.call("rebox", { width = hbox.width, height = 0 }, { mark })
               SILE.typesetter:pushGlue({ width = -setback })
            end
         end)
      end)
   end)
end

function package:_init ()
   base._init(self)
   self:loadPackage("color")
   self:loadPackage("raiselower")
   self:loadPackage("rebox")
end

function package:registerCommands ()
   self:registerCommand("pullquote:font", function (_, _) end, "The font chosen for the pullquote environment")

   self:registerCommand("pullquote:author-font", function (_, _)
      SILE.settings:set("font.style", "italic")
   end, "The font style with which to typeset the author attribution.")

   self:registerCommand("pullquote:mark-font", function (_, _)
      SILE.settings:set("font.family", "Libertinus Serif")
   end, "The font from which to pull the quotation marks.")

   self:registerCommand(
      "pullquote",
      function (options, content)
         SILE.typesetter:leaveHmode()
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
      end,
      "Typesets its contents in a formatted blockquote with decorative quotation\
        marks in the margins."
   )
end

package.documentation = [[
\begin{document}
The \autodoc:package{pullquote} package formats longer quotations in an indented blockquote block with decorative quotation marks in the margins.
Here is some text set in a \autodoc:environment{pullquote} environment:

\begin[author=Anatole France]{pullquote}%
An education is not how much you have committed to memory, or even how much you know.
It is being able to differentiate between what you do know and what you do not know.
\end{pullquote}

Optional values are available for:

\begin{itemize}
\item{\autodoc:parameter{author} to add an attribution line}
\item{\autodoc:parameter{setback} to set the bilateral margins around the block}
\item{\autodoc:parameter{color} to change the color of the quote marks}
\item{\autodoc:parameter{scale} to change the relative size of the quote marks}
\end{itemize}

If you want to specify what font the \autodoc:environment{pullquote} environment should use, you can redefine the \autodoc:command{\pullquote:font} command.
By default it will be the same as the surrounding document.
The font style used for the attribution line can likewise be set redefining \autodoc:command{\pullquote:author-font}, and the font used for the quote marks can be set redefining \autodoc:command{\pullquote:mark-font}.
\end{document}
]]

return package
