local base = pl.class()
base._name = "base"

base._initialized = false
base._legacy = false
base._deprecated = false
base.deferredLegacyInit = {}
base.deferredInit = {}
base.pageTemplate = { frames = {}, firstContentFrame = nil }
base.defaultFrameset = {}
base.firstContentFrame = "page"
base.options = setmetatable({}, {
    _opts = {},
    __newindex = function (self, key, value)
      local opts = getmetatable(self)._opts
      if type(opts[key]) == "function" then
        opts[key](base, value)
      elseif type(value) == "function" then
        opts[key] = value
      elseif type(key) == "number" then
        return nil
      else
        SU.error("Attempted to set an undeclared class option '" .. key .. "'")
      end
    end,
    __index = function (self, key)
      if key == "super" then return nil end
      if type(key) == "number" then return nil end
      local opt = getmetatable(self)._opts[key]
      if type(opt) == "function" then
        return opt(base)
      elseif opt then
        return opt
      else
        SU.error("Attempted to get an undeclared class option '" .. key .. "'")
      end
    end
  })
base.hooks = {
  newpage = {},
  endpage = {},
  finish = {},
}

-- Part of stdlib deprecation hack: class constructors in the new model should
-- *never* be called with an id. If it does we know somebody is using the
-- legacy model and setup shims to get them out of trouble. Notable we want to
-- skip the normal init process the first time around (and even walk it back).
-- Normal _init() will be called again later, possibly with legacy init() mixins.
function base:_create ()
  if type(self) == "table" and self.id then
    self._legacy = true
    self._name = self.id
    self.id = nil
  end
  return self
end

function base:_init (options)
  if self._legacy and not self._deprecated then return self:_deprecator(base) end
  if self == options then options = {} end
  self:declareOptions()
  self:registerCommands()
  self:declareSettings()
  self:setOptions(options)
  SILE.outputter:init(self)
  self:declareFrames(self.defaultFrameset)
  self:registerPostinit(function (self_)
      if type(self.firstContentFrame) == "string" then
        self_.pageTemplate.firstContentFrame = self_.pageTemplate.frames[self_.firstContentFrame]
      end
      local frame = self_:initialFrame()
      SILE.typesetter = SILE.defaultTypesetter(frame)
      SILE.typesetter:registerPageEndHook(function ()
        if SU.debugging("frames") then
          for _, v in pairs(SILE.frames) do SILE.outputter:debugFrame(v) end
        end
      end)
    end)
  return self
end

local mt

-- Penlight hook, currently only used to help shim stdlib based calls to the
-- new constructors.
function base:_post_init ()
  if self._legacy then
    setmetatable(self, mt)
  end
end

function base:start ()
  if self._legacy then
    for i, func in ipairs(self.deferredLegacyInit) do
      func(self)
      self.deferredLegacyInit[i] = nil
    end
  end
  self._initialized = true
  for i, func in ipairs(self.deferredInit) do
    func(self)
    self.deferredInit[i] = nil
  end
end

-- This is essentially of a self destruct mechanism that monkey patches the old
-- stdlib object model definition to return a Penlight class constructor
-- instead of the old std.object model.
function base:_deprecator (parent)
  local id = self._name
  self = pl.class(parent)
  self._name = id
  self._legacy = true
  SU.warn(string.format([[
    The document class inheritance system for SILE classes has been
      refactored using a different object model. Your class (%s), has been
      instantiated with a shim immitating the stdlib based model, but it is
      *not* fully backwards compatible, *will* cause unexpected errors, and
      *will* eventually be removed. Please update your code to use the new
      Penlight based inheritance model.

    ]], self._name))
  SU.deprecated("std.object", "pl.class", "0.13.0", "0.14.0")
  self.declareOption = function (self_, option, setter)
    if not getmetatable(self_.options)._opts[option] then
      if type(setter) ~= "function" then
        local default = setter
        setter = function (_, value)
          local k = "_legacy_option_" .. option
          if value then self_[k] = value end
          return function() return self_[k] end
        end
        setter(self_, default)
      end
      parent.declareOption(self_, option, setter)
    end
  end
  -- Legacy classes from old example code run declareFrame and loadPackage before instantializing,
  -- stash them in a post init callback instead so we have frames and a typesetter
  self.declareFrame = function (self_, id_, spec)
    self_:registerLegacyPostinit(function ()
      parent.declareFrame(self_, id_, spec)
    end)
    return self_
  end
  self.loadPackage = function (self_, packname, args)
    self_:registerLegacyPostinit(function ()
      parent.loadPackage(self_, packname, args)
    end)
    return self_
  end
  -- Just in case the legacy class calls this directly, make it a noop
  parent.init = function (self_) return self_ end
  self._init = function (self_, options_)
    if type(self_.init) == "function" then
      self_:registerLegacyPostinit(self_.init, options_)
    end
    parent._init(self_, options_)
    return self_
  end
  self._deprecated = true
  -- The function we are in (Penlight's constructor) is going to blow away the
  -- meta table after we return here so stash it and re-apply it on _post_init
  mt = getmetatable(self)
  return self
end

function base:setOptions (options)
  options = options or {}
  options.papersize = options.papersize or "a4"
  for option, value in pairs(options) do
    self.options[option] = value
  end
end

function base:declareOption (option, setter)
  self.options[option] = setter
end

function base:declareOptions ()
  self:declareOption("class", function (_, name)
    if name then
      if self._legacy then
        self._name = name
      elseif name ~= self._name then
        SU.error("Cannot change class name after instantiation, derive a new class instead.")
      end
    end
    return self._name
  end)
  self:declareOption("papersize", function (_, size)
    if size then
      self.papersize = size
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
    return self.papersize
  end)
end

function base.declareSettings (_)
  SILE.settings:declare({
    parameter = "current.parindent",
    type = "glue or nil",
    default = nil,
    help = "Glue at start of paragraph"
  })
  SILE.settings:declare({
    parameter = "current.hangIndent",
    type = "integer or nil",
    default = nil,
    help = "Size of hanging indent"
  })
  SILE.settings:declare({
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
    if type(pack.declareSettings) == "function" then
      pack.declareSettings(self)
    end
    if type(pack.registerCommands) == "function" then
      pack.registerCommands(self)
    end
    if type(pack.init) == "function" then
      self:registerPostinit(pack.init, args)
    end
  end
end

function base:registerLegacyPostinit (func, args)
  if self._initialized then return func(self, args) end
  table.insert(self.deferredLegacyInit, function (_)
      func(self, args)
    end)
end

function base:registerPostinit (func, args)
  if self._initialized then return func(self, args) end
  table.insert(self.deferredInit, function (_)
      func(self, args)
    end)
end

function base:registerHook (category, func)
  for _, func_ in ipairs(self.hooks[category]) do
    if func_ == func then
      return SU.warn("Attempted to set the same function hook twice, probably unintended, skipping.")
    end
  end
  table.insert(self.hooks[category], func)
end

function base:runHooks (category, args)
  for _, func in ipairs(self.hooks[category]) do
    SU.debug("classhooks", "Running hook from " .. category, args and "with args " .. #args)
    func(self, args)
  end
end

function base:registerCommands ()

  SILE.registerCommand("script", function (options, content)
    if options.src then
      local pack, _ = require(options.src)
      self:initPackage(pack)
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
  if not SILE.documentState.thisPageTemplate.firstContentFrame then
    SILE.documentState.thisPageTemplate.firstContentFrame = SILE.frames[self.firstContentFrame]
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
  typesetter:pushGlue(SILE.settings:get("current.parindent") or SILE.settings:get("document.parindent"))
  SILE.settings:set("current.parindent", nil)
  local hangIndent = SILE.settings:get("current.hangIndent")
  if hangIndent then
    SILE.settings:set("linebreak.hangIndent", hangIndent)
  end
  local hangAfter = SILE.settings:get("current.hangAfter")
  if hangAfter then
    SILE.settings:set("linebreak.hangAfter", hangAfter)
  end
end

-- WARNING: not called as class method
function base.endPar (typesetter)
  typesetter:pushVglue(SILE.settings:get("document.parskip"))
  if SILE.settings:get("current.hangIndent") then
    SILE.settings:set("current.hangIndent", nil)
    SILE.settings:set("linebreak.hangIndent", nil)
  end
  if SILE.settings:get("current.hangAfter") then
    SILE.settings:set("current.hangAfter", nil)
    SILE.settings:set("linebreak.hangAfter", nil)
  end
end

function base:newPage ()
  SILE.outputter:newPage()
  self:runHooks("newpage")
  -- Any other output-routiney things will be done here by inheritors
  return self:initialFrame()
end

function base:endPage ()
  SILE.typesetter.frame:leave(SILE.typesetter)
  self:runHooks("endpage")
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
    if SILE.typesetter then
      assert(SILE.typesetter:isQueueEmpty(), "queues not empty")
    end
  SILE.outputter:finish()
  self:runHooks("finish")
end

return base
