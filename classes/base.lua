-- foo
local base = pl.class()

-- base.type = "class"
base._name = "base"
base._initialized = false
base.deferredInit = {}
base.pageTemplate = std.object { frames = {}, firstContentFrame = nil }
base.defaultFrameset = {}
base.firstContentFrame = "page"
base.options = {}

function base:_init (options)
  if not options then options = {} end
  setmetatable(self.options, {
    __newindex = function (_, key, value)
      if type(value) ~= "function" then
        SU.error("Option "..key.." must be declared as a setter function before being set")
      end
    end,
    __index = function (_, key)
      SU.error("Attempted to get/set a class option '" .. key .. "' that isn’t registered.")
    end
  })
  local legacy = self._deprecator(options)
  if legacy then return legacy end
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
    self.options[k](v)
  end
  SILE.outputter:init(self)
  self:declareSettings()
  self:registerCommands()
  self:declareFrames(self.defaultFrameset)
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames[self.firstContentFrame]
  for _, f in ipairs(self.deferredInit) do f() end
  SILE.typesetter:registerPageEndHook(function ()
    if SU.debugging("frames") then
      for _, v in pairs(SILE.frames) do SILE.outputter:debugFrame(v) end
    end
  end)
  self._initialized = true
end

-- This is essentially of a self destruct mechanism that monkey patches the old
-- stdlib object model definition to return a Penlight class constructor
-- instead of the old std.object model.
function base:_deprecator (options)
  if not options then options = {} end
  if options.id then
    -- The old std.object inheritence for classes called the base class with
    -- and arg of a table which had an ID. Since the new system doesn't have
    -- an ID arg, we can assume this is unported code. See also core/sile.lua
    -- for the actual deprecation mechanism for the old SILE.baseClass.
    SU.warn([[
      The inheritance system for SILE classes has been refactored using a
        different object model, please update your code as use of the old
        model will cause unexpected errors and will eventually be removed.
      ]])
    SU.deprecated("std.object x", "pl.class", "0.13.0", "0.14.0")
    options.id = nil
    local constructor = pl.class(self)
    pl.tablex.update(constructor, options)
    constructor._init = function(self_, options_)
      return self_:init(options_)
    end
    -- Regress to the legacy declareOption functionality
    self.legacyopts = {}
    rawset(constructor, "declareOption", function(self_, option, setter)
      self_.legacyopts[option] = setter
      self_.options[option] = function (value)
        if value then self_.legacyopts[option] = value end
        return self_.legacyopts[option]
      end
    end)
    return constructor
  end
end

function base:setOptions (options)
  for option, value in pairs(options) do
    if type(self.options[option]) == "function" then
      self.options[option](value)
    else
      SU.warn("Attempted to set undeclared class option "..option)
    end
  end
end

function base:declareOption (option, setter)
  rawset(self.options, option, setter)
end

function base.declareSettings (_)
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
end

function base:loadPackage (packname, args)
  local pack = require("packages." .. packname)
  self:initPackage(pack, args)
end

function base:initPackage (pack, args)
  if type(pack) == "table" then
    if pack.exports then pl.tablex.update(self, pack.exports) end
    if type(pack.init) == "function" then
      table.insert(self.deferredInit, function () pack.init(self, args) end)
      if self._initialized then
        pack.init(self, args)
      end
    end
  end
end

base.registerCommands = function (_)

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

end

function base:initialFrame ()
  SILE.documentState.thisPageTemplate = pl.tablex.deepcopy(self.pageTemplate)
  SILE.frames = { page = SILE.frames.page }
  for k, v in pairs(SILE.documentState.thisPageTemplate.frames) do
    SILE.frames[k] = v
  end
  SILE.documentState.thisPageTemplate.firstContentFrame:invalidate()
  return SILE.documentState.thisPageTemplate.firstContentFrame
end

function base:declareFrame (id, spec)
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
end

function base:declareFrames (specs)
  if specs then
    for k, v in pairs(specs) do self:declareFrame(k, v) end
  end
end

-- WARNING: not called as class method
function base.newPar (typesetter)
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
end

-- WARNING: not called as class method
function base.endPar (typesetter)
  typesetter:pushVglue(SILE.settings.get("document.parskip"))
  if SILE.settings.get("current.hangIndent") then
    SILE.settings.set("current.hangIndent", nil)
    SILE.settings.set("linebreak.hangIndent", nil)
  end
  if SILE.settings.get("current.hangAfter") then
    SILE.settings.set("current.hangAfter", nil)
    SILE.settings.set("linebreak.hangAfter", nil)
  end
end

function base:newPage ()
  SILE.outputter:newPage()
  -- Any other output-routiney things will be done here by inheritors
  return self:initialFrame()
end

function base.endPage (_)
  SILE.typesetter.frame:leave()
  -- I'm trying to call up a new frame here, don't cause a page break in the current one
  -- SILE.typesetter:leaveHmode()
  -- Any other output-routiney things will be done here by inheritors
end

function base:finish ()
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
end

return base
