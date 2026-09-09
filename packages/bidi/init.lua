local base = require("packages.base")

local package = pl.class(base)
package._name = "bidi"

local bidi = require("core.bidi")

function package:reorder (n, typesetter)
   n.nodes = bidi.reorder(n.nodes, typesetter.frame:writingDirection())
end

function package:bidiEnableTypesetter (typesetter)
   SU.warn("BiDi is no longer something that can be turned off or on")
end

function package:bidiDisableTypesetter (typesetter)
   SU.warn("BiDi is no longer something that can be turned off or on")
end

function package:_init ()
   base._init(self)
   self:deprecatedExport("reorder", self.reorder)
   self:deprecatedExport("bidiEnableTypesetter", self.bidiEnableTypesetter)
   self:deprecatedExport("bidiDisableTypesetter", self.bidiDisableTypesetter)
end

function package:registerCommands ()
   self:registerCommand("thisframeLTR", function (_, _)
      local direction = "LTR"
      SILE.typesetter.frame.direction = direction
      SILE.settings:set("font.direction", direction)
      SILE.typesetter:leaveHmode()
      SILE.typesetter.frame:newLine()
   end)

   self:registerCommand("thisframedirection", function (options, _)
      local direction = SU.required(options, "direction", "frame direction")
      SILE.typesetter.frame.direction = direction
      SILE.settings:set("font.direction", direction)
      SILE.typesetter:leaveHmode()
      SILE.typesetter.frame:init()
   end)

   self:registerCommand("thisframeRTL", function (_, _)
      local direction = "RTL"
      SILE.typesetter.frame.direction = direction
      SILE.settings:set("font.direction", direction)
      SILE.typesetter:leaveHmode()
      SILE.typesetter.frame:newLine()
   end)

   self:registerCommand("bidi-on", function (_, _)
      self:bidiEnableTypesetter(SILE.typesetter)
   end)

   self:registerCommand("bidi-off", function (_, _)
      self:bidiDisableTypesetter(SILE.typesetter)
   end)
end

package.documentation = [[
\begin{document}
Scripts like the Latin alphabet you are currently reading are normally written left to right (LTR); however, some scripts, such as Arabic and Hebrew, are written right to left (RTL).
The \autodoc:package{bidi} package, which is loaded by default, provides SILE with the ability to correctly typeset right-to-left text and also documents which mix right-to-left and left-to-right typesetting.
Because it is loaded by default, you can use both LTR and RTL text within a paragraph and SILE will ensure that the output characters appear in the correct order.

The \autodoc:package{bidi} package provides two commands, \autodoc:command{\thisframeLTR} and \autodoc:command{\thisframeRTL}, which set the default text direction for the current frame.
If you tell SILE that a frame is RTL, the text will start in the right margin and proceed leftward.
It also provides the commands \autodoc:command{\bidi-off} and \autodoc:command{\bidi-on}, which allow you to trade off bidirectional support for a dubious increase in speed.
\end{document}
]]

return package
