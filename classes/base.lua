--- SILE document class interface.
-- @interfaces classes

local class = pl.class()
class.type = "class"
class._name = "base"

class._initialized = false
class.deferredLegacyInit = {}
class.deferredInit = {}
class.pageTemplate = { frames = {}, firstContentFrame = nil }
class.defaultFrameset = {}
class.firstContentFrame = "page"
class.options = setmetatable({}, {
    _opts = {},
    __newindex = function (self, key, value)
      local opts = getmetatable(self)._opts
      if type(opts[key]) == "function" then
        opts[key](class, value)
      elseif type(value) == "function" then
        opts[key] = value
      elseif type(key) == "number" then
        return
      else
        SU.error("Attempted to set an undeclared class option '" .. key .. "'")
      end
    end,
    __index = function (self, key)
      if key == "super" then return nil end
      if type(key) == "number" then return nil end
      local opt = getmetatable(self)._opts[key]
      if type(opt) == "function" then
        return opt(class)
      elseif opt then
        return opt
      else
        SU.error("Attempted to get an undeclared class option '" .. key .. "'")
      end
    end
  })
class.hooks = {
  newpage = {},
  endpage = {},
  finish = {},
}

class.packages = {}

function class:_init (options)
  SILE.scratch.half_initialized_class = self
  if self == options then options = {} end
  SILE.languageSupport.loadLanguage('und') -- preload for unlocalized fallbacks
  self:declareOptions()
  self:registerRawHandlers()
  self:declareSettings()
  self:registerCommands()
  self:setOptions(options)
  self:declareFrames(self.defaultFrameset)
  self:registerPostinit(function (self_)
      -- In the event no packages have called \language explicitly or otherwise triggerend the language loader, at this
      -- point we'll have a language *setting* but not actually have loaded the language. We put it off as long as we
      -- could in case the user changed the default document language and we didn't need to load the system default one,
      -- but that time has come at gone at this point. Make sure we've loaded somethnig...
      local lang = SILE.settings:get("document.language")
      SILE.languageSupport.loadLanguage(lang)
      if type(self.firstContentFrame) == "string" then
        self_.pageTemplate.firstContentFrame = self_.pageTemplate.frames[self_.firstContentFrame]
      end
      local frame = self_:initialFrame()
      SILE.typesetter = SILE.typesetters.base(frame)
      SILE.typesetter:registerPageEndHook(function ()
        SU.debug("frames", function ()
          for _, v in pairs(SILE.frames) do SILE.outputter:debugFrame(v) end
          return "Drew debug outlines around frames"
        end)
      end)
    end)
end

function class:_post_init ()
  self._initialized = true
  for i, func in ipairs(self.deferredInit) do
    func(self)
    self.deferredInit[i] = nil
  end
  SILE.scratch.half_initialized_class = nil
end

function class:setOptions (options)
  options = options or {}
  -- Classes that add options with dependencies should explicitly handle them, then exempt them from furthur processing.
  -- The landscape and crop related options are handled explicitly before papersize, then the "rest" of options that are not interdependent.
  self.options.landscape = SU.boolean(options.landscape, false)
  options.landscape = nil
  self.options.papersize = options.papersize or "a4"
  options.papersize = nil
  self.options.bleed = options.bleed or "0"
  options.bleed = nil
  self.options.sheetsize = options.sheetsize or nil
  options.sheetsize = nil
  for option, value in pairs(options) do
    self.options[option] = value
  end
end

function class:declareOption (option, setter)
  rawset(getmetatable(self.options)._opts, option, nil)
  self.options[option] = setter
end

function class:declareOptions ()
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
  self:declareOption("landscape", function(_, landscape)
    if landscape then
      self.landscape = landscape
    end
    return self.landscape
  end)
  self:declareOption("papersize", function (_, size)
    if size then
      self.papersize = size
      SILE.documentState.paperSize = SILE.papersize(size, self.options.landscape)
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
  self:declareOption("sheetsize", function (_, size)
    if size then
      self.sheetsize = size
      SILE.documentState.sheetSize = SILE.papersize(size, self.options.landscape)
      if SILE.documentState.sheetSize[1] < SILE.documentState.paperSize[1]
        or SILE.documentState.sheetSize[2] < SILE.documentState.paperSize[2] then
        SU.error("Sheet size shall not be smaller than the paper size")
      end
      if SILE.documentState.sheetSize[1] < SILE.documentState.paperSize[1] + SILE.documentState.bleed then
        SU.debug("frames", "Sheet size width augmented to take page bleed into account")
        SILE.documentState.sheetSize[1] = SILE.documentState.paperSize[1] + SILE.documentState.bleed
      end
      if SILE.documentState.sheetSize[2] < SILE.documentState.paperSize[2] + SILE.documentState.bleed then
        SU.debug("frames", "Sheet size height augmented to take page bleed into account")
        SILE.documentState.sheetSize[2] = SILE.documentState.paperSize[2] + SILE.documentState.bleed
      end
    else
      return self.sheetsize
    end
   end)
  self:declareOption("bleed", function (_, dimen)
    if dimen then
      self.bleed = dimen
      SILE.documentState.bleed = SU.cast("measurement", dimen):tonumber()
    end
    return self.bleed
  end)
end

function class.declareSettings (_)
  SILE.settings:declare({
    parameter = "current.parindent",
    type = "glue or nil",
    default = nil,
    help = "Glue at start of paragraph"
  })
  SILE.settings:declare({
    parameter = "current.hangIndent",
    type = "measurement or nil",
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

function class:loadPackage (packname, options, reload)
  local pack
  -- Allow loading by injecting whole packages as-is, otherwise try to load it with the usual packages path.
  if type(packname) == "table" then
    pack, packname = packname, packname._name
  elseif type(packname) == "nil" or packname == "nil" or pl.stringx.strip(packname) == "" then
    SU.error(("Attempted to load package with an invalid packname '%s'"):format(packname))
  else
    pack = require(("packages.%s"):format(packname))
    if pack._name ~= packname then
      SU.error(("Loaded module name '%s' does not match requested name '%s'"):format(pack._name, packname))
    end
  end
  SILE.packages[packname] = pack
  if type(pack) == "table" and pack.type == "package" then -- current package api
    if self.packages[packname] then
      -- If the same package name has been loaded before, we might be loading a modified version of the same package or
      -- we might be re-loading the same package, or we might just be doubling up work because somebody called us twice.
      -- The package itself should take care of the difference between load and reload based on the reload flag here,
      -- but in addition to that we also want to avoid creating a new instance. We want to run the intitializer from the
      -- (possibly different) new module, but not create a new instance ID and loose any connections it made.
      -- To do this we add a create function that returns the current instance. This brings along the _initialized flag
      -- and of course anything else already setup and running.
      local current_instance = self.packages[packname]
      pack._create = function () return current_instance end
      pack(options, true)
    else
      self.packages[packname] = pack(options, reload)
    end
  else -- legacy package
    self:initPackage(pack, options)
  end
end

function class:reloadPackage (packname, options)
  return self:loadPackage(packname, options, true)
end

function class:initPackage (pack, options)
  SU.deprecated("class:initPackage(options)", "package(options)", "0.14.0", "0.16.0", [[
  This package appears to be a legacy format package. It returns a table
  an expects SILE to guess a bit about what to do. New packages inherit
  from the base class and have a constructor function (_init) that
  automatically handles setup.]])
  if type(pack) == "table" then
    if pack.exports then pl.tablex.update(self, pack.exports) end
    if type(pack.declareSettings) == "function" then
      pack.declareSettings(self)
    end
    if type(pack.registerRawHandlers) == "function" then
      pack.registerRawHandlers(self)
    end
    if type(pack.registerCommands) == "function" then
      pack.registerCommands(self)
    end
    if type(pack.init) == "function" then
      self:registerPostinit(pack.init, options)
    end
  end
end

function class:registerLegacyPostinit (func, options)
  if self._initialized then return func(self, options) end
  table.insert(self.deferredLegacyInit, function (_)
      func(self, options)
    end)
end

function class:registerPostinit (func, options)
  if self._initialized then return func(self, options) end
  table.insert(self.deferredInit, function (_)
      func(self, options)
    end)
end

function class:registerHook (category, func)
  for _, func_ in ipairs(self.hooks[category]) do
    if func_ == func then
      return
      --[[ See https://github.com/sile-typesetter/sile/issues/1531
      return SU.warn("Attempted to set the same function hook twice, probably unintended, skipping.")
      -- If the same function signature is already set a package is probably being
      -- re-initialized. Ditch the first instance of the hook so that it runs in
      -- the order of last initialization.
      self.hooks[category][_] = nil
      ]]
    end
  end
  table.insert(self.hooks[category], func)
end

function class:runHooks (category, options)
  for _, func in ipairs(self.hooks[category]) do
    SU.debug("classhooks", "Running hook from", category, options and "with options #" .. #options)
    func(self, options)
  end
end

--- Register a function as a SILE command.
-- Takes any Lua function and registers it for use as a SILE command (which will in turn be used to process any content
-- nodes identified with the command name.
--
-- Note that this should only be used to register commands supplied directly by a document class. A similar method is
-- available for packages, `packages:registerCommand`.
-- @tparam string name Name of cammand to register.
-- @tparam function func Callback function to use as command handler.
-- @tparam[opt] nil|string help User friendly short usage string for use in error messages, documentation, etc.
-- @tparam[opt] nil|string pack Information identifying the module registering the command for use in error and usage
-- messages. Usually auto-detected.
-- @see SILE.packages:registerCommand
function class.registerCommand (_, name, func, help, pack)
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

function class.registerRawHandler (_, format, callback)
  SILE.rawHandlers[format] = callback
end

function class:registerRawHandlers ()

  self:registerRawHandler("text", function (_, content)
    SILE.settings:temporarily(function()
      SILE.settings:set("typesetter.parseppattern", "\n")
      SILE.settings:set("typesetter.obeyspaces", true)
      SILE.typesetter:typeset(content[1])
    end)
  end)

end

local function packOptions (options)
  local relevant = pl.tablex.copy(options)
  relevant.src = nil
  relevant.format = nil
  relevant.module = nil
  relevant.require = nil
  return relevant
end

function class:registerCommands ()

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

  self:registerCommand("define", function (options, content)
    SU.required(options, "command", "defining command")
    if type(content) == "function" then
      -- A macro defined as a function can take no argument, so we register
      -- it as-is.
      self:registerCommand(options["command"], content)
      return
    elseif options.command == "process" then
      SU.warn("Did you mean to re-definine the `\\process` macro? That probably won't go well.")
    end
    self:registerCommand(options["command"], function (_, inner_content)
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
  self:registerCommand("noop", function (_, content)
    SILE.process(content)
  end)

  -- The document (SIL) or sile (XML) command is always the sigular leaf at the
  -- top level of our AST. The work you might expect to see happen here is
  -- actually handled by SILE.inputter:classInit() before we get here, so these
  -- are just pass through functions. Theoretically, this could be a useful
  -- point to hook into-especially for included documents.
  self:registerCommand("document", function (_, content)
    SILE.process(content)
  end)
  self:registerCommand("sile", function (_, content)
    SILE.process(content)
  end)

  self:registerCommand("comment", function (_, _)
  end, "Ignores any text within this command's body.")

  self:registerCommand("process", function ()
    SU.error("Encountered unsubstituted \\process.")
  end, "Within a macro definition, processes the contents of the macro body.")

  self:registerCommand("script", function (options, content)
    local packopts = packOptions(options)
    local function _deprecated (original, suggested)
      SU.deprecated("\\script", "\\lua or \\use", "0.15.0", "0.16.0", ([[
      The \script function has been deprecated. It was overloaded to mean
      too many different things and more targeted tools were introduced in
      SILE v0.14.0. To load 3rd party modules designed for use with SILE,
      replace \script[src=...] with \use[module=...]. To run arbitrary Lua
      code inline use \lua{}, optionally with a require= parameter to load
      a (non-SILE) Lua module using the Lua module path or src= to load a
      file by file path.

      For this use case consider replacing:

          %s

      with:

          %s
      ]]):format(original, suggested))
    end
    if SU.ast.hasContent(content) then
      _deprecated("\\script{...}", "\\lua{...}")
      return SILE.processString(content[1], options.format or "lua", nil, packopts)
    elseif options.src then
      local module = options.src:gsub("%/", ".")
      local original = (("\\script[src=%s]"):format(options.src))
      local result = SILE.require(options.src)
      local suggested = (result._name and "\\use[module=%s]" or "\\lua[require=%s]"):format(module)
      _deprecated(original, suggested)
      return result
    else
      SU.error("\\script function requires inline content or a src file path")
      return SILE.processString(content[1], options.format or "lua", nil, packopts)
    end
  end, "Runs lua code. The code may be supplied either inline or using src=...")

  self:registerCommand("include", function (options, content)
    local packopts = packOptions(options)
    if SU.ast.hasContent(content) then
      local doc = SU.ast.contentToString(content)
      return SILE.processString(doc, options.format, nil, packopts)
    elseif options.src then
      return SILE.processFile(options.src, options.format, packopts)
    else
      SU.error("\\include function requires inline content or a src file path")
    end
  end, "Includes a content file for processing.")

  self:registerCommand("lua", function (options, content)
    local packopts = packOptions(options)
    if SU.ast.hasContent(content) then
      local doc = SU.ast.contentToString(content)
      return SILE.processString(doc, "lua", nil, packopts)
    elseif options.src then
      return SILE.processFile(options.src, "lua", packopts)
    elseif options.require then
      local module = SU.required(options, "require", "lua")
      return require(module)
    else
      SU.error("\\lua function requires inline content or a src file path or a require module name")
    end
  end, "Run Lua code. The code may be supplied either inline, using require=... for a Lua module, or using src=... for a file path")

  self:registerCommand("sil", function (options, content)
    local packopts = packOptions(options)
    if SU.ast.hasContent(content) then
      local doc = SU.ast.contentToString(content)
      return SILE.processString(doc, "sil")
    elseif options.src then
      return SILE.processFile(options.src, "sil", packopts)
    else
      SU.error("\\sil function requires inline content or a src file path")
    end
  end, "Process sil content. The content may be supplied either inline or using src=...")

  self:registerCommand("xml", function (options, content)
    local packopts = packOptions(options)
    if SU.ast.hasContent(content) then
      local doc = SU.ast.contentToString(content)
      return SILE.processString(doc, "xml", nil, packopts)
    elseif options.src then
      return SILE.processFile(options.src, "xml", packopts)
    else
      SU.error("\\xml function requires inline content or a src file path")
    end
  end, "Process xml content. The content may be supplied either inline or using src=...")

  self:registerCommand("use", function (options, content)
    local packopts = packOptions(options)
    if content[1] and string.len(content[1]) > 0 then
      local doc = SU.ast.contentToString(content)
      SILE.processString(doc, "lua", nil, packopts)
    else
      if options.src then
        SU.warn("Use of 'src' with \\use is discouraged because some of it's path handling\n  will eventually be deprecated. Use 'module' instead when possible.")
        SILE.processFile(options.src, "lua", packopts)
      else
        local module = SU.required(options, "module", "use")
        SILE.use(module, packopts)
      end
    end
  end, "Load and initialize a SILE module (can be a package, a shaper, a typesetter, or whatever). Use module=... to specif what to load or include module code inline.")

  self:registerCommand("raw", function (options, content)
    local rawtype = SU.required(options, "type", "raw")
    local handler = SILE.rawHandlers[rawtype]
    if not handler then SU.error("No inline handler for '"..rawtype.."'") end
    handler(options, content)
  end, "Invoke a raw passthrough handler")

  self:registerCommand("pagetemplate", function (options, content)
    SILE.typesetter:pushState()
    SILE.documentState.thisPageTemplate = { frames = {} }
    SILE.process(content)
    SILE.documentState.thisPageTemplate.firstContentFrame = SILE.getFrame(options["first-content-frame"])
    SILE.typesetter:initFrame(SILE.documentState.thisPageTemplate.firstContentFrame)
    SILE.typesetter:popState()
  end, "Defines a new page template for the current page and sets the typesetter to use it.")

  self:registerCommand("frame", function (options, _)
    SILE.documentState.thisPageTemplate.frames[options.id] = SILE.newFrame(options)
  end, "Declares (or re-declares) a frame on this page.")

  self:registerCommand("penalty", function (options, _)
    if SU.boolean(options.vertical, false) and not SILE.typesetter:vmode() then
      SILE.typesetter:leaveHmode()
    end
    if SILE.typesetter:vmode() then
      SILE.typesetter:pushVpenalty({ penalty = tonumber(options.penalty) })
    else
      SILE.typesetter:pushPenalty({ penalty = tonumber(options.penalty) })
    end
  end, "Inserts a penalty node. Option is penalty= for the size of the penalty.")

  self:registerCommand("discretionary", function (options, _)
    local discretionary = SILE.types.node.discretionary({})
    if options.prebreak then
      local hbox = SILE.typesetter:makeHbox({ options.prebreak })
      discretionary.prebreak = { hbox }
    end
    if options.postbreak then
      local hbox = SILE.typesetter:makeHbox({ options.postbreak })
      discretionary.postbreak = { hbox }
    end
    if options.replacement then
      local hbox = SILE.typesetter:makeHbox({ options.replacement })
      discretionary.replacement = { hbox }
    end
    table.insert(SILE.typesetter.state.nodes, discretionary)
  end, "Inserts a discretionary node.")

  self:registerCommand("glue", function (options, _)
    local width = SU.cast("length", options.width):absolute()
    SILE.typesetter:pushGlue(width)
  end, "Inserts a glue node. The width option denotes the glue dimension.")

  self:registerCommand("kern", function (options, _)
    local width = SU.cast("length", options.width):absolute()
    SILE.typesetter:pushHorizontal(SILE.types.node.kern(width))
  end, "Inserts a glue node. The width option denotes the glue dimension.")

  self:registerCommand("skip", function (options, _)
    options.discardable = SU.boolean(options.discardable, false)
    options.height = SILE.types.length(options.height):absolute()
    SILE.typesetter:leaveHmode()
    if options.discardable then
      SILE.typesetter:pushVglue(options)
    else
      SILE.typesetter:pushExplicitVglue(options)
    end
  end, "Inserts vertical skip. The height options denotes the skip dimension.")

  self:registerCommand("par", function (_, _)
    SILE.typesetter:endline()
  end, "Ends the current paragraph.")

end

function class:initialFrame ()
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

function class:declareFrame (id, spec)
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

function class:declareFrames (specs)
  if specs then
    for k, v in pairs(specs) do self:declareFrame(k, v) end
  end
end

-- WARNING: not called as class method
function class.newPar (typesetter)
  local parindent = SILE.settings:get("current.parindent") or SILE.settings:get("document.parindent")
  -- See https://github.com/sile-typesetter/sile/issues/1361
  -- The parindent *cannot* be pushed non-absolutized, as it may be evaluated
  -- outside the (possibly temporary) setting scope where it was used for line
  -- breaking.
  -- Early absolutization can be problematic sometimes, but here we do not
  -- really have the choice.
  -- As of problematic cases, consider a parindent that would be defined in a
  -- frame-related unit (%lw, %fw, etc.). If a frame break occurs and the next
  -- frame has a different width, the parindent won't be re-evaluated in that
  -- new frame context. However, defining a parindent in such a unit is quite
  -- unlikely. And anyway pushback() has plenty of other issues.
  typesetter:pushGlue(parindent:absolute())
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
function class.endPar (typesetter)
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

function class:newPage ()
  SILE.outputter:newPage()
  self:runHooks("newpage")
  -- Any other output-routiney things will be done here by inheritors
  return self:initialFrame()
end

function class:endPage ()
  SILE.typesetter.frame:leave(SILE.typesetter)
  self:runHooks("endpage")
  -- I'm trying to call up a new frame here, don't cause a page break in the current one
  -- SILE.typesetter:leaveHmode()
  -- Any other output-routiney things will be done here by inheritors
end

function class:finish ()
  SILE.inputter:postamble()
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
  if SILE.typesetter and not SILE.typesetter:isQueueEmpty() then
    SU.error("Queues are not empty as expected after ending last page", true)
  end
  SILE.outputter:finish()
  self:runHooks("finish")
end

return class
