SILE.Help = {}

SILE.registerCommand = function (name, func, help, pack)
  SILE.Commands[name] = SILE.typesetter and SILE.typesetter.breadcrumbs(name, func) or func
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
  doc = "\\begin{document}" .. doc .. "\\end{document}"
  local cpf = SILE.currentlyProcessingFile
  SILE.currentlyProcessingFile = "<"..debug.getinfo(2).short_src..":"..debug.getinfo(2).linedefined..">"
  SILE.process(SILE.inputs.TeXlike.docToTree(doc))
  SILE.currentlyProcessingFile = cpf
end

-- Need the \define command *really* early on in SILE startup
local commandStack = {}
SILE.registerCommand("define", function (options, content)
  SU.required(options, "command", "defining command")
  SILE.registerCommand(options["command"], function (options2, content2)
    --local prevState = SILE.documentState
    --SILE.documentState = std.tree.clone( prevState )
    local depth = #commandStack
    table.insert(commandStack, content2)
    SU.debug("macros","Processing a "..options["command"].." Stack depth is "..depth)
    SILE.process(content)
    while (#commandStack > depth) do table.remove(commandStack) end
    SU.debug("macros","Finished processing "..options["command"].." Stack depth is "..#commandStack.."\n")
    --SILE.documentState = prevState
  end, options.help, SILE.currentlyProcessingFile)
end, "Define a new macro. \\define[command=example]{ ... \\process }")

SILE.registerCommand("comment", function (options, content)
end, "Ignores any text within this command's body.")

SILE.registerCommand("process", function ()
  local val = table.remove(commandStack)
  if not val then SU.error("Macro stack underflow. Too many \\process calls?") end
  SILE.process(val)
end, "Within a macro definition, processes the contents of the macro body.")

SILE.baseClass = std.object {
  registerCommands = (function ()
    SILE.registerCommand("\\", function (options, content) SILE.typesetter:typeset("\\") end)

    SILE.registerCommand("script", function (options, content)
      if (options["src"]) then
        require(options["src"])
      else
        p,e = loadstring(content[1])
        if not p then SU.error(e) end
        p()
      end
    end, "Runs lua code. The code may be supplied either inline or using the src=... option. (Think HTML.)")

    SILE.registerCommand("include", function (options, content)
        SILE.readFile(options["src"])
    end, "Includes a SILE file for processing.")

    SILE.registerCommand("pagetemplate", function (options, content)
      SILE.documentState.thisPageTemplate = { frames = {} }
      SILE.process(content)
      SILE.documentState.thisPageTemplate.firstContentFrame = SILE.getFrame(options["first-content-frame"])
      SILE.typesetter:initFrame(SILE.documentState.thisPageTemplate.firstContentFrame)
    end, "Defines a new page template for the current page and sets the typesetter to use it.")

    SILE.registerCommand("frame", function (options, content)
      SILE.documentState.thisPageTemplate.frames[options.id] = SILE.newFrame(options)
    end, "Declares (or re-declares) a frame on this page.")

    SILE.registerCommand("penalty", function (options, content)
      if options.vertical and not SILE.typesetter:vmode() then
        SILE.typesetter:leaveHmode()
      end
      if SILE.typesetter:vmode() then
        SILE.typesetter:pushVpenalty({ flagged = tonumber(options.flagged), penalty = tonumber(options.penalty) })
      else
        SILE.typesetter:pushPenalty({ flagged = tonumber(options.flagged), penalty = tonumber(options.penalty) })
      end
    end, "Inserts a penalty node. Options are penalty= for the size of the penalty and flagged= if this is a flagged penalty.")

    SILE.registerCommand("discretionary", function (options, content)
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

    SILE.registerCommand("glue", function (options, content)
      SILE.typesetter:pushGlue({
        width = SILE.length.parse(options.width):absolute()
      })
    end, "Inserts a glue node. The width option denotes the glue dimension.")

    SILE.registerCommand("kern", function (options, content)
      table.insert(SILE.typesetter.state.nodes,
        SILE.nodefactory.newKern({
          width = SILE.length.parse(options.width):absolute()
        })
      )
    end, "Inserts a glue node. The width option denotes the glue dimension.")

    SILE.registerCommand("skip", function (options, content)
      options.discardable = options.discardable or false
      options.height = SILE.length.parse(options.height):absolute()
      SILE.typesetter:leaveHmode()
      if options.discardable then
        SILE.typesetter:pushVglue(options)
      else
        SILE.typesetter:pushExplicitVglue(options)
      end
    end, "Inserts vertical skip. The height options denotes the skip dimension.")

    SILE.registerCommand("par", function (options, content)
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
      type = "Glue or nil",
      default = nil,
      help = "Glue at start of paragraph"
    })
    SILE.outputter.init(self)
    self:registerCommands()
    -- Call all stored package init routines
    for i = 1,#(SILE.baseClass.deferredInit) do (SILE.baseClass.deferredInit[i])() end
    SILE.typesetter:registerPageEndHook(function ()
      if SU.debugging("frames") then
        for k,v in pairs(SILE.frames) do SILE.outputter:debugFrame(v) end
      end
    end)
    return self:initialFrame()
  end,

  initialFrame = function (self)
    SILE.documentState.thisPageTemplate = std.tree.clone(self.pageTemplate)
    local p = SILE.frames.page
    SILE.frames = { page = p }
    for k,v in pairs(SILE.documentState.thisPageTemplate.frames) do
      SILE.frames[k] = v
    end
    SILE.documentState.thisPageTemplate.firstContentFrame:invalidate()
    return SILE.documentState.thisPageTemplate.firstContentFrame
  end,

  declareFrame = function (self, id, spec)
    -- local fW = function (val) return function () return SILE.parseComplexFrameDimension(val, "w"); end end
    -- local fH = function (val) return function () return SILE.parseComplexFrameDimension(val, "h"); end end
    spec.id = id
    SILE.frames[id] = nil
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
    while not (#SILE.typesetter.state.nodes == 0 and #SILE.typesetter.state.outputQueue == 0) do
      SILE.call("supereject")
      SILE.typesetter:leaveHmode(true)
      SILE.typesetter:pageBuilder()
      if not (#SILE.typesetter.state.nodes == 0 and #SILE.typesetter.state.outputQueue == 0) then
        SILE.typesetter:initNextFrame()
      end
    end
    SILE.typesetter:runHooks("pageend") -- normally run by the typesetter
    self:endPage()
    assert(#SILE.typesetter.state.nodes == 0 and #SILE.typesetter.state.outputQueue == 0, "queues not empty")
    SILE.outputter:finish()
  end,

  newPar = function (typesetter)
    typesetter:pushGlue(SILE.settings.get("current.parindent") or SILE.settings.get("document.parindent"))
    SILE.settings.set("current.parindent", nil)
  end,

  endPar = function (typesetter)
    local g = SILE.settings.get("document.parskip")
    typesetter:pushVglue(std.tree.clone(g))
  end,

  options = {
    papersize = function (size)
      SILE.documentState.paperSize = SILE.paperSizeParser(size)
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
