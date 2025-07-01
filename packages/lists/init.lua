local base = require("packages.base")

local package = pl.class(base)
package._name = "lists"

--
-- Enumerations and bullet lists for SILE
-- Donated to the SILE typesetter - 2021-2022, Didier Willis
-- This a trimmed-down version of the feature-richer but more experimental
-- "enumitem" package (https://github.com/Omikhleia/omikhleia-sile-packages).
-- License: MIT
--
-- NOTE: Though not described explicitly in the documentation, the package supports
-- two nesting techniques:
-- The "simple" or compact one:
--    \begin{itemize}
--       \item{L1.1}
--       \begin{itemize}
--          \item{L2.1}
--       \end{itemize}
--    \end{itemize}
-- The "alternative" one, which consists in having the nested elements in an item:
--    \begin{itemize}
--       \item{L1.1
--         \begin{itemize}
--            \item{L2.1}
--         \end{itemize}}
--    \end{itemize}
-- The latter might be less readable, but is of course more powerful, as other
-- contents can be added to the item, as in:
--    \begin{itemize}
--       \item{L1.1
--         \begin{itemize}
--            \item{L2.1}
--         \end{itemize}%
--         This is still in L1.1}
--    \end{itemize}
-- But personally, for simple lists, I prefer the first "more readable" one.
-- Lists from Markdown, obviously, due to their structure, would need the
-- second technique.
--

local styles = {
   enumerate = {
      { display = "arabic", after = "." },
      { display = "roman", after = "." },
      { display = "alpha", after = "." },
      { display = "arabic", after = ")" },
      { display = "roman", after = ")" },
      { display = "alpha", after = ")" },
   },
   itemize = {
      { bullet = "•" }, -- black bullet
      { bullet = "◦" }, -- circle bullet
      { bullet = "–" }, -- en-dash
      { bullet = "•" }, -- black bullet
      { bullet = "◦" }, -- circle bullet
      { bullet = "–" }, -- en-dash
   },
}

local enforceListType = function (cmd)
   if cmd ~= "enumerate" and cmd ~= "itemize" and cmd ~= "BulletedList" and cmd ~= "OrderedList" then
      SU.error("Only items or lists are allowed as content in lists, found '" .. cmd .. "'")
   end
end

local lastListSpacing

local function getNestedDepth ()
   local itemize_level = SILE.settings:get("lists.current.itemize.depth")
   local enumerate_level = SILE.settings:get("lists.current.enumerate.depth")
   return itemize_level + enumerate_level
end

-- Push some list separation space provided we don't already have some
local function pushListSpacing ()
   if #SILE.typesetter.state.outputQueue ~= lastListSpacing then
      SILE.typesetter:pushVglue(SILE.settings:get("lists.parskip"))
      lastListSpacing = #SILE.typesetter.state.outputQueue
   end
end

-- Remove the last list separation space so it doesn't interfere with parskip
local function popListSpacing ()
   if lastListSpacing then
      local node = SILE.typesetter.state.outputQueue[lastListSpacing]
      if not node.is_vglue then
         SU.error("Attempted to pop something other than vertical spacing", true)
      end
      table.remove(SILE.typesetter.state.outputQueue, lastListSpacing)
   end
end

local function maybeAddListSpacing (islist, entering, counter)
   -- Observed nesting depth for lists is zero based and hence N-1 vs. items in those lists
   local depth = getNestedDepth() + (islist and 1 or 0)
   local isitem = not islist
   local leaving = not entering
   SILE.typesetter:leaveHmode()
   -- All list items except the first one in the outermost list get leading space
   if entering and isitem and (counter ~= 1 or depth >= 2) then
      pushListSpacing()
   end
   -- All lists get trailing space (to cover nesting)
   if leaving and islist then
      pushListSpacing()
      if depth == 1 then
         popListSpacing()
      end
   end
end

function package:doItem (options, content)
   local enumStyle = content._lists_.style
   local counter = content._lists_.counter
   local indent = content._lists_.indent

   maybeAddListSpacing(false, true, counter)

   local mark = SILE.typesetter:makeHbox(function ()
      if enumStyle.display then
         if enumStyle.before then
            SILE.typesetter:typeset(enumStyle.before)
         end
         SILE.typesetter:typeset(self.class.packages.counters:formatCounter({
            value = counter,
            display = enumStyle.display,
         }))
         if enumStyle.after then
            SILE.typesetter:typeset(enumStyle.after)
         end
      else
         local bullet = options.bullet or enumStyle.bullet
         SILE.typesetter:typeset(bullet)
      end
   end)

   local stepback
   if enumStyle.display then
      -- The positioning is quite tentative... LaTeX would right justify the
      -- number (at least for roman numerals), i.e.
      --   i. Text
      --  ii. Text
      -- iii. Text.
      -- Other Office software do not do that...
      local labelIndent = SILE.settings:get("lists.enumerate.labelindent"):absolute()
      stepback = indent - labelIndent
   else
      -- Center bullets in the indentation space
      stepback = indent / 2 + mark.width / 2
   end

   SILE.call("kern", { width = -stepback })
   -- reinsert the mark with modified length
   -- using \rebox caused an issue sometimes, not sure why, with the bullets
   -- appearing twice in output... but we can avoid it:
   -- reboxing an hbox was dumb anyway. We just need to fix its width before
   -- reinserting it in the text flow.
   mark.width = SILE.types.length(stepback)
   SILE.typesetter:pushHbox(mark)
   SILE.process(content)

   -- In the event the list ends but paragraph continues we don't want a paragraph
   -- indent applied just because we yielded to the typesetter in vmode.
   SILE.settings:set("current.parindent", SILE.types.node.glue())
   maybeAddListSpacing(false, false, counter)
end

function package:doNestedList (listType, options, content)
   -- depth
   local depth = SILE.settings:get("lists.current." .. listType .. ".depth") + 1

   -- styling
   local enumStyle = styles[listType][(depth - 1) % 6 + 1]
   -- options may override the default styling
   enumStyle = pl.tablex.copy(enumStyle) -- shallow copy for possible overrides
   if enumStyle.display then
      if options.before or options.after then
         -- for before/after, don't mix default style and options
         enumStyle.before = options.before or ""
         enumStyle.after = options.after or ""
      end
      if options.display then
         enumStyle.display = options.display
      end
   else
      enumStyle.bullet = options.bullet or enumStyle.bullet
   end

   -- indent
   local baseIndent = (depth == 1) and SILE.settings:get("document.parindent").width:absolute()
      or SILE.types.measurement("0pt")
   local listIndent = SILE.settings:get("lists." .. listType .. ".leftmargin"):absolute()

   maybeAddListSpacing(true, true, nil)
   SILE.settings:temporarily(function ()
      SILE.settings:set("lists.current." .. listType .. ".depth", depth)
      SILE.settings:set("current.parindent", SILE.types.node.glue())
      SILE.settings:set("document.parindent", SILE.types.node.glue())
      local lskip = SILE.settings:get("document.lskip") or SILE.types.node.glue()
      SILE.settings:set("document.lskip", SILE.types.node.glue(lskip.width + (baseIndent + listIndent)))

      local counter = options.start and (SU.cast("integer", options.start) - 1) or 0
      for i = 1, #content do
         if type(content[i]) == "table" and #content[i] > 0 then
            if content[i].command == "item" or content[i].command == "ListItem" then
               counter = counter + 1
               -- Enrich the node with internal properties
               content[i]._lists_ = {
                  style = enumStyle,
                  counter = counter,
                  indent = listIndent,
               }
            else
               enforceListType(content[i].command)
            end
            SILE.process({ content[i] })
         -- Whitespace left around comment nodes is fine too
         elseif type(content[i]) == "table" and #content[i] == 0 then
            -- ignore whitespace leaking in from in front of indented comments
            assert(true)
         elseif type(content[i]) == "string" then
            -- All text nodes are ignored in structure tags, but just warn
            -- if there do not just consist in spaces.
            local text = pl.stringx.strip(content[i])
            if text ~= "" then
               SU.warn("Ignored standalone text (" .. text .. ")")
            end
         else
            SU.error("List structure error")
         end
      end
   end)
   maybeAddListSpacing(true, false, nil)
end

function package:_init ()
   base._init(self)
   self:loadPackage("counters")
end

function package:declareSettings ()
   SILE.settings:declare({
      parameter = "lists.current.enumerate.depth",
      type = "integer",
      default = 0,
      help = "Current enumerate depth (nesting) - internal",
   })

   SILE.settings:declare({
      parameter = "lists.current.itemize.depth",
      type = "integer",
      default = 0,
      help = "Current itemize depth (nesting) - internal",
   })

   SILE.settings:declare({
      parameter = "lists.enumerate.leftmargin",
      type = "measurement",
      default = SILE.types.measurement("2em"),
      help = "Left margin (indentation) for enumerations",
   })

   SILE.settings:declare({
      parameter = "lists.enumerate.labelindent",
      type = "measurement",
      default = SILE.types.measurement("0.5em"),
      help = "Label indentation for enumerations",
   })

   SILE.settings:declare({
      parameter = "lists.itemize.leftmargin",
      type = "measurement",
      default = SILE.types.measurement("1.5em"),
      help = "Left margin (indentation) for bullet lists (itemize)",
   })

   SILE.settings:declare({
      parameter = "lists.parskip",
      type = "vglue",
      default = SILE.types.node.vglue("0pt plus 1pt"),
      help = "Leading between items in a list",
   })
end

function package:registerCommands ()
   self:registerCommand("enumerate", function (options, content)
      self:doNestedList("enumerate", options, content)
   end)

   self:registerCommand("itemize", function (options, content)
      self:doNestedList("itemize", options, content)
   end)

   self:registerCommand("item", function (options, content)
      if not content._lists_ then
         SU.error("The item command shall not be called outside a list")
      end
      self:doItem(options, content)
   end)
end

package.documentation = [[
\begin{document}
\font:add-fallback[family=Symbola]% HACK Gentium Book (SILE default font) lacks the circle bullet :(
The \autodoc:package{lists} package provides enumerated and itemized (also known as \em{bulleted lists}) which can be nested together.

\smallskip
\noindent
\em{Itemized lists}
\novbreak

\indent
The \autodoc:environment{itemize} environment initiates a itemized list.
Each item, unsurprisingly, is wrapped in an \autodoc:command{\item} command.

The environment, as a structure or data model, can only contain \code{item} elements or other lists.
Any other element causes an error to be reported, and any text content is ignored with a warning.

\begin{itemize}
    \item{Lorem}
    \begin{itemize}
        \item{Ipsum}
        \begin{itemize}
            \item{Dolor}
        \end{itemize}
    \end{itemize}
\end{itemize}

On each level, the indentation is defined by the \autodoc:setting{lists.itemize.leftmargin} setting (defaults to \code{1.5em}) and the bullet is centered in that margin.
Note that if your document has a paragraph indent enabled at this point, it is also added to the first list level.

The package has a default bullet style for each level, but you can explicitly select a bullet symbol of your choice to be used by specifying the options \autodoc:parameter{bullet=<character>} on the \autodoc:environment{itemize} environment.
You can also force a specific bullet character to be used on a specific item with \autodoc:command{\item[bullet=<character>]}.

\smallskip
\noindent
\em{Enumerated lists}
\novbreak

\indent
The \autodoc:environment{enumerate} environment initiates an enumeration.
Each item shall, again, be wrapped in an \autodoc:command{\item} command.
This environment too is regarded as a structure, so the same rules as above apply.

The enumeration starts at one, unless you specify the \autodoc:parameter{start=<integer>} option (a numeric value, regardless of the display format).

\begin{enumerate}
    \item{Lorem}
    \begin{enumerate}
        \item{Ipsum}
        \begin{enumerate}
            \item{Dolor}
        \end{enumerate}
    \end{enumerate}
\end{enumerate}

On each level, the indentation is defined by the \autodoc:setting{lists.enumerate.leftmargin} setting (defaults to \code{2em}).
Note, again, that if your document has a paragraph indent enabled at this point, it is also added to the first list level.

% And… ah, at least something less repetitive than a raw list of features.
% \em{Quite obviously}, we cannot center the label.
% Roman numbers, folks, if any reason is required.

The \autodoc:setting{lists.enumerate.labelindent} setting specifies the distance between the label and the previous indentation level (defaults to \code{0.5em}).
Tune these settings at your convenience depending on your styles.
If there is a more general solution to this subtle issue, we accept patches.%
\footnote{TeX typesets the enumeration label ragged left. Most word processing software do not.}

The package has a default number style for each level, but you can explicitly select the display type (format) of the values (as \code{arabic}, \code{roman}, or \code{alpha}), and the text prepended or appended to them, by specifying the options \autodoc:parameter{display=<display>}, \autodoc:parameter{before=<string>}, and \autodoc:parameter{after=<string>} to the \autodoc:environment{enumerate} environment.

\smallskip
\noindent
\em{Nesting}
\novbreak

\indent
Both environments can be nested.
The way they do is best illustrated by an example.

\begin{enumerate}
    \item{Lorem}
    \begin{enumerate}
        \item{Ipsum}
        \begin{itemize}
            \item{Dolor}
            \begin{enumerate}
                \item{Sit amet}
                \begin{itemize}
                    \item{Consectetur}
                \end{itemize}
            \end{enumerate}
        \end{itemize}
    \end{enumerate}
\end{enumerate}

\smallskip
\noindent
\em{Vertical spaces}
\novbreak

\indent
The package outputs lists starting after a line break, but it does not enforce a paragraph break before or after the list.
If you want the usual value of \autodoc:setting{document.parskip} to apply before and/or after your list leave a blank line in your source document separating paragraphs as usual.
Between list items, however, the paragraph skip is switched to the value of the \autodoc:setting{lists.parskip} setting.

\smallskip
\noindent
\em{Other considerations}
\novbreak

\indent
Do not expect these fragile lists to work in any way in centered or ragged-right environments, or with fancy line-breaking features such as hanged or shaped paragraphs.
Please be a good typographer. Also, these lists have not yet been tried in right-to-left or vertical writing direction.

\font:remove-fallback
\end{document}
]]

return package
