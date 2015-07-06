SILE.require("packages/frametricks")
SILE.registerCommand("pullquote:font", function(options, content)
end, "The font chosen for the pullquote environment")
SILE.registerCommand("pullquote:author-font", function(options, content)
	SILE.settings.set("font.style", "italic")
end, "The font style with which to typeset the author attribution.")

SILE.registerCommand("pullquote", function(options, content)
	local author = options.author or nil
	local setback = options.setback or "2em"
	SILE.settings.temporarily(function()
		SILE.settings.set("document.rskip", SILE.nodefactory.newGlue(setback))
		SILE.settings.set("document.lskip", SILE.nodefactory.newGlue(setback))
		SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
		SILE.call("pullquote:font")
		SILE.typesetter:typeset("“")
		SILE.process(content)
		SILE.typesetter:typeset("”")
		if author then
			SILE.settings.temporarily(function()
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
end, "Typesets its contents in a formatted blockquote.")

return [[\begin{document}

The \code{pullquote} formats longer quotations with a pretty layout.

Here is some text set in a pullquote environment:

\begin{pullquote}
The history of every nation revolves around Jesus of Nazareth. This is really
an astonishing claim: to say everything depends on a guy who lived two thousand
years ago, ate some fish, and got himself killed. And then ate some more fish.
\end{pullquote}

Optional values are available for:

\listitem \code{author} to add an attribution line
\listitem \code{setback} to add bilateral margins around the block

If you want to specify what font the pullquote environment should use, you
can redefine the \code{pullquote:font} command. By default it will be the same
as the surrounding document. The font style used for the attribution line
can likewise be set using \code{pullquote:author-font}.]]
