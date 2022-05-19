--
-- Documentation tooling for package designers.
--

SILE.registerCommand("package-documentation", function (options, _)
  local package = SU.required(options, "src", "src for package documentation")
  SU.debug("autodoc", package)
  local pkg = require(package)
  if type(pkg) ~= "table" or not pkg.documentation then
    SU.error("Undocumented package "..package)
  end
  if type(pkg.registerCommands) == "function" then pkg.registerCommands(SILE.documentState.documentClass) end
  SILE.process(
    SILE.inputs.TeXlike.docToTree(
      pkg.documentation
    )
  )
end)

-- Styling hook

SILE.settings.declare({
  parameter = "autodoc.highlighting",
  default = false,
  type = "boolean",
  help = "Whether audodoc enables syntax highlighting"
})

SILE.scratch.autodoc = {
  theme = {
    command = "#1d4851", -- oil blue
    parameter = "#3f5218", -- some sort of dark green
    setting = "#42280e", -- some kind of dark brown
    bracketed = "#656565", -- some grey
    package = "#172557", -- saturated space blue
  }
}
local colorWrapper = function (ctype, content)
  local color = SILE.scratch.autodoc.theme[ctype]
  if color and SILE.settings.get("autodoc.highlighting") and SILE.Commands["color"] then
    SILE.call("color", { color = color }, content)
  else
    SILE.process(content)
  end
end

SILE.registerCommand("autodoc:package:style", function (_, content)
  SILE.call("font", { weight = 700 }, function()
    colorWrapper("package", content)
  end)
end)

SILE.registerCommand("autodoc:code:style", function (options, content)
  -- options.type is used to distinguish the type of code element and style
  -- it accordingly: "ast", "setting", "environment" shall select the font
  -- (by default, using \code) and color, the other (lower-level in an AST)
  -- shall select only the color.
  if options.type == "ast" then
    SILE.call("code", {}, content)
  elseif options.type == "setting" then
    SILE.call("code", {}, function()
      colorWrapper(options.type, content)
    end)
  elseif options.type == "environment" then
    SILE.call("code", {}, function()
      colorWrapper("command", content)
    end)
  else
    colorWrapper(options.type, content)
  end
end)

-- Documenting a setting with good line-breaks

local inputfilter = SILE.require("packages.inputfilter").exports
local settingFilter = function (node, content)
  if type(node) == "table" then return node end
  local result = {}
  for token in SU.gtoke(node, "[%.]") do
    if token.string then
      result[#result+1] = token.string
    else
        result[#result+1] = token.separator
        result[#result+1] = inputfilter.createCommand(
          content.pos, content.col, content.line,
          "penalty", { penalty = 100 }, nil
        )
    end
  end
  return result
end

SILE.registerCommand("autodoc:setting", function (options, content)
  if type(content) ~= "table" then SU.error("Expected a table content") end
  if #content ~= 1 then SU.error("Expected a single element") end
  local name = type(content[1] == "string") and content[1]
  if not name then SU.error("Unexpected setting") end
  -- Conditional existence check (can be disable is passing check=false), e.g.
  -- for settings that would be define in another context.
  if SU.boolean(options.check, true) then
    SILE.settings.get(name) -- will issue an error if unknown
  end
  -- Inserts breakpoints after dots
  local nameWithBreaks = inputfilter.transformContent(content, settingFilter)

  SILE.call("autodoc:code:style", { type = "setting" }, nameWithBreaks)
end, "Outputs a settings name in code, ensuring good line breaks and possibly checking their existence.")

-- Documenting a command, benefiting from AST parsing

local function optionSorter(o1, o2)
  -- options are in an associative table and Lua doesn't guarantee a fixed order.
  -- To ensure we get a consistent and stable output, we make with some wild guesses here
  -- (Quick'n dirty, could be improved!), and rely on alphabetical order otherwise.
  if o1 == "src" then return true end
  if o2 == "src" then return false end
  if o1 == "name" then return true end
  if o2 == "name" then return false end
  return o1 < o2
end

local function typesetAST(options, content)
  if not content then return end
  local seenCommandWithoutArg = false
  for i = 1, #content do
    local ast = content[i]

    if type(ast) == "string" then
      if seenCommandWithoutArg and ast:sub(1,1) ~= " " and ast:sub(1,1) ~= "{" then
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
        SU.error("Unexpected command '"..ast.command.."'")
      end
      SILE.typesetter:typeset("\\")
      SILE.call("autodoc:code:style", { type = "command" }, { ast.command })

      local sortedOpts = {}
      for k, _ in pairs(ast.options) do table.insert(sortedOpts, k) end
      table.sort(sortedOpts, optionSorter)
      if #sortedOpts > 0 then
        SILE.typesetter:typeset("[")
        for iOpt, option in ipairs(sortedOpts) do
          SILE.call("autodoc:code:style", { type = "parameter" }, { option })
          SILE.typesetter:typeset("=")
          SILE.call("penalty", { penalty = 100 }, nil) -- Quite decent to break here if need be.
          SILE.call("autodoc:value", {}, { ast.options[option] })
          if iOpt == #sortedOpts then
            SILE.typesetter:typeset("]")
          else
            SILE.typesetter:typeset(", ")
          end
        end
      end
      if (#ast >= 1) then
        SILE.call("penalty", { penalty = 200 }, nil) -- Less than optimal break.
        SILE.typesetter:typeset("{")
        typesetAST(options, ast)
        SILE.typesetter:typeset("}")
      else
        seenCommandWithoutArg = true
      end

    else
      SU.error("Unrecognized AST element")
    end
  end
end

SILE.registerCommand("autodoc:internal:ast", function (options, content)
  if type(content) ~= "table" then SU.error("Expected a table content") end
  SILE.call("autodoc:code:style", { type = "ast" }, function ()
    typesetAST(options, content)
  end)
end, "Outputs a nicely typeset AST (low-level command).")

SILE.registerCommand("autodoc:internal:bracketed", function (_, content)
  SILE.typesetter:typeset("⟨")
  SILE.call("autodoc:code:style", { type = "bracketed" }, function()
    SILE.call("em", {}, content)
  end)
  SILE.call("kern", { width = "0.1em" }) -- fake italic correction.
  SILE.typesetter:typeset("⟩")
end, "Outputs a nicely formatted user-given value within <brackets>.")

SILE.registerCommand("autodoc:value", function (_, content)
  local value = type(content) == "table" and content[1] or content
  if type(value) ~= "string" then SU.error("Expected a string") end

  if value:sub(1, 1) == "<" and value:sub(-1) == ">" then
    SILE.call("autodoc:internal:bracketed", {}, { value:sub(2, -2) })
  else
    -- Here we should check for comma/semicolon, or surrounding spaces, and in that
    -- case add quotes around the value. This is a bit of an edge-case though, esp.
    -- for documentation needs.
    SILE.call("autodoc:code:style", { type = "value" }, content)
  end
end, "Outputs a nicely formatted argument within <brackets>.")

SILE.registerCommand("autodoc:command", function (options, content)
  if type(content) ~= "table" then SU.error("Expected a table content") end
  if type(content[1]) ~= "table" then SU.error("Expected a command, got "..type(content[1]).." '"..content[1].."'") end

  SILE.call("autodoc:internal:ast", options, content)
end, "Outputs a formatted command, possibly checking its validity.")

-- Documenting a parameter

SILE.registerCommand("autodoc:parameter", function (_, content)
  if type(content) ~= "table" then SU.error("Expected a table content") end
  if #content ~= 1 then SU.error("Expected a single element") end
  local param = type(content[1] == "string") and content[1]

  local parts = {}
  for v in string.gmatch(param, "[^=]+") do
    parts[#parts+1] = v
  end
  SILE.call("autodoc:code:style", { type = "ast" }, function ()
    if #parts < 1 or #parts > 2 then SU.error("Unexpected parameter '"..param.."'") end
    SILE.call("autodoc:code:style", { type = "parameter" }, { parts[1] })
    if #parts == 2 then
      SILE.typesetter:typeset("=")

      SILE.call("penalty", { penalty = 100 }, nil) -- Quite decent to break here if need be.
      SILE.call("autodoc:value", {}, { parts[2] })
    end
  end)
end, "Outputs a nicely presented parameter, possibly with a value.")

-- Documenting an environment

SILE.registerCommand("autodoc:environment", function (options, content)
  if type(content) ~= "table" then SU.error("Expected a table content") end
  if #content ~= 1 then SU.error("Expected a single element") end
  local name = type(content[1] == "string") and content[1]
  if not name then SU.error("Unexpected environment") end
  -- Conditional existence check
  if SU.boolean(options.check, true) then
    if not SILE.Commands[name] then SU.error("Unknown command "..name) end
  end

  SILE.call("autodoc:code:style", { type = "environment" }, { name })
end, "Outputs a command name in code, checking its validity.")

-- Documenting a package name

SILE.registerCommand("autodoc:package", function (_, content)
  if type(content) ~= "table" then SU.error("Expected a table content") end
  if #content ~= 1 then SU.error("Expected a single element") end
  local name = type(content[1] == "string") and content[1]
  if not name then SU.error("Unexpected package name") end
  -- We cannot really check package name to exist!

  SILE.call("autodoc:package:style", {}, { name })
end, "Outputs a package name in code, checking its validity.")

return {
  documentation = [[\begin{document}
This package extracts documentation information from other packages. It’s used to
construct the SILE manual. Keeping package documentation in the package itself
keeps the documentation near the implementation, which (in theory) makes it easy
for documentation and implementation to be in sync.

For that purpose, it provides the \autodoc:command{\package-documentation[src=<package>]}
command.

Properly documented packages should export a \code{documentation} string
containing their documentation, as a SILE document.

For documenters and package authors, it also provides commands that can be used in their package
documentation to present various pieces of information in a consistent way.

Setting names can be fairly long (e.g. \em{namespace.area.some-stuff\kern[width=0.1em]}).
The \autodoc:command{\autodoc:setting} command helps line-breaking them automatically at
appropriate points, so that package authors do not have care about them
manually.

With the \autodoc:command{\autodoc:command} command, one can pass a simple command, or even
a full commands (with parameters and arguments), without the need for escaping special
characters. This relies on SILE’s AST (abstract syntax tree) parsing, so you benefit from
typing simplicity, syntax check, and even more –such as styling\footnote{If the \autodoc:package{color}
package is loaded and the \autodoc:setting{autodoc.highlighting} setting is set to true, you get syntax
highlighting.}.
Moreover, for text content in parameter values or command arguments, if they are enclosed
between angle brackets, they will be presented with an distinguishable style.
Just type the command as it would appear in code, and it will be nicely typeset. It comes with
a few caveats, though: parameters are not guaranteed to appear in the order you entered them and
some purely syntactic sequences are just skipped and not reconstructed. Also, it is not adapted
to math-related commands. So it comes with many benefits, but also at a cost.

The \autodoc:command{\autodoc:environment} command just takes an environment name, so
basically a command, but just displays it without leading backslash.

The \autodoc:command{\autodoc:setting}, \autodoc:command{\autodoc:command} and
\autodoc:command{\autodoc:environment} commands all check the validity and existence of
their inputs. Would you want to disable this feature (e.g. to refer to a setting or command
defined in another package or module that might not be loaded at this point), you can set the
optional parameter \autodoc:parameter{check} to false.
Note, however, that for commands, it is applied recursively to the parsed AST
(so it is a all-or-none trade-off).

The \autodoc:command{\autodoc:parameter} commands takes either a parameter name, possibly
with a value (which as above, may be bracketed) and typesets it in the same fashion.

\end{document}]]
}
