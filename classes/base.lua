local _oldbase = {
  registerCommands = function ()

    SILE.registerCommand("script", function (options, content)
      if (options["src"]) then
        local script, _ = require(options["src"])
        if type(script) == "table" and script.init then
          script.init()
        end
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
      SILE.typesetter:pushState()
      SILE.documentState.thisPageTemplate = { frames = {} }
      SILE.process(content)
      SILE.documentState.thisPageTemplate.firstContentFrame = SILE.getFrame(options["first-content-frame"])
      SILE.typesetter:initFrame(SILE.documentState.thisPageTemplate.firstContentFrame)
      SILE.typesetter:popState()
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
      local discretionary = SILE.nodefactory.discretionary({})
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
      local width = SU.cast("length", options.width):absolute()
      SILE.typesetter:pushGlue(width)
    end, "Inserts a glue node. The width option denotes the glue dimension.")

    SILE.registerCommand("kern", function (options, _)
      local width = SU.cast("length", options.width):absolute()
      SILE.typesetter:pushHorizontal(SILE.nodefactory.kern(width))
    end, "Inserts a glue node. The width option denotes the glue dimension.")

    SILE.registerCommand("skip", function (options, _)
      options.discardable = options.discardable or false
      options.height = SILE.length(options.height):absolute()
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

  end,

  pageTemplate = std.object { frames = {}, firstContentFrame = nil },

  deferredInit = {},

  loadPackage = function (self, packname, args)
    local pack = require("packages/" .. packname)
    self:initPackage(pack, args)
  end,

  initPackage = function (self, pack, args)
    if type(pack) == "table" then
      if pack.exports then pl.tablex.update(self, pack.exports) end
      if type(pack.init) == "function" then
        table.insert(SILE.classes.base.deferredInit, function () pack.init(self, args) end)
        if self._initialized then
          pack.init(self, args)
        end
      end
    end
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
    if spec.solve then
      self.pageTemplate.frames[id] = spec
    else
      self.pageTemplate.frames[id] = SILE.newFrame(spec)
    end
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
      for k, v in pairs(specs) do self:declareFrame(k, v) end
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
    local hangIndent = SILE.settings.get("current.hangIndent")
    if hangIndent then
      SILE.settings.set("linebreak.hangIndent", hangIndent)
    end
    local hangAfter = SILE.settings.get("current.hangAfter")
    if hangAfter then
      SILE.settings.set("linebreak.hangAfter", hangAfter)
    end
  end,

  endPar = function (typesetter)
    typesetter:pushVglue(SILE.settings.get("document.parskip"))
    if SILE.settings.get("current.hangIndent") then
      SILE.settings.set("current.hangIndent", nil)
      SILE.settings.set("linebreak.hangIndent", nil)
    end
    if SILE.settings.get("current.hangAfter") then
      SILE.settings.set("current.hangAfter", nil)
      SILE.settings.set("linebreak.hangAfter", nil)
    end
  end,
}

local base = pl.class({
    type = "class",
    _initialized = false,
    deferredInit = {},
    pageTemplate = _oldbase.pageTemplate,
    defaultFrameset = {},
    firstContentFrame = "page",
    options = {},

    _init = function (self, options)
      if not options then options = {} end
      self:declareOption("id", function (_)
        -- The old std.object inheritence for classes called the base class with
        -- and arg of a table which had an ID. Since the new system doesn't have
        -- an ID arg, we can assume this is unported code. See also core/sile.lua
        -- for the actual deprecation mechanism for the old SILE.baseClass.
        SU.warn([[
        The inheritance system for SILE classes has been refactored using a
          different object model, please update your code as use of the old
          model will cause unexpected errors and will eventually be removed.
        ]])
        SU.deprecated("std.object x", "pl.class", "0.11.0", "0.12.0")
      end)
      self:declareOption("class", function (name) return name end)
      self:declareOption("papersize", function (size)
        SILE.documentState.paperSize = SILE.papersize(size)
        SILE.documentState.orgPaperSize = SILE.documentState.paperSize
        SILE.newFrame({
            id = "page",
            left = 0,
            top = 0,
            right = SILE.documentState.paperSize[1],
            bottom = SILE.documentState.paperSize[2]
          })
        return size
      end)
      for k, v in pairs(options) do
        self.options[k] = v
      end
      SILE.outputter:init(self)
      self:declareSettings()
      self:registerCommands()
      self:declareFrames(self.defaultFrameset)
      self.pageTemplate.firstContentFrame = self.pageTemplate.frames[self.firstContentFrame]
      for i = 1, #(SILE.classes.base.deferredInit) do (SILE.classes.base.deferredInit[i])() end
      SILE.typesetter:registerPageEndHook(function ()
        if SU.debugging("frames") then
          for _, v in pairs(SILE.frames) do SILE.outputter:debugFrame(v) end
        end
      end)
      self._initialized = true
    end,

    declareOption = function (self, option, setter)
      if not getmetatable(self.options) then
        setmetatable(self.options, {
            __newindex = function (self_, key, value)
              local setter_ = getmetatable(self_)[key]
              if not setter then
                SU.error("Attempted to set a class option '" .. key .. "' that isn’t registered.")
              end
              rawset(self_, key, setter_(value))
            end
          })
      end
      getmetatable(self.options)[option] = setter
    end,

    declareSettings = function (_)
      SILE.settings.declare({
        parameter = "current.parindent",
        type = "glue or nil",
        default = nil,
        help = "Glue at start of paragraph"
      })
      SILE.settings.declare({
        parameter = "current.hangIndent",
        type = "integer or nil",
        default = nil,
        help = "Size of hanging indent"
      })
      SILE.settings.declare({
        parameter = "current.hangAfter",
        type = "integer or nil",
        default = nil,
        help = "Number of lines affected by handIndent"
      })
    end,

    loadPackage = _oldbase.loadPackage,
    initPackage = _oldbase.initPackage,
    registerCommands = _oldbase.registerCommands,
    initialFrame = _oldbase.initialFrame,
    declareFrame = _oldbase.declareFrame,
    declareFrames = _oldbase.declareFrames,
    newPar = _oldbase.newPar,
    endPar = _oldbase.endPar,
    newPage = _oldbase.newPage,
    endPage = _oldbase.endPage,
    finish = _oldbase.finish
  })

return base
