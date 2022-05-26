local base = require("classes.base")

local plain = pl.class(base)
plain._name = "plain"

plain.defaultFrameset = {
  content = {
    left = "5%pw",
    right = "95%pw",
    top = "5%ph",
    bottom = "top(footnotes)"
  },
  folio = {
    left = "left(content)",
    right = "right(content)",
    top = "bottom(footnotes)+2%ph",
    bottom = "97%ph"
  },
  footnotes = {
    left = "left(content)",
    right = "right(content)",
    height = "0",
    bottom = "90%ph"
  }
}
plain.firstContentFrame = "content"

function plain:_init (options)
  if self._legacy and not self._deprecated then return self:_deprecator(plain) end
  if not options then options = {} end
  self:declareOption("direction", function (_, value)
    if value then
      SILE.documentState.direction = value
      for _, frame in pairs(self.defaultFrameset) do
        if not frame.direction then
          frame.direction = value
        end
      end
    end
    return SILE.documentState.direction
  end)
  base._init(self, options)
  self:loadPackage("bidi")
  self:loadPackage("folio")
  -- Avoid calling this (yet) if we're the parent of some child class
  if self._name == "plain" then self:post_init() end
  return self
end

function plain:registerCommands ()

  SILE.classes.base.registerCommands(self)

  SILE.registerCommand("noindent", function (_, content)
    if #SILE.typesetter.state.nodes ~= 0 then
      SU.warn("\\noindent called after nodes already recieved in a paragraph, the setting will have no effect because the parindent (if any) has already been output")
    end
    SILE.settings:set("current.parindent", SILE.nodefactory.glue())
    SILE.process(content)
  end, "Do not add an indent to the start of this paragraph")

  SILE.registerCommand("neverindent", function (_, content)
    SILE.settings:set("current.parindent", SILE.nodefactory.glue())
    SILE.settings:set("document.parindent", SILE.nodefactory.glue())
    SILE.process(content)
  end, "Turn off all indentation")

  SILE.registerCommand("indent", function (_, content)
    SILE.settings:set("current.parindent", SILE.settings:get("document.parindent"))
    SILE.process(content)
  end, "Do add an indent to the start of this paragraph, even if previously told otherwise")

  local skips = {
    small = "3pt plus 1pt minus 1pt",
    med = "6pt plus 2pt minus 2pt",
    big = "12pt plus 4pt minus 4pt"
  }

  for k, v in pairs(skips) do
    SILE.settings:declare({
        parameter = "plain." .. k .. "skipamount",
        type = "vglue",
        default = SILE.nodefactory.vglue(v),
        help = "The amount of a \\" .. k .. "skip"
      })
    SILE.registerCommand(k .. "skip", function (_, _)
      SILE.typesetter:leaveHmode()
      SILE.typesetter:pushExplicitVglue(SILE.settings:get("plain." .. k .. "skipamount"))
    end, "Skip vertically by a " .. k .. " amount")
  end

  SILE.registerCommand("hfill", function (_, _)
    SILE.typesetter:pushExplicitGlue(SILE.nodefactory.hfillglue())
  end, "Add a huge horizontal glue")

  SILE.registerCommand("vfill", function (_, _)
    SILE.typesetter:leaveHmode()
    SILE.typesetter:pushExplicitVglue(SILE.nodefactory.vfillglue())
  end, "Add huge vertical glue")

  SILE.registerCommand("hss", function (_, _)
    SILE.typesetter:initline()
    SILE.typesetter:pushGlue(SILE.nodefactory.hssglue())
    table.insert(SILE.typesetter.state.nodes, SILE.nodefactory.zerohbox())
  end, "Add glue which stretches and shrinks horizontally (good for centering)")

  SILE.registerCommand("vss", function (_, _)
    SILE.typesetter:pushExplicitVglue(SILE.nodefactory.vssglue())
  end, "Add glue which stretches and shrinks vertically")

  local _thinspacewidth = SILE.measurement(0.16667, "em")

  SILE.registerCommand("thinspace", function (_, _)
    SILE.call("glue", { width = _thinspacewidth })
  end)

  SILE.registerCommand("negthinspace", function (_, _)
    SILE.call("glue", { width = -_thinspacewidth })
  end)

  SILE.registerCommand("enspace", function (_, _)
    SILE.call("glue", { width = SILE.measurement(1, "en") })
  end)

  SILE.registerCommand("relax", function (_, _)
  end)

  SILE.registerCommand("enskip", function (_, _)
    SILE.call("enspace")
  end)

  local _quadwidth = SILE.measurement(1, "em")

  SILE.registerCommand("quad", function (_, _)
    SILE.call("glue", { width = _quadwidth })
  end)

  SILE.registerCommand("qquad", function (_, _)
    SILE.call("glue", { width = _quadwidth * 2 })
  end)

  SILE.registerCommand("slash", function (_, _)
    SILE.typesetter:typeset("/")
    SILE.call("penalty", { penalty = 50 })
  end)

  SILE.registerCommand("break", function (_, _)
    SILE.call("penalty", { penalty = -10000 })
  end)

  SILE.registerCommand("cr", function (_, _)
    SILE.call("hfill")
    SILE.call("break")
  end)

  SILE.registerCommand("framebreak", function (_, _)
    SILE.call("break")
  end)

  SILE.registerCommand("pagebreak", function (_, _)
    SILE.call("penalty", { penalty = -20000 })
  end)

  SILE.registerCommand("nobreak", function (_, _)
    SILE.call("penalty", { penalty = 10000 })
  end)

  SILE.registerCommand("novbreak", function (_, _)
    SILE.call("penalty", { penalty = 10000, vertical = true })
  end)

  SILE.registerCommand("allowbreak", function (_, _)
    SILE.call("penalty", { penalty = 0 })
  end)

  SILE.registerCommand("filbreak", function (_, _)
    SILE.call("vfill")
    SILE.call("penalty", { penalty = -200 })
  end)

  SILE.registerCommand("goodbreak", function (_, _)
    SILE.call("penalty", { penalty = -500 })
  end)

  SILE.registerCommand("eject", function (_, _)
    SILE.call("vfill")
    SILE.call("break")
  end)

  SILE.registerCommand("supereject", function (_, _)
    SILE.call("vfill")
    SILE.call("penalty", { penalty = -20000 })
  end)

  SILE.registerCommand("justified", function (_, content)
    SILE.settings:set("document.rskip", nil)
    SILE.settings:set("document.spaceskip", nil)
    SILE.process(content)
    SILE.call("par")
  end)

  SILE.registerCommand("rightalign", function (_, content)
    SILE.call("raggedleft", {}, function ()
      SILE.process(content)
      SILE.call("par")
    end)
  end)

  SILE.registerCommand("em", function (_, content)
    SILE.call("font", { style = "Italic" }, content)
  end)

  SILE.registerCommand("strong", function (_, content)
    SILE.call("font", { weight = 700 }, content)
  end)

  SILE.registerCommand("nohyphenation", function (_, content)
    SILE.call("font", { language = "und" }, content)
  end)

  SILE.registerCommand("raggedright", function (_, content)
    SILE.call("ragged", { right = true }, content)
  end)

  SILE.registerCommand("raggedleft", function (_, content)
    SILE.call("ragged", { left = true }, content)
  end)

  SILE.registerCommand("quote", function (_, content)
    SILE.call("smallskip")
    SILE.call("par")
    local margin = SILE.measurement(2.5, "em")
    SILE.settings:set("document.lskip", margin)
    SILE.settings:set("document.lskip", margin)
    SILE.call("font", { size = SILE.measurement(0.8, "em") }, function ()
      SILE.call("noindent")
      SILE.process(content)
    end)
    SILE.call("par")
    SILE.settings:set("document.lskip", nil)
    SILE.settings:set("document.rskip", nil)
    SILE.call("smallskip")
  end)

  SILE.registerCommand("listitem", function (_, content)
    SILE.call("medskip")
    SILE.typesetter:typeset("• ")
    SILE.process(content)
    SILE.call("medskip")
  end)

  SILE.registerCommand("sloppy", function (_, _)
    SILE.settings:set("linebreak.tolerance", 9999)
  end)

  SILE.registerCommand("awful", function (_, _)
    SILE.settings:set("linebreak.tolerance", 10000)
  end)

  SILE.registerCommand("center", function (_, content)
    if #SILE.typesetter.state.nodes ~= 0 then
      SU.warn("\\center environment started after other nodes in a paragraph, may not center as expected")
    end
    SILE.settings:temporarily(function()
      SILE.settings:set("current.parindent", 0)
      SILE.settings:set("document.parindent", 0)
      SILE.call("ragged", { left = true, right = true }, content)
    end)
  end)

  SILE.registerCommand("ragged", function (options, content)
    SILE.settings:temporarily(function ()
      if SU.boolean(options.left, false) then SILE.settings:set("document.lskip", SILE.nodefactory.hfillglue()) end
      if SU.boolean(options.right, false) then SILE.settings:set("document.rskip", SILE.nodefactory.hfillglue()) end
      SILE.settings:set("typesetter.parfillskip", SILE.nodefactory.glue())
      SILE.settings:set("document.parindent", SILE.nodefactory.glue())
      SILE.settings:set("document.spaceskip", SILE.length("1spc", 0, 0))
      SILE.process(content)
      SILE.call("par")
    end)
  end)

  local _rtl_pre_post = function (box, typesetter, line)
    local advance = function () typesetter.frame:advanceWritingDirection(box:scaledWidth(line)) end
    if typesetter.frame:writingDirection() == "RTL" then
      advance()
      return function () end
    else
      return advance
    end
  end

  SILE.registerCommand("hbox", function (_, content)
    local index = #(SILE.typesetter.state.nodes)+1
    local recentContribution = {}
    SILE.process(content)
    local l = SILE.length()
    local h, d = SILE.length(), SILE.length()
    for i = index, #(SILE.typesetter.state.nodes) do
      local node = SILE.typesetter.state.nodes[i]
      if node.is_unshaped then
        local shape = node:shape()
        for _, attr in ipairs(shape) do
          recentContribution[#recentContribution+1] = attr
          h = attr.height > h and attr.height or h
          d = attr.depth > d and attr.depth or d
          l = l + attr:lineContribution():absolute()
        end
      else
        recentContribution[#recentContribution+1] = node
        l = l + node:lineContribution():absolute()
        h = node.height > h and node.height or h
        d = node.depth > d and node.depth or d
      end
      SILE.typesetter.state.nodes[i] = nil
    end
    local hbox = SILE.nodefactory.hbox({
        height = h,
        width = l,
        depth = d,
        value = recentContribution,
        outputYourself = function (self_, typesetter, line)
          local _post = _rtl_pre_post(self_, typesetter, line)
          local ox = typesetter.frame.state.cursorX
          local oy = typesetter.frame.state.cursorY
          SILE.outputter:setCursor(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
          for _, node in ipairs(self_.value) do
            node:outputYourself(typesetter, line)
          end
          typesetter.frame.state.cursorX = ox
          typesetter.frame.state.cursorY = oy
          _post()
          if SU.debugging("hboxes") then SILE.outputter:debugHbox(self_, self_:scaledWidth(line)) end
        end
      })
    table.insert(SILE.typesetter.state.nodes, hbox)
    return hbox
  end, "Compiles all the enclosed horizontal-mode material into a single hbox")

  SILE.registerCommand("vbox", function (options, content)
    local vbox
    SILE.settings:temporarily(function ()
      if options.width then SILE.settings:set("typesetter.breakwidth", SILE.length(options.width)) end
      SILE.typesetter:pushState()
      SILE.process(content)
      SILE.typesetter:leaveHmode(1)
      vbox = SILE.pagebuilder:collateVboxes(SILE.typesetter.state.outputQueue)
      SILE.typesetter:popState()
    end)
    return vbox
  end, "Compiles all the enclosed material into a single vbox")

end

function plain:endPage ()
  self:outputFolio()
  return base.endPage(self)
end

SILE.classes.plain = plain
return plain
