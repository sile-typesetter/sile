SILE.require("packages/color")
SILE.registerCommand("pullquote:font", function(options, content)
end, "The font chosen for the pullquote environment")
SILE.registerCommand("pullquote:author-font", function(options, content)
	SILE.settings.set("font.style", "italic")
end, "The font style with which to typeset the author attribution.")
SILE.registerCommand("pullquote:mark-font", function(options, content)
	SILE.settings.set("font.family", "Libertine Sans")
end, "The font from which to pull the quotation marks.")

local typesetMark = function (open, setback, scale, color, mark)
	SILE.typesetter:chuck()
	local saveX = SILE.typesetter.frame.state.cursorX;
	local saveY = SILE.typesetter.frame.state.cursorY;
	SILE.settings.temporarily(function()
		SILE.call("pullquote:mark-font")
		if open then
			SILE.typesetter.frame:moveX(- SILE.toPoints(setback))
			SILE.typesetter.frame:moveY(SILE.toPoints("1ex"))
		else
			SILE.typesetter.frame:moveX(SILE.toPoints(setback))
			SILE.typesetter.frame:moveY(- SILE.toPoints(scale -1 .. "ex"))
		end
		SILE.settings.set("font.size", SILE.settings.get("font.size") * scale)
		SILE.call("color", {color = color}, function ()
			SILE.call(open and "raggedright" or "raggedleft", {}, function ()
				SILE.typesetter:typeset(mark)
			end)
		end)
	end)
	SILE.typesetter:chuck()
	SILE.typesetter.frame.state.cursorX = saveX
	SILE.typesetter.frame.state.cursorY = saveY
end

SILE.registerCommand("pullquote", function(options, content)
	local author = options.author or nil
	local setback = options.setback or "2em"
	local scale = options.scale or 3
	local color = options.color or "#999999"
	SILE.settings.temporarily(function()
		SILE.settings.set("document.rskip", SILE.nodefactory.newGlue(setback))
		SILE.settings.set("document.lskip", SILE.nodefactory.newGlue(setback))
		SILE.settings.set("current.parindent", SILE.nodefactory.zeroGlue)
		SILE.call("pullquote:font")
		typesetMark(true, setback, scale, color, "“")
		SILE.process(content)
		typesetMark(false, setback, scale, color, "”")
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
\listitem \code{color} to change the color of the quote marks
\listitem \code{scale} to change the size of the marks relative to the base font

If you want to specify what font the pullquote environment should use, you
can redefine the \code{pullquote:font} command. By default it will be the same
as the surrounding document. The font style used for the attribution line
can likewise be set using \code{pullquote:author-font} and the font used for
the quote marks can be set using \code{pullquote:mark-font}.]]
