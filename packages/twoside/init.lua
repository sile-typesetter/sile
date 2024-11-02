local base = require("packages.base")

local package = pl.class(base)
package._name = "twoside"

local _odd = true

local mirrorMaster = function (_, existing, new)
   -- Frames in one master can't "see" frames in another, so we have to get creative
   -- XXX This knows altogether too much about the implementation of masters
   if not SILE.scratch.masters[new] then
      SILE.scratch.masters[new] = { frames = {} }
   end
   if not SILE.scratch.masters[existing] then
      SU.error("Can't find master " .. existing)
   end
   for name, frame in pairs(SILE.scratch.masters[existing].frames) do
      local newframe = pl.tablex.deepcopy(frame)
      if frame:isAbsoluteConstraint("right") then
         newframe.constraints.left = "100%pw-(" .. frame.constraints.right .. ")"
      end
      if frame:isAbsoluteConstraint("left") then
         newframe.constraints.right = "100%pw-(" .. frame.constraints.left .. ")"
      end
      SILE.scratch.masters[new].frames[name] = newframe
      if frame == SILE.scratch.masters[existing].firstContentFrame then
         SILE.scratch.masters[new].firstContentFrame = newframe
      end
   end
end

function package.oddPage (_)
   return _odd
end

local function switchPage (class)
   _odd = not class:oddPage()
   local nextmaster = _odd and class.oddPageMaster or class.evenPageMaster
   class:switchMaster(nextmaster)
end

local _deprecate = [[
   Directly calling master switch handling functions is no longer necessary. All
   the SILE core classes and anything inheriting from them will take care of this
   automatically using hooks. Custom classes that override the class:newPage()
   function may need to handle this in other ways. By calling this hook directly
   you are likely causing it to run twice and duplicate entries.
]]

local spread_counter = 0
local spreadHook = function ()
   spread_counter = spread_counter + 1
end

function package:_init (options)
   base._init(self)
   if not SILE.scratch.masters then
      SU.error("Cannot load twoside package before masters.")
   end
   self:export("oddPage", self.oddPage)
   self:export("mirrorMaster", mirrorMaster)
   self:export("switchPage", function ()
      SU.deprecated("class:switchPage", nil, "0.13.0", "0.15.0", _deprecate)
   end)
   self.class.oddPageMaster = options.oddPageMaster
   self.class.evenPageMaster = options.evenPageMaster
   self.class:registerPostinit(function (class)
      -- TODO: Refactor this to make mirroring a separate package / option
      if not SILE.scratch.masters[options.evenPageMaster] then
         class:mirrorMaster(options.oddPageMaster, options.evenPageMaster)
      end
   end)
   self.class:registerHook("newpage", spreadHook)
   self.class:registerHook("newpage", switchPage)
end

function package:registerCommands ()
   self:registerCommand("open-double-page", function ()
      SILE.call("open-spread", { double = false, odd = true, blank = false })
   end)

   self:registerCommand("open-spread-eject", function ()
      SILE.call("supereject")
   end)

   -- This is upstreamed from CaSILE. Similar to the original open-double-page,
   -- but can disable headers and folios on blank pages and allows opening the
   -- even side (with or without a leading blank).
   self:registerCommand("open-spread", function (options)
      local odd = SU.boolean(options.odd, true)
      local double = SU.boolean(options.double, true)
      local blank = SU.boolean(options.blank, true)
      local optionsMet = function ()
         return (not double or spread_counter > 1) and (odd == self.class:oddPage())
      end
      spread_counter = 0
      SILE.typesetter:leaveHmode()
      -- Output a box, then remove it and see where we are. Without adding
      -- content we can't prove on which page we would land because the page
      -- breaker *might* be stuffed almost full but still sitting on the last
      -- line happy to *maybe* accept more letter (but not a line). If this check
      -- gets us to the desired page nuke the vertical space so we don't leak it
      -- into the final content, otherwise just leave it be since we want to be
      -- forced to the next page anyway.
      SILE.call("hbox")
      SILE.typesetter:leaveHmode()
      table.remove(SILE.typesetter.state.nodes)
      if spread_counter == 1 and optionsMet() then
         SILE.typesetter.state.outputQueue = {}
         return
      end
      local startedattop = #SILE.typesetter.state.outputQueue == 2 and #SILE.typesetter.state.nodes == 0
      local spread_counter_at_start = spread_counter
      repeat
         if spread_counter > 0 then
            SILE.call("hbox")
            SILE.typesetter:leaveHmode()
            -- Note: before you think you can simplify this, make sure all the
            -- pages before chapter starts in the manual have headers if they have
            -- content and not if empty. Combined with the workaround for just
            -- barely full pages above it's tricky to get right.
            if blank and not (spread_counter == spread_counter_at_start and not startedattop) then
               SILE.scratch.headers.skipthispage = true
               SILE.call("nofoliothispage")
            end
         end
         SILE.call("open-spread-eject")
         SILE.typesetter:leaveHmode()
      until optionsMet()
   end)
end

package.documentation = [[
\begin{document}
A book-like class usually sets up left and right mirrored page masters.
The \autodoc:package{twoside} package is then responsible for swapping between the two left and right frames, running headers, and so on.
As it is normally loaded and initialized by a document class, its main function in mirroring master frames does not provide any user-serviceable parts.
It does supply a few user-facing commands for convenience.

The \autodoc:command{\open-double-page} ejects whatever page is currently being processed, then checks if it landed on an even page.
If so, it ejects another page to assure content starts on an odd page.

The \autodoc:command{\open-spread} is similar but a bit more tailored to use in book layouts.
By default, headers and folios will be suppressed automatically on any empty pages ejected, making them blank.
It can also accept three parameters.
The \autodoc:parameter{odd} parameter (default \code{true}) can be used to disable the opening page being odd, hence opening an even page spread.
The \autodoc:parameter{double} parameter (default \code{true}) can be used to always output at least one empty even page before the starting an odd page.
The \autodoc:parameter{blank} parameter (default \code{true}) can be used to not suppress headers and folios on otherwise empty pages.

Lastly the \autodoc:command{\open-spread-eject} command can be overridden to customize the output of blank pages.
By default it just runs \autodoc:command{\supereject}, but you could potentially add decorative content or other features in the otherwise empty space.
\end{document}
]]

return package
