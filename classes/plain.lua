local base = require("classes.base")

local class = pl.class(base)
class._name = "plain"

class.defaultFrameset = {
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
class.firstContentFrame = "content"

local skips = {
  small = "3pt plus 1pt minus 1pt",
  med = "6pt plus 2pt minus 2pt",
  big = "12pt plus 4pt minus 4pt"
}

function class:_init (options)
  base._init(self, options)
  self:loadPackage("bidi")
  self:loadPackage("folio")
end

function class:declareOptions ()
  base.declareOptions(self)
  self:declareOption("direction", function (_, value)
    if value then
      SILE.documentState.direction = value
      SILE.settings:set("font.direction", value, true)
      for _, frame in pairs(self.defaultFrameset) do
        if not frame.direction then
          frame.direction = value
        end
      end
    end
    return SILE.documentState.direction
  end)
end

function class:setOptions (options)
  -- TODO: set a default direction here?
  base.setOptions(self, options)
end

function class:declareSettings ()
  base.declareSettings(self)
  for k, v in pairs(skips) do
    SILE.settings:declare({
        parameter = "plain." .. k .. "skipamount",
        type = "vglue",
        default = SILE.nodefactory.vglue(v),
        help = "The amount of a \\" .. k .. "skip"
      })
  end
end

function class:registerCommands ()

  SILE.classes.base.registerCommands(self)

  self:registerCommand("noindent", function (_, content)
    if #SILE.typesetter.state.nodes ~= 0 then
      SU.warn("\\noindent called after nodes already recieved in a paragraph, the setting will have no effect because the parindent (if any) has already been output")
    end
    SILE.settings:set("current.parindent", SILE.nodefactory.glue())
    SILE.process(content)
  end, "Do not add an indent to the start of this paragraph")

  self:registerCommand("neverindent", function (_, content)
    SILE.settings:set("current.parindent", SILE.nodefactory.glue())
    SILE.settings:set("document.parindent", SILE.nodefactory.glue())
    SILE.process(content)
  end, "Turn off all indentation")

  self:registerCommand("indent", function (_, content)
    SILE.settings:set("current.parindent", SILE.settings:get("document.parindent"))
    SILE.process(content)
  end, "Do add an indent to the start of this paragraph, even if previously told otherwise")

  for k, _ in pairs(skips) do
    self:registerCommand(k .. "skip", function (_, _)
      SILE.typesetter:leaveHmode()
      SILE.typesetter:pushExplicitVglue(SILE.settings:get("plain." .. k .. "skipamount"))
    end, "Skip vertically by a " .. k .. " amount")
  end

  self:registerCommand("hfill", function (_, _)
    SILE.typesetter:pushExplicitGlue(SILE.nodefactory.hfillglue())
  end, "Add a huge horizontal glue")

  self:registerCommand("vfill", function (_, _)
    SILE.typesetter:leaveHmode()
    SILE.typesetter:pushExplicitVglue(SILE.nodefactory.vfillglue())
  end, "Add huge vertical glue")

  self:registerCommand("hss", function (_, _)
    SILE.typesetter:initline()
    SILE.typesetter:pushGlue(SILE.nodefactory.hssglue())
    table.insert(SILE.typesetter.state.nodes, SILE.nodefactory.zerohbox())
  end, "Add glue which stretches and shrinks horizontally (good for centering)")

  self:registerCommand("vss", function (_, _)
    SILE.typesetter:pushExplicitVglue(SILE.nodefactory.vssglue())
  end, "Add glue which stretches and shrinks vertically")

  local _thinspacewidth = SILE.measurement(0.16667, "em")

  self:registerCommand("thinspace", function (_, _)
    SILE.call("glue", { width = _thinspacewidth })
  end)

  self:registerCommand("negthinspace", function (_, _)
    SILE.call("glue", { width = -_thinspacewidth })
  end)

  self:registerCommand("enspace", function (_, _)
    SILE.call("glue", { width = SILE.measurement(1, "en") })
  end)

  self:registerCommand("relax", function (_, _)
  end)

  self:registerCommand("enskip", function (_, _)
    SILE.call("enspace")
  end)

  local _quadwidth = SILE.measurement(1, "em")

  self:registerCommand("quad", function (_, _)
    SILE.call("glue", { width = _quadwidth })
  end)

  self:registerCommand("qquad", function (_, _)
    SILE.call("glue", { width = _quadwidth * 2 })
  end)

  self:registerCommand("slash", function (_, _)
    SILE.typesetter:typeset("/")
    SILE.call("penalty", { penalty = 50 })
  end)

  self:registerCommand("break", function (_, _)
    SILE.call("penalty", { penalty = -10000 })
  end, "Requests a frame break (if in vertical mode) or a line break (if in horizontal mode)")

  self:registerCommand("cr", function (_, _)
    SILE.call("hfill")
    SILE.call("break")
  end, "Fills a line with a stretchable glue and then requests a line break")

  -- Despite their name, in older versions, \framebreak and \pagebreak worked badly in horizontal
  -- mode. The former was a linebreak, and the latter did nothing. That was surely not intended.
  -- There are many ways, though to assume what's wrong or what the user's intent ought to be.
  -- We now warn, and terminate the paragraph, but to all extents this might be a wrong approach to
  -- reconsider at some point.

  self:registerCommand("framebreak", function (_, _)
    if not SILE.typesetter:vmode() then
      SU.warn("framebreak was not intended to work in horizontal mode. Behaviour may change in future versions")
    end
    SILE.call("penalty", { penalty = -10000, vertical = true })
  end, "Requests a frame break (switching to vertical mode if needed)")

  self:registerCommand("pagebreak", function (_, _)
    if not SILE.typesetter:vmode() then
      SU.warn("pagebreak was not intended to work in horizontal mode. Behaviour may change in future versions")
    end
    SILE.call("penalty", { penalty = -20000, vertical = true })
  end, "Requests a non-negotiable page break (switching to vertical mode if needed)")

  self:registerCommand("nobreak", function (_, _)
    SILE.call("penalty", { penalty = 10000 })
  end, "Inhibits a frame break (if in vertical mode) or a line break (if in horizontal mode)")

  self:registerCommand("novbreak", function (_, _)
    SILE.call("penalty", { penalty = 10000, vertical = true })
  end, "Inhibits a frame break (switching to vertical mode if needed)")

  self:registerCommand("allowbreak", function (_, _)
    SILE.call("penalty", { penalty = 0 })
  end, "Allows a page break (if in vertical mode) or a line break (if in horizontal mode) at a point would not be considered as suitable for breaking")

  -- THIS SEEMS BROKEN BUT THE COMMAND NOT MENTIONED IN THE SILE MANUAL
  -- In TeX, "\filbreak" compensates the vertical fill if no break actually occurs
  -- (\def\filbreak{\par\vfil\penalty-200\vfilneg)
  self:registerCommand("filbreak", function (_, _)
    SILE.call("vfill")
    SILE.call("penalty", { penalty = -200 })
  end, "I HAVE THE SAME NAME AS A TEX COMMAND BUT DON'T SEEM TO BE THE SAME")

  -- NOTE: TeX's "\goodbreak" does a \par first, so always switches to vertical mode.
  -- SILE differs here, allowing it both within a paragraph (line breaking) and between
  -- paragraphs (page breaking).
  self:registerCommand("goodbreak", function (_, _)
    SILE.call("penalty", { penalty = -500 })
  end, "Indicates a good potential point to break a frame (if in vertical mode) or a line (if in horizontal mode")

  self:registerCommand("eject", function (_, _)
    SILE.call("vfill")
    SILE.call("break")
  end, "Fills the page with stretchable vglue and then request a page break")

  self:registerCommand("supereject", function (_, _)
    SILE.call("vfill")
    SILE.call("penalty", { penalty = -20000 })
  end, "Fills the page with stretchable vglue and then requests a non-negotiable page break")

  self:registerCommand("justified", function (_, content)
    SILE.settings:set("document.rskip", nil)
    SILE.settings:set("document.spaceskip", nil)
    SILE.process(content)
    SILE.call("par")
  end)

  self:registerCommand("rightalign", function (_, content)
    SILE.call("raggedleft", {}, function ()
      SILE.process(content)
      SILE.call("par")
    end)
  end)

  self:registerCommand("em", function (_, content)
    SILE.call("font", { style = "Italic" }, content)
  end)

  self:registerCommand("strong", function (_, content)
    SILE.call("font", { weight = 700 }, content)
  end)

  self:registerCommand("nohyphenation", function (_, content)
    SILE.call("font", { language = "und" }, content)
  end)

  self:registerCommand("raggedright", function (_, content)
    SILE.call("ragged", { right = true }, content)
  end)

  self:registerCommand("raggedleft", function (_, content)
    SILE.call("ragged", { left = true }, content)
  end)

  self:registerCommand("quote", function (_, content)
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

  self:registerCommand("listitem", function (_, content)
    SILE.call("medskip")
    SILE.typesetter:typeset("• ")
    SILE.process(content)
    SILE.call("medskip")
  end)

  self:registerCommand("sloppy", function (_, _)
    SILE.settings:set("linebreak.tolerance", 9999)
  end)

  self:registerCommand("awful", function (_, _)
    SILE.settings:set("linebreak.tolerance", 10000)
  end)

  self:registerCommand("center", function (_, content)
    if #SILE.typesetter.state.nodes ~= 0 then
      SU.warn("\\center environment started after other nodes in a paragraph, may not center as expected")
    end
    SILE.settings:temporarily(function()
      SILE.settings:set("current.parindent", 0)
      SILE.settings:set("document.parindent", 0)
      SILE.call("ragged", { left = true, right = true }, content)
    end)
  end)

  self:registerCommand("ragged", function (options, content)
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

  self:registerCommand("hbox", function (_, content)
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

  self:registerCommand("vbox", function (options, content)
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

return class
