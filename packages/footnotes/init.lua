local base = require("packages.base")

local package = pl.class(base)
package._name = "footnotes"

function package:_init (options)
   base._init(self)
   self:loadPackage("counters")
   self:loadPackage("raiselower")
   self:loadPackage("insertions")
   if not SILE.scratch.counters.footnotes then
      SILE.scratch.counters.footnote = { value = 1, display = "arabic" }
   end
   options = options or {}
   self.class:initInsertionClass("footnote", {
      insertInto = options.insertInto or "footnotes",
      stealFrom = options.stealFrom or { "content" },
      maxHeight = SILE.types.length("75%ph"),
      topBox = SILE.types.node.vglue("2ex"),
      interInsertionSkip = SILE.types.length("1ex"),
   })
end

function package:registerCommands ()
   self.commands:register("footnotemark", function (_, _)
      SILE.call("raise", { height = "0.7ex" }, function ()
         SILE.call("font", { size = "1.5ex" }, function ()
            SILE.typesetter:typeset(self.class.packages.counters:formatCounter(SILE.scratch.counters.footnote))
         end)
      end)
   end)

   self.commands:register("footnote:separator", function (_, content)
      self.settings:pushState()
      local material = SILE.call("vbox", {}, content)
      SILE.scratch.insertions.classes.footnote.topBox = material
      self.settings:popState()
   end)

   self.commands:register("footnote:options", function (options, _)
      if options["maxHeight"] then
         SILE.scratch.insertions.classes.footnote.maxHeight = SILE.types.length(options["maxHeight"])
      end
      if options["interInsertionSkip"] then
         SILE.scratch.insertions.classes.footnote.interInsertionSkip = SILE.types.length(options["interInsertionSkip"])
      end
   end)

   self.commands:register("footnote", function (options, content)
      SILE.call("footnotemark")
      local opts = SILE.scratch.insertions.classes.footnote or {}
      local frame = opts.insertInto and SILE.getFrame(opts.insertInto.frame)
      local oldGetTargetLength = SILE.typesetter.getTargetLength
      local oldFrame = SILE.typesetter.frame
      SILE.typesetter.getTargetLength = function ()
         return SILE.types.length(0xFFFFFF)
      end
      self.settings:pushState()
      -- Restore the settings to the top of the queue, which should be the document #986
      self.settings:toplevelState()
      SILE.typesetter:initFrame(frame)
      -- Reset settings the document may have but should not be applied to footnotes
      -- See also same resets in folio package
      for _, v in ipairs({
         "current.hangAfter",
         "current.hangIndent",
         "linebreak.hangAfter",
         "linebreak.hangIndent",
      }) do
         self.settings:pull(v):reset()
      end
      -- Apply the font before boxing, so relative baselineskip applies #1027
      local material
      SILE.call("footnote:font", {}, function ()
         material = SILE.call("vbox", {}, function ()
            SILE.call("footnote:atstart", options)
            SILE.call("footnote:counter", options)
            SILE.process(content)
         end)
      end)
      self.settings:popState()
      SILE.typesetter.getTargetLength = oldGetTargetLength
      SILE.typesetter.frame = oldFrame
      self.class:insert("footnote", material)
      SILE.scratch.counters.footnote.value = SILE.scratch.counters.footnote.value + 1
   end)

   self.commands:register("footnote:font", function (_, content)
      -- The footnote frame has is settings reset to the toplevel state, so if one does
      -- something relative (as below), it is expected to be the main value from the
      -- document.
      SILE.call("font", { size = self.settings:get("font.size") * 0.9 }, function ()
         SILE.process(content)
      end)
   end)

   self.commands:register("footnote:atstart", function (_, _) end)

   self.commands:register("footnote:counter", function (_, _)
      SILE.call("noindent")
      SILE.typesetter:typeset(self.class.packages.counters:formatCounter(SILE.scratch.counters.footnote) .. ".")
      SILE.call("qquad")
   end)
end

package.documentation = [[
\begin{document}
The \autodoc:package{footnotes} package allows you to add footnotes to text with the \autodoc:command{\footnote} command.
Other commands provided by the package, not described here, take care of formatting the footnotes.

Usually, a document class is responsible for automatically loading this package.
Minimally, upon initialization, it needs a frame identifier for the the footnotes, and one or more frame(s) which will be reduced as the footnotes take place.
By default, it uses, respectively, the \code{footnotes} and \code{content} frames, which are assumed to be present in the default standard layout.

For the record, it internally relies on the \autodoc:package{insertions} package and tells it which frame should receive the footnotes that are typeset.
\end{document}
]]

return package
