local base = SILE.baseClass
local plain = base { id = "plain" }

local classopts = {}
plain.declareOption = function (self, name, default)
  classopts[name] = default
  self.options[name] = function (value)
    if value then classopts[name] = value end
    return classopts[name]
  end
end

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

plain.options.direction = function (value)
  SILE.documentState.direction = value
  if value then
    for _, frame in pairs(plain.defaultFrameset) do
      if not frame.direction then
        frame.direction = value
      end
    end
  end
end

function plain:init ()
  self:declareFrames(self.defaultFrameset)
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames[self.firstContentFrame]
  self:loadPackage("folio")
  return base.init(self)
end

plain.endPage = function (self)
  self:outputFolio()
  return base.endPage(self)
end

SILE.registerCommand("noindent", function (_, content)
  if #SILE.typesetter.state.nodes ~= 0 then
    SU.warn("\\noindent called after nodes already recieved in a paragraph, the setting will have no effect because the parindent (if any) has already been output")
  end
  SILE.settings.set("current.parindent", SILE.nodefactory.glue())
  SILE.process(content)
end, "Do not add an indent to the start of this paragraph")

SILE.registerCommand("neverindent", function (_, content)
  SILE.settings.set("current.parindent", SILE.nodefactory.glue())
  SILE.settings.set("document.parindent", SILE.nodefactory.glue())
  SILE.process(content)
end, "Turn off all indentation")

SILE.registerCommand("indent", function (_, content)
  SILE.settings.set("current.parindent", SILE.settings.get("document.parindent"))
  SILE.process(content)
end, "Do add an indent to the start of this paragraph, even if previously told otherwise")

local skips = {
  small = "3pt plus 1pt minus 1pt",
  med = "6pt plus 2pt minus 2pt",
  big = "12pt plus 4pt minus 4pt"
}

for k, v in pairs(skips) do
  SILE.settings.declare({
      parameter = "plain." .. k .. "skipamount",
      type = "vglue",
      default = SILE.nodefactory.vglue(v),
      help = "The amount of a \\" .. k .. "skip"
    })
  SILE.registerCommand(k .. "skip", function (_, _)
    SILE.typesetter:leaveHmode()
    SILE.typesetter:pushExplicitVglue(SILE.settings.get("plain." .. k .. "skipamount"))
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

plain.registerCommands = function ()
  base.registerCommands()
  SILE.doTexlike([[\define[command=thinspace]{\glue[width=0.16667em]}%
\define[command=negthinspace]{\glue[width=-0.16667em]}%
\define[command=enspace]{\glue[width=0.5em]}%
\define[command=relax]{}%
\define[command=enskip]{\enspace}%
\define[command=quad]{\glue[width=1em]}%
\define[command=qquad]{\glue[width=2em]}%
\define[command=slash]{/\penalty[penalty=50]}%
\define[command=break]{\penalty[penalty=-10000]}%
\define[command=cr]{\hfill\break}%
\define[command=framebreak]{\break}%
\define[command=pagebreak]{\penalty[penalty=-20000]}%
\define[command=nobreak]{\penalty[penalty=10000]}%
\define[command=novbreak]{\penalty[penalty=10000,vertical=1]}%
\define[command=allowbreak]{\penalty[penalty=0]}%
\define[command=filbreak]{\vfill\penalty[penalty=-200]}%
\define[command=goodbreak]{\penalty[penalty=-500]}%
\define[command=eject]{\vfill\break}%
\define[command=supereject]{\vfill\penalty[penalty=-20000]}%
\define[command=justified]{\set[parameter=document.rskip]\set[parameter=document.spaceskip]{\process\par}}%
\define[command=rightalign]{\raggedleft{\process\par}}%
\define[command=em]{\font[style=Italic]{\process}}%
\define[command=strong]{\font[weight=700]{\process}}%
\define[command=nohyphenation]{\font[language=und]{\process}}%
\define[command=raggedright]{\ragged[right=true]{\process}}%
\define[command=raggedleft]{\ragged[left=true]{\process}}%
\define[command=quote]{\smallskip\par\set[parameter=document.lskip,value=2.5em]\set[parameter=document.rskip,value=2.5em]\font[size=0.8em]{\noindent\process}\par\set[parameter=document.lskip]\set[parameter="document.rskip"]\smallskip}%
\define[command=listitem]{\medskip{}• \process\medskip}%
\define[command=sloppy]{\set[parameter=linebreak.tolerance,value=9999]}%
\define[command=awful]{\set[parameter=linebreak.tolerance,value=10000]}%
]])
end

SILE.registerCommand("center", function (_, content)
  if #SILE.typesetter.state.nodes ~= 0 then
    SU.warn("\\center environment started after other nodes in a paragraph, may not center as expected")
  end
  SILE.settings.temporarily(function()
    SILE.settings.set("current.parindent", 0)
    SILE.settings.set("document.parindent", 0)
    SILE.call("ragged", { left = true, right = true }, content)
  end)
end)

SILE.registerCommand("ragged", function (options, content)
  SILE.settings.temporarily(function ()
    if SU.boolean(options.left, false) then SILE.settings.set("document.lskip", SILE.nodefactory.hfillglue()) end
    if SU.boolean(options.right, false) then SILE.settings.set("document.rskip", SILE.nodefactory.hfillglue()) end
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue())
    SILE.settings.set("document.parindent", SILE.nodefactory.glue())
    SILE.settings.set("document.spaceskip", SILE.length("1spc", 0, 0))
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
      outputYourself = function (self, typesetter, line)
        local _post = _rtl_pre_post(self, typesetter, line)
        local ox = typesetter.frame.state.cursorX
        local oy = typesetter.frame.state.cursorY
        SILE.outputter:setCursor(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
        for _, node in ipairs(self.value) do
          node:outputYourself(typesetter, line)
        end
        typesetter.frame.state.cursorX = ox
        typesetter.frame.state.cursorY = oy
        _post()
        if SU.debugging("hboxes") then SILE.outputter:debugHbox(self, self:scaledWidth(line)) end
      end
    })
  table.insert(SILE.typesetter.state.nodes, hbox)
  return hbox
end, "Compiles all the enclosed horizontal-mode material into a single hbox")

SILE.registerCommand("vbox", function (options, content)
  local vbox
  SILE.settings.temporarily(function ()
    if options.width then SILE.settings.set("typesetter.breakwidth", SILE.length(options.width)) end
    SILE.typesetter:pushState()
    SILE.process(content)
    SILE.typesetter:leaveHmode(1)
    vbox = SILE.pagebuilder:collateVboxes(SILE.typesetter.state.outputQueue)
    SILE.typesetter:popState()
  end)
  return vbox
end, "Compiles all the enclosed material into a single vbox")

SILE.require("packages/bidi")

return plain
