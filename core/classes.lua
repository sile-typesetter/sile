SILE.Help = {}

SILE.registerCommand = function (name, func, help, pack)
  SILE.Commands[name] = func
  if not pack then
    local where = debug.getinfo(2).source
    pack = where:match("(%w+).lua")
  end
  --if not help and not pack:match(".sil") then SU.error("Could not define command '"..name.."' (in package "..pack..") - no help text" ) end
  SILE.Help[name] = {
    description = help,
    where = pack
  }
end

SILE.setCommandDefaults = function (command, defaults)
  local oldCommand = SILE.Commands[command]
  SILE.Commands[command] = function (options, content)
    for k, v in pairs(defaults) do
      options[k] = options[k] or v
    end
    return oldCommand(options, content)
  end
end

SILE.doTexlike = function (doc)
  -- Setup new "fake" file in which the doc exists
  local cpf = SILE.currentlyProcessingFile
  local caller = debug.getinfo(2, "Sl")
  local temporaryFile = "<"..caller.short_src..":"..caller.currentline..">"
  SILE.currentlyProcessingFile = temporaryFile
  -- NOTE: this messes up column numbers on first line, but most places start with newline, so it isn't a problem
  doc = "\\begin{document}" .. doc .. "\\end{document}"
  local tree = SILE.inputs.TeXlike.docToTree(doc)
  -- Since elements of the tree may be used long after currentlyProcessingFile has changed (e.g. through \define)
  -- supply the file in which the node was found explicitly.
  SU.walkContent(tree, function (c) c.file = temporaryFile end)
  SILE.process(tree)
  -- Revert the processed file
  SILE.currentlyProcessingFile = cpf
end

local function replaceProcessBy(replacement, tree)
  if type(tree) ~= "table" then return tree end
  local ret = pl.tablex.deepcopy(tree)
  if tree.command == "process" then
    return replacement
  else
    for i, child in ipairs(tree) do
      ret[i] = replaceProcessBy(replacement, child)
    end
    return ret
  end
end

-- Need the \define command *really* early on in SILE startup
SILE.registerCommand("define", function (options, content)
  SU.required(options, "command", "defining command")
  if type(content) == "function" then
    -- A macro defined as a function can take no argument, so we register
    -- it as-is.
    SILE.registerCommand(options["command"], content)
    return
  elseif options.command == "process" then
    SU.warn("Did you mean to re-definine the `\\process` macro? That probably won't go well.")
  end
  SILE.registerCommand(options["command"], function (_, inner_content)
    SU.debug("macros", "Processing macro \\" .. options["command"])
    local macroArg
    if type(inner_content) == "function" then
      macroArg = inner_content
    elseif type(inner_content) == "table" then
      macroArg = pl.tablex.copy(inner_content)
      macroArg.command = nil
      macroArg.id = nil
    elseif inner_content == nil then
      macroArg = {}
    else
      SU.error("Unhandled content type " .. type(inner_content) .. " passed to macro \\" .. options["command"], true)
    end
    -- Replace every occurrence of \process in `content` (the macro
    -- body) with `macroArg`, then have SILE go through the new `content`.
    local newContent = replaceProcessBy(macroArg, content)
    SILE.process(newContent)
    SU.debug("macros", "Finished processing \\" .. options["command"])
  end, options.help, SILE.currentlyProcessingFile)
end, "Define a new macro. \\define[command=example]{ ... \\process }")

-- A utility function that allows SILE.call() to be used as a noop wrapper.
SILE.registerCommand("noop", function (_, content)
  SILE.process(content)
end)

SILE.registerCommand("comment", function (_, _)
end, "Ignores any text within this command's body.")

SILE.registerCommand("process", function ()
  SU.error("Encountered unsubstituted \\process.")
end, "Within a macro definition, processes the contents of the macro body.")

return {
  base = require("classes.base")
}
