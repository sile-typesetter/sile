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

-- Need the \define command *really* early on in SILE startup
local macroStack = {}
SILE.registerCommand("define", function (options, content)
  SU.required(options, "command", "defining command")
  SILE.registerCommand(options["command"], function (_, _content)
    --local prevState = SILE.documentState
    --SILE.documentState = pl.tablex.deepcopy( prevState )
    local depth = #macroStack
    table.insert(macroStack, _content)
    SU.debug("macros", "Processing a "..options["command"].." Stack depth is "..depth)
    SILE.process(content)
    while (#macroStack > depth) do table.remove(macroStack) end
    SU.debug("macros", "Finished processing "..options["command"].." Stack depth is "..#macroStack.."\n")
    --SILE.documentState = prevState
  end, options.help, SILE.currentlyProcessingFile)
end, "Define a new macro. \\define[command=example]{ ... \\process }")

SILE.registerCommand("comment", function (_, _)
end, "Ignores any text within this command's body.")

SILE.registerCommand("process", function ()
  local val = table.remove(macroStack)
  if not val then SU.error("Macro stack underflow. Too many \\process calls?") end
  SILE.process(val)
end, "Within a macro definition, processes the contents of the macro body.")

SILE.baseClass = std.object {
  registerCommands = (function ()

    SILE.registerCommand("\\", function (_, _)
      SILE.typesetter:typeset("\\")
    end)

    SILE.registerCommand("script", function (options, content)
      if (options["src"]) then
        require(options["src"])
      else
        local func, err = load(content[1])
        if not func then SU.error(err) end
        func()
      end
    end, "Runs lua code. The code may be supplied either inline or using the src=... option. (Think HTML.)")

    SILE.registerCommand("include", function (options, _)
        SILE.readFile(options["src"])
    end, "Includes a SILE file for processing.")

    SILE.registerCommand("pagetemplate", function (options, content)
      SILE.documentState.thisPageTemplate = { frames = {} }
      SILE.process(content)
      SILE.documentState.thisPageTemplate.firstContentFrame = SILE.getFrame(options["first-content-frame"])
      SILE.typesetter:initFrame(SILE.documentState.thisPageTemplate.firstContentFrame)
    end, "Defines a new page template for the current page and sets the typesetter to use it.")

    SILE.registerCommand("frame", function (options, _)
      SILE.documentState.thisPageTemplate.frames[options.id] = SILE.newFrame(options)
    end, "Declares (or re-declares) a frame on this page.")

    SILE.registerCommand("penalty", function (options, _)
      if options.vertical and not SILE.typesetter:vmode() then
        SILE.typesetter:leaveHmode()
      end
      if SILE.typesetter:vmode() then
        SILE.typesetter:pushVpenalty({ penalty = tonumber(options.penalty) })
      else
        SILE.typesetter:pushPenalty({ penalty = tonumber(options.penalty) })
      end
    end, "Inserts a penalty node. Option is penalty= for the size of the penalty.")

    SILE.registerCommand("discretionary", function (options, _)
      local discretionary = SILE.nodefactory.newDiscretionary({})
      if options.prebreak then
        SILE.call("hbox", {}, function () SILE.typesetter:typeset(options.prebreak) end)
        discretionary.prebreak = { SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] }
        SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
      end
      if options.postbreak then
        SILE.call("hbox", {}, function () SILE.typesetter:typeset(options.postbreak) end)
        discretionary.postbreak = { SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] }
        SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
      end
      if options.replacement then
        SILE.call("hbox", {}, function () SILE.typesetter:typeset(options.replacement) end)
        discretionary.replacement = { SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] }
        SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = nil
      end
      table.insert(SILE.typesetter.state.nodes, discretionary)
    end, "Inserts a discretionary node.")

    SILE.registerCommand("glue", function (options, _)
      SILE.typesetter:pushGlue({
        width = SILE.length.parse(options.width):absolute()
      })
    end, "Inserts a glue node. The width option denotes the glue dimension.")

    SILE.registerCommand("kern", function (options, _)
      table.insert(SILE.typesetter.state.nodes,
        SILE.nodefactory.newKern({
          width = SILE.length.parse(options.width):absolute()
        })
      )
    end, "Inserts a glue node. The width option denotes the glue dimension.")

    SILE.registerCommand("skip", function (options, _)
      options.discardable = options.discardable or false
      options.height = SILE.length.parse(options.height):absolute()
      SILE.typesetter:leaveHmode()
      if options.discardable then
        SILE.typesetter:pushVglue(options)
      else
        SILE.typesetter:pushExplicitVglue(options)
      end
    end, "Inserts vertical skip. The height options denotes the skip dimension.")

    SILE.registerCommand("par", function (_, _)
      SILE.typesetter:endline()
    end, "Ends the current paragraph.")

  end),

  pageTemplate = std.object { frames = {}, firstContentFrame = nil },

  deferredInit = {},

  loadPackage = function (self, packname, args)
    local pack = require("packages/" .. packname)
    if type(pack) == "table" then
      if pack.exports then self:mapfields(pack.exports) end
      if pack.init then
        table.insert(SILE.baseClass.deferredInit, function () pack.init(self, args) end)
      end
    end
  end,

  init = function (self)
    SILE.settings.declare({
      name = "current.parindent",
      type = "glue or nil",
      default = nil,
      help = "Glue at start of paragraph"
    })
    SILE.outputter.init(self)
    self:registerCommands()
    -- Call all stored package init routines
    for i = 1, #(SILE.baseClass.deferredInit) do (SILE.baseClass.deferredInit[i])() end
    SILE.typesetter:registerPageEndHook(function ()
      if SU.debugging("frames") then
        for _, v in pairs(SILE.frames) do SILE.outputter:debugFrame(v) end
      end
    end)
    return self:initialFrame()
  end,

  initialFrame = function (self)
    SILE.documentState.thisPageTemplate = pl.tablex.deepcopy(self.pageTemplate)
    SILE.frames = { page = SILE.frames.page }
    for k, v in pairs(SILE.documentState.thisPageTemplate.frames) do
      SILE.frames[k] = v
    end
    SILE.documentState.thisPageTemplate.firstContentFrame:invalidate()
    return SILE.documentState.thisPageTemplate.firstContentFrame
  end,

  declareFrame = function (self, id, spec)
    spec.id = id
    self.pageTemplate.frames[id] = SILE.newFrame(spec)
    --   next = spec.next,
    --   left = spec.left and fW(spec.left),
    --   right = spec.right and fW(spec.right),
    --   top = spec.top and fH(spec.top),
    --   bottom = spec.bottom and fH(spec.bottom),
    --   height = spec.height and fH(spec.height),
    --   width = spec.width and fH(spec.width),
    --   id = id
    -- })
  end,

  declareFrames = function (self, specs)
    if specs then
      for k, v in ipairs(specs) do self:declareFrame(k, v) end
    end
  end,

  newPage = function (self)
    SILE.outputter:newPage()
    -- Any other output-routiney things will be done here by inheritors
    return self:initialFrame()
  end,

  endPage = function ()
    SILE.typesetter.frame:leave()
    -- I'm trying to call up a new frame here, don't cause a page break in the current one
    -- SILE.typesetter:leaveHmode()
    -- Any other output-routiney things will be done here by inheritors
  end,

  finish = function (self)
    SILE.call("vfill")
    while not SILE.typesetter:isQueueEmpty() do
      SILE.call("supereject")
      SILE.typesetter:leaveHmode(true)
      SILE.typesetter:buildPage()
      if not SILE.typesetter:isQueueEmpty() then
        SILE.typesetter:initNextFrame()
      end
    end
    SILE.typesetter:runHooks("pageend") -- normally run by the typesetter
    self:endPage()
    assert(SILE.typesetter:isQueueEmpty(), "queues not empty")
    SILE.outputter:finish()
  end,

  newPar = function (typesetter)
    typesetter:pushGlue(SILE.settings.get("current.parindent") or SILE.settings.get("document.parindent"))
    SILE.settings.set("current.parindent", nil)
  end,

  endPar = function (typesetter)
    typesetter:pushVglue(SILE.settings.get("document.parskip"))
  end,

  options = {
    papersize = function (size)
      SILE.documentState.paperSize = SILE.papersize(size)
      SILE.documentState.orgPaperSize = SILE.documentState.paperSize
      SILE.newFrame({
          id = "page",
          left = 0,
          top = 0,
          right = SILE.documentState.paperSize[1],
          bottom = SILE.documentState.paperSize[2]
        })
    end
  }
}
