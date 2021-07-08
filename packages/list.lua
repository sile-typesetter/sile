SILE.scratch.listStack = {}

SILE.settings.declare({
  name = "list.bullet.numbered",
  type = "string",
  default = ".",
  help = "Bullet used after a list item number"
})

-- TODO Not ready to handle RTL
SILE.settings.declare({
  name = "list.bullet.inset",
  type = "Length",
  default = SILE.length.parse("1.3em"),
  help = "The amount of space by which each level of the list is shifted"
})

local defaultBullets = {"•", "◦"}
for i = 1, #defaultBullets do
  SILE.settings.declare({
    name = "list.bullet."..i,
    type = "string",
    default = defaultBullets[i],
    help = "Bullet used for unordered list items at level "..i
  })
end

SILE.registerCommand("list", function (options, content)
  local level = #SILE.scratch.listStack + 1
  local topLevel = level == 1
  if topLevel then SILE.call("smallskip") else SILE.typesetter:leaveHmode() end

  local numbered = SU.boolean(options.numbered, SU.boolean(options.ordered, options.numbering ~= nil))
  local bullet = options.bullet
  if not bullet then
    if numbered then
      bullet = SILE.settings.get("list.bullet.numbered")
    else
      local setting = "list.bullet."..level
      -- If the level is too large, cycle bullet types
      if not SILE.settings.declarations[setting] then
        local mod = math.mod or math.fmod
        setting = "list.bullet." .. (1 + mod(level - 1, #defaultBullets))
      end

      bullet = SILE.settings.get(setting)
    end
  end
  local inset = options.inset and SILE.length.parse(options.inset) or SILE.settings.get("list.bullet.inset")

  SILE.scratch.listStack[level] = {
    nextNumber = 1,
    numbered = numbered,
    numbering = options.numbering or "arabic",
    bullet = bullet,
    skip = inset
  }
  local baseLSkip = SILE.settings.get("document.lskip")
  baseLSkip = baseLSkip and baseLSkip.width or SILE.length.new()
  SILE.settings.temporarily(function ()
    SILE.settings.set("document.lskip", SILE.nodefactory.newGlue({width = baseLSkip + inset}))
    SILE.settings.set("document.rskip", options.rskip and SILE.nodefactory.newGlue(options.rskip) or SILE.nodefactory.zeroGlue)
    SILE.settings.set("document.parindent", SILE.nodefactory.zeroGlue)
    SILE.process(content)
  end)
  SILE.scratch.listStack[#SILE.scratch.listStack] = nil

  if topLevel then SILE.call("smallskip") else SILE.typesetter:leaveHmode() end
  SILE.call("noindent") -- list does not create a new paragraph
end)

SILE.registerCommand("list:item", function (options, content)
  local settings = SILE.scratch.listStack[#SILE.scratch.listStack]
  local number = options.number or settings.nextNumber
  settings.nextNumber = number + 1

  local markerwidth = settings.skip
  SILE.call("kern", { width = tostring(markerwidth:negate()) })
  local box = SILE.call("hbox", {}, function ()
    if settings.numbered then
      SILE.typesetter:setpar(SILE.formatCounter({ value = number, display = settings.numbering or "arabic" }))
    end
    SILE.typesetter:setpar(settings.bullet)
  end)
  box.width = markerwidth

  SILE.process(content)
  if #SILE.scratch.listStack == 1 then SILE.call("smallskip") else SILE.call("par") end
end)

return { documentation = [[\begin{document}
Lists of items can be created with the \code{list} package. It consists of two main commands:
\command{\\list} and \command{\\list:item}.

\command{\\list} has following optional options:
\code{numbered} (or its alias \code{ordered}), a boolean determining whether numbers will be printed
before the bullet or not. Lists are unordered by default.
\code{bullet} a string with explicit bullet character to use.
\code{numbering} a string denoting the numbering system to use for ordered lists.
See the documentation of counters for possible values.
\code{lskip} width reserved for the bullets.

\command{\\list:item} has option \code{number}, to override the number of the item in case of numbered lists.
By default, the numbered list starts at 1 and each item has a number that is one bigger than of the previous one.

Lists can be arbitrarily nested.
\end{document}]] }