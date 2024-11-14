--
-- Documentation tooling for package designers.
--

local base = require("packages.base")

local package = pl.class(base)
package._name = "autodoc"

local theme = {
   command = "#1d4851", -- oil blue
   parameter = "#3f5218", -- some sort of dark green
   setting = "#42280e", -- some kind of dark brown
   bracketed = "#656565", -- some grey
   package = "#172557", -- saturated space blue
   note = "#525257", -- some asphalt grey hue
   class = "#6a2c54", -- some dark shaded magenta
   codeblock = "#303040", -- dark grey with a hint of blue
}

local colorWrapper = function (ctype, content)
   local color = SILE.scratch.autodoc.theme[ctype]
   if color and SILE.settings:get("autodoc.highlighting") and SILE.Commands["color"] then
      SILE.call("color", { color = color }, content)
   else
      SILE.process(content)
   end
end

local function optionSorter (o1, o2)
   -- options are in an associative table and Lua doesn't guarantee a fixed order.
   -- To ensure we get a consistent and stable output, we make with some wild guesses here
   -- (Quick'n dirty, could be improved!), and rely on alphabetical order otherwise.
   if o1 == "src" then
      return true
   end
   if o2 == "src" then
      return false
   end
   if o1 == "name" then
      return true
   end
   if o2 == "name" then
      return false
   end
   return o1 < o2
end

local function typesetAST (options, content)
   if not content then
      return
   end
   local seenCommandWithoutArg = false
   for i = 1, #content do
      local ast = content[i]
      if type(ast) == "string" then
         if seenCommandWithoutArg and ast:sub(1, 1) ~= " " and ast:sub(1, 1) ~= "{" then
            -- Touchy:
            -- There might have been a space or a {} here in the original code. The AST does
            -- not remember it, we only know we have to separate somehow the string from
            -- the previous command...
            SILE.typesetter:typeset(" ")
            seenCommandWithoutArg = false
         end
         if ast:sub(1, 1) == "<" and ast:sub(-1) == ">" then
            SILE.call("autodoc:internal:bracketed", {}, { ast:sub(2, -2) })
         else
            SILE.typesetter:typeset(ast)
         end
      elseif ast.command then
         local cmd = SILE.Commands[ast.command]
         if not cmd and SU.boolean(options.check, true) then
            SU.error("Unexpected command '" .. ast.command .. "'")
         end
         SILE.typesetter:typeset("\\")
         SILE.call("autodoc:code:style", { type = "command" }, { ast.command })
         local sortedOpts = {}
         for k, _ in pairs(ast.options) do
            table.insert(sortedOpts, k)
         end
         table.sort(sortedOpts, optionSorter)
         if #sortedOpts > 0 then
            SILE.typesetter:typeset("[")
            for iOpt, option in ipairs(sortedOpts) do
               SILE.call("autodoc:code:style", { type = "parameter" }, { option })
               SILE.typesetter:typeset("=")
               SILE.call("penalty", { penalty = 100 }) -- Quite decent to break here if need be.
               SILE.call("autodoc:value", {}, { ast.options[option] })
               if iOpt == #sortedOpts then
                  SILE.typesetter:typeset("]")
               else
                  SILE.typesetter:typeset(", ")
               end
            end
         end
         if #ast >= 1 then
            SILE.call("penalty", { penalty = 200 }) -- Less than optimal break.
            SILE.typesetter:typeset("{")
            typesetAST(options, ast)
            SILE.typesetter:typeset("}")
         else
            seenCommandWithoutArg = true
         end
      elseif not ast.command and not ast.id then
         -- Mere list of nodes
         typesetAST(options, ast)
      else
         SU.error("Unrecognized AST element, type " .. type(ast))
      end
   end
end

function package:_init (options)
   base._init(self)
   self:loadPackage("inputfilter")
   self:loadPackage("rules")
   self:loadPackage("raiselower")
   self:loadPackage("verbatim")
   if options then
      pl.tablex.update(theme, options)
   end
   if not SILE.scratch.autodoc then
      SILE.scratch.autodoc = {
         theme = theme,
      }
   end
end

function package.declareSettings (_)
   SILE.settings:declare({
      parameter = "autodoc.highlighting",
      default = false,
      type = "boolean",
      help = "Whether audodoc enables syntax highlighting",
   })
end

function package:registerRawHandlers ()
   self:registerRawHandler("autodoc:codeblock", function (options, content)
      SILE.call("autodoc:codeblock", options, { content[1] }) -- Still issues with SU.ast.contentToString() witb raw content
   end)
end

function package:registerCommands ()
   -- Documenting a setting with good line-breaks
   local settingFilter = function (node, content)
      if type(node) == "table" then
         return node
      end
      local result = {}
      for token in SU.gtoke(node, "[%.]") do
         if token.string then
            result[#result + 1] = token.string
         else
            result[#result + 1] = token.separator
            result[#result + 1] = self.class.packages.inputfilter:createCommand(
               content.pos,
               content.col,
               content.lno,
               "penalty",
               { penalty = 100 }
            )
         end
      end
      return result
   end

   self:registerCommand("package-documentation", function (_, content)
      local packname = content[1]
      SU.debug("autodoc", packname)
      local pkg = require("packages." .. packname)
      if type(pkg) ~= "table" or not pkg.documentation then
         SU.error("Undocumented package " .. packname)
      end
      if type(pkg.registerCommands) == "function" then
         -- faking an uninstantiated package
         pkg.class = self.class
         pkg.registerCommands(pkg)
      end
      SILE.processString(pkg.documentation)
   end)

   self:registerCommand("autodoc:package:style", function (_, content)
      SILE.call("font", { weight = 700 }, function ()
         colorWrapper("package", content)
      end)
   end)

   self:registerCommand("autodoc:class:style", function (_, content)
      SILE.call("font", { weight = 700 }, function ()
         colorWrapper("class", content)
      end)
   end)

   self:registerCommand("autodoc:code:style", function (options, content)
      -- options.type is used to distinguish the type of code element and style
      -- it accordingly: "ast", "setting", "environment" shall select the font
      -- (by default, using \code) and color, the other (lower-level in an AST)
      -- shall select only the color.
      if options.type == "ast" then
         SILE.call("code", {}, content)
      elseif options.type == "setting" then
         SILE.call("code", {}, function ()
            colorWrapper(options.type, content)
         end)
      elseif options.type == "environment" then
         SILE.call("code", {}, function ()
            colorWrapper("command", content)
         end)
      else
         colorWrapper(options.type, content)
      end
   end)

   self:registerCommand("autodoc:setting", function (options, content)
      if type(content) ~= "table" then
         SU.error("Expected a table content")
      end
      if #content ~= 1 then
         SU.error("Expected a single element")
      end
      local name = type(content[1] == "string") and content[1]
      if not name then
         SU.error("Unexpected setting")
      end
      -- Conditional existence check (can be disable is passing check=false), e.g.
      -- for settings that would be define in another context.
      if SU.boolean(options.check, true) then
         SILE.settings:get(name) -- will issue an error if unknown
      end
      -- Inserts breakpoints after dots
      local nameWithBreaks = self.class.packages.inputfilter:transformContent(content, settingFilter)

      SILE.call("autodoc:code:style", { type = "setting" }, nameWithBreaks)
   end, "Outputs a settings name in code, ensuring good line breaks and possibly checking their existence.")

   self:registerCommand("autodoc:internal:ast", function (options, content)
      if type(content) ~= "table" then
         SU.error("Expected a table content")
      end
      SILE.call("autodoc:code:style", { type = "ast" }, function ()
         typesetAST(options, content)
      end)
   end, "Outputs a nicely typeset AST (low-level command).")

   self:registerCommand("autodoc:internal:bracketed", function (_, content)
      SILE.typesetter:typeset("⟨")
      SILE.call("autodoc:code:style", { type = "bracketed" }, function ()
         SILE.call("em", {}, content)
      end)
      SILE.call("kern", { width = "0.1em" }) -- fake italic correction.
      SILE.typesetter:typeset("⟩")
   end, "Outputs a nicely formatted user-given value within <brackets>.")

   self:registerCommand("autodoc:value", function (_, content)
      local value = type(content) == "table" and content[1] or content
      if type(value) ~= "string" then
         SU.error("Expected a string")
      end

      if value:sub(1, 1) == "<" and value:sub(-1) == ">" then
         SILE.call("autodoc:internal:bracketed", {}, { value:sub(2, -2) })
      else
         if value:match("[,=]") or value:match("^ ") or value:match(" $") then
            value = ([["%s"]]):format(value)
         end
         SILE.call("autodoc:code:style", { type = "value" }, { value })
      end
   end, "Outputs a nicely formatted argument within <brackets>.")

   -- Documenting a command, benefiting from AST parsing

   self:registerCommand("autodoc:command", function (options, content)
      if type(content) ~= "table" then
         SU.error("Expected a table content")
      end
      if type(content[1]) ~= "table" then
         SU.error("Expected a command, got " .. type(content[1]) .. " '" .. content[1] .. "'")
      end

      SILE.call("autodoc:internal:ast", options, content)
   end, "Outputs a formatted command, possibly checking its validity.")

   -- Documenting a parameter

   self:registerCommand("autodoc:parameter", function (_, content)
      if type(content) ~= "table" then
         SU.error("Expected a table content")
      end
      if #content ~= 1 then
         SU.error("Expected a single element")
      end
      local param = type(content[1] == "string") and content[1]

      local parts = {}
      for v in string.gmatch(param, "[^=]+") do
         parts[#parts + 1] = v
      end
      SILE.call("autodoc:code:style", { type = "ast" }, function ()
         if #parts < 1 or #parts > 2 then
            SU.error("Unexpected parameter '" .. param .. "'")
         end
         SILE.call("autodoc:code:style", { type = "parameter" }, { parts[1] })
         if #parts == 2 then
            SILE.typesetter:typeset("=")

            SILE.call("penalty", { penalty = 100 }, nil) -- Quite decent to break here if need be.
            SILE.call("autodoc:value", {}, { parts[2] })
         end
      end)
   end, "Outputs a nicely presented parameter, possibly with a value.")

   -- Documenting an environment

   self:registerCommand("autodoc:environment", function (options, content)
      if type(content) ~= "table" then
         SU.error("Expected a table content")
      end
      if #content ~= 1 then
         SU.error("Expected a single element")
      end
      local name = type(content[1] == "string") and content[1]
      if not name then
         SU.error("Unexpected environment")
      end
      -- Conditional existence check
      if SU.boolean(options.check, true) then
         if not SILE.Commands[name] then
            SU.error("Unknown command " .. name)
         end
      end

      SILE.call("autodoc:code:style", { type = "environment" }, { name })
   end, "Outputs a command name in code, checking its validity.")

   -- Documenting a package name

   self:registerCommand("autodoc:package", function (_, content)
      if type(content) ~= "table" then
         SU.error("Expected a table content")
      end
      if #content ~= 1 then
         SU.error("Expected a single element")
      end
      local name = type(content[1] == "string") and content[1]
      if not name then
         SU.error("Unexpected package name")
      end
      -- We cannot really check package name to exist!

      SILE.call("autodoc:package:style", {}, { name })
   end, "Outputs a package name.")

   -- Documenting a class name

   self:registerCommand("autodoc:class", function (_, content)
      if type(content) ~= "table" then
         SU.error("Expected a table content")
      end
      if #content ~= 1 then
         SU.error("Expected a single element")
      end
      local name = type(content[1] == "string") and content[1]
      if not name then
         SU.error("Unexpected class name")
      end
      -- We cannot really check class name to exist!

      SILE.call("autodoc:class:style", {}, { name })
   end, "Outputs a class name.")

   -- Homogenizing the appearance of blocks of code
   self:registerCommand("autodoc:codeblock", function (_, content)
      SILE.typesetter:leaveHmode()
      local lskip = SILE.settings:get("document.lskip") or SILE.types.node.glue()
      local rskip = SILE.settings:get("document.rskip") or SILE.types.node.glue()
      SILE.settings:temporarily(function ()
         -- Note: We avoid using the verbatim environment and simplify things a bit
         -- (and try to better enforce novbreak points of insertion)
         SILE.call("verbatim:font")
         SILE.call("language", { main = "und" })
         -- Rather than absolutizing 4 different values, just do it once and cache it
         local bs = SILE.types.measurement("1bs"):absolute()
         local ex = SILE.types.measurement("1ex"):absolute()
         local pushline = function ()
            colorWrapper("note", function ()
               SILE.call("novbreak")
               SILE.typesetter:pushVglue(-bs)
               SILE.call("novbreak")
               SILE.call("fullrule", { thickness = "0.5pt" })
               SILE.call("novbreak")
               SILE.typesetter:pushVglue(-bs-ex)
               SILE.call("novbreak")
            end)
         end
         SILE.settings:set("typesetter.parseppattern", "\n")
         SILE.settings:set("typesetter.obeyspaces", true)
         SILE.settings:set("document.lskip", SILE.types.node.glue(lskip.width.length))
         SILE.settings:set("document.rskip", SILE.types.node.glue(rskip.width.length))
         SILE.settings:set("document.parindent", SILE.types.node.glue())
         SILE.settings:set("document.parskip", SILE.types.node.vglue())
         SILE.settings:set("document.spaceskip", SILE.types.length("1spc"))
         SILE.settings:set("shaper.variablespaces", false)
         colorWrapper("codeblock", function ()
            pushline()
            SILE.process(content)
            pushline()
         end)
         SILE.typesetter:leaveHmode()
      end)
   end, "Outputs its content as a standardized block of code")

   self:registerCommand("autodoc:example", function (_, content)
      -- Loosely derived from the \examplefont command from the original SILE manual...
      SILE.call("font", { family = "Cormorant Infant", size = "1.1em" }, content)
   end, "Marks content as an example (possibly typeset in a distinct font, etc.)")

   self:registerCommand("autodoc:note", function (_, content)
      -- Replacing the \note command from the original SILE manual...
      local linedimen = SILE.types.length("0.75em")
      local linethickness = SILE.types.length("0.3pt")
      local ls = SILE.settings:get("document.lskip") or SILE.types.node.glue()
      local p = SILE.settings:get("document.parindent")
      local leftindent = (p.width:absolute() + ls.width:absolute()).length -- fixed part
      local innerindent = SILE.types.measurement("1em"):absolute()
      SILE.settings:temporarily(function ()
         SILE.typesetter:leaveHmode()
         SILE.settings:set("document.lskip", leftindent)
         SILE.settings:set("document.rskip", leftindent)
         SILE.settings:set("current.parindent", SILE.types.node.glue())
         colorWrapper("note", function ()
            SILE.call("hrule", { width = linethickness, height = linethickness, depth = linedimen })
            SILE.call("hrule", { width = 3 * linedimen, height = linethickness })
            SILE.call("hfill")
            SILE.call("hrule", { width = 3 * linedimen, height = linethickness })
            SILE.call("hrule", { width = linethickness, height = linethickness, depth = linedimen })

            SILE.call("novbreak")
            SILE.settings:temporarily(function ()
               SILE.settings:set("document.lskip", SILE.types.node.glue(leftindent + innerindent))
               SILE.settings:set("document.rskip", SILE.types.node.glue(leftindent + innerindent))
               SILE.call("font", { size = "0.95em", style = "italic " }, content)
               SILE.call("novbreak")
               SILE.typesetter:pushVglue(SILE.types.node.vglue(-0.5 * linedimen))
               SILE.call("novbreak")
            end)

            SILE.settings:set("current.parindent", SILE.types.node.glue())
            SILE.call("hrule", { width = linethickness, depth = linethickness, height = linedimen })
            SILE.call("hrule", { width = 3 * linedimen, depth = linethickness })
            SILE.call("hfill")
            SILE.call("hrule", { width = 3 * linedimen, depth = linethickness })
            SILE.call("hrule", { width = linethickness, depth = linethickness, height = linedimen })
         end)
         SILE.typesetter:leaveHmode()
      end)
   end, "Outputs its content as a note in a specific boxed and indented block")
end

package.documentation = [[
\begin{document}
The \autodoc:package{autodoc} package extracts documentation information from other packages.
It’s used to construct the SILE manual.
Keeping package documentation in the package itself keeps the documentation near the implementation, which (in theory) makes it easy for documentation and implementation to be in sync.

For that purpose, it provides the \autodoc:command{\package-documentation{<package>}} command.

Properly documented packages should export a \code{documentation} string containing their documentation, as a SILE document.

For documenters and package authors, \autodoc:package{autodoc} also provides commands that can be used in their package documentation to present various pieces of information in a consistent way.

Setting names can be fairly long (e.g., \code{namespace.area.some-stuff}).
The \autodoc:command{\autodoc:setting} command helps line-breaking them automatically at appropriate points, so that package authors do not have to do so
manually.

With the \autodoc:command{\autodoc:command} command, one can pass a simple command, or even an extended command with parameters and arguments, without the need for escaping special characters.
This relies on SILE’s AST (abstract syntax tree) parsing, so you benefit from typing simplicity, syntax check, and even more—such as styling.%
\footnote{If the \autodoc:package{color} package is loaded and the \autodoc:setting{autodoc.highlighting} setting is set to \code{true}, you get syntax highlighting.}
Moreover, for text content in parameter values or command arguments, if they are enclosed between angle brackets, they will be presented in a distinguishable style.
Just type the command as it would appear in code, and it will be nicely typeset.
It comes with a few caveats, though: parameters are not guaranteed to appear in the order you entered them, and some purely syntactic sequences are simply skipped and not reconstructed.
Also, it is not adapted to math-related commands.
So it comes with many benefits, but also at a cost.

The \autodoc:command{\autodoc:environment} command takes an environment name or a command, but displays it without a leading backslash.

The \autodoc:command{\autodoc:setting}, \autodoc:command{\autodoc:command}, and \autodoc:command{\autodoc:environment} commands all check the validity and existence of their inputs.
If you want to disable this feature (e.g., to refer to a setting or command defined in another package or module that might not yet be loaded), you can set the optional parameter \autodoc:parameter{check} to \code{false}.
Note, however, that for commands, it is applied recursively to the parsed AST—so it is a all-or-none trade-off.

The \autodoc:command{\autodoc:parameter} commands takes either a parameter name, possibly with a value (which as above, may be bracketed) and typesets it in the same fashion.

The \autodoc:environment{autodoc:codeblock} environment allows typesetting a block of code in a consistent way.
This is not a true verbatim environment, and you still have to escape SILE’s special characters within it
(unless calling commands is what you really intend doing there, obviously).
For convenience, the package also provides a \code{raw} handler going by the same name, where you do not have to escape the special characters (backslashes, braces, percents).

The \autodoc:command{\autodoc:example} marks its content as an example, possibly typeset in a different choice of font.

The \autodoc:command{\autodoc:note} outputs its content as a note, in a dedicated framed and indented block.
The \autodoc:command{\autodoc:package} and \autodoc:command{\autodoc:class} commands are used to format a package and class name.
\end{document}
]]

return package
