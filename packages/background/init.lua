local base = require("packages.base")

local package = pl.class(base)
package._name = "background"

local background = {}

local knownAnchorSet = pl.Set({
   "center", "n", "ne", "e", "se", "s", "sw", "w", "nw"
})

local outputBackground = function ()
   local pagea = SILE.getFrame("page")
   local offset = SILE.documentState.bleed / 2

   -- Background color first:
   -- The image may not fully cover the area (depending on scaling
   -- and aspect ratio preservation), and may anyway have transparent areas.
   if background.bg then
      SILE.outputter:pushColor(background.bg)
      SILE.outputter:drawRule(
         pagea:left() - offset,
         pagea:top() - offset,
         pagea:width() + 2 * offset,
         pagea:height() + 2 * offset
      )
      SILE.outputter:popColor()
   end

   if background.src then
      local scale = background.scale
      local preserveaspect = background.preserveaspect
      local anchor = background.anchor

      -- Determine target image width and height fitting the area.
      local imgw, imgh = SILE.outputter:getImageSize(background.src, background.pageno)
      local w
      local h
      if scale then
         w = pagea:width() + 2 * offset
         h = pagea:height() + 2 * offset
         local xratio = w / imgw
         local yratio = h / imgh
         if preserveaspect then
            local scaleFactor = SU.min(xratio, yratio)
            w = imgw * scaleFactor
            h = imgh * scaleFactor
         else
            w = imgw * xratio
            h = imgh * yratio
         end
      else
         w = imgw
         h = imgh
      end
      -- Determine image position.
      -- When not scaling or preserving aspect ratio, we default to top-left
      -- since it does not matter (and we can ignore the anchor).
      local x = pagea:left() - offset
      local y = pagea:top() - offset
      local pw = pagea:width() + 2 * offset
      local ph = pagea:height() + 2 * offset
      -- Otherwise, we adjust the position based on the anchor.
      if not scale or preserveaspect then
         if anchor == "center" then
            x = x + (pw - w) / 2
            y = y + (ph - h) / 2
         elseif anchor == "n" then
            x = x + (pw - w) / 2
         elseif anchor == "ne" then
            x = x + (pw - w)
         elseif anchor == "e" then
            x = x + (pw - w)
            y = y + (ph - h) / 2
         elseif anchor == "se" then
            x = x + (pw - w)
            y = y + (ph - h)
         elseif anchor == "s" then
            x = x + (pw - w) / 2
            y = y + (ph - h)
         elseif anchor == "sw" then
            y = y + (ph - h)
         elseif anchor == "w" then
            y = y + (ph - h) / 2
         end
      end
      SILE.outputter:drawImage(
         background.src,
         x,
         y,
         w,
         h,
         background.pageno
      )
   end
   if not background.allpages then
      background.bg = nil
      background.src = nil
   end
end

function package:_init ()
   base._init(self)
   self.class:registerHook("newpage", outputBackground)
end

function package:registerCommands ()
   self:registerCommand("background", function (options, _)
      if SU.boolean(options.disable, false) then
         -- This option is certainly better than enforcing a white color.
         background.bg = nil
         background.src = nil
         return
      end
      local allpages = SU.boolean(options.allpages, true)
      local pageno = SU.cast("integer", options.page or 1)
      local color = options.color and SILE.types.color(options.color)
      local src = options.src

      background.pageno = pageno
      background.allpages = allpages
      if src then
         background.bg = color
         background.src = src and SILE.resolveFile(src) or SU.error("Couldn't find file " .. src)
         if options.anchor and not knownAnchorSet[options.anchor] then
            SU.error("Invalid anchor option for background: "..options.anchor)
         end
         background.anchor = options.anchor or "center"
         background.scale = SU.boolean(options.scale, true)
         background.preserveaspect = SU.boolean(options.preserveaspect, false)
      elseif color then
         background.bg = color
         background.src = nil
      else
         SU.error("background requires at least a color or an image option")
      end
      -- Changing the background immediately on the current page is what one may
      -- expect. But note that it may result in the previous background having been
      -- already output on that page (via the newpage hook), esp. when allpages=true
      -- (but also when the command is invoked multiple times on the same page).
      -- So we may end up with multiple backgrounds on the same page, if page breaks
      -- are not controlled carefully by the user.
      -- Whether this is a feature or a bug is open to debate.
      outputBackground()
   end, "Output a solid background color <color> or an image <src> on pages after initialization.")
end

package.documentation = [[
\begin{document}
\use[module=packages.background]
As its name implies, the \autodoc:package{background} package allows you to set the color of the page canvas background or to use a background image extending to the full page width and height.

The package provides a \autodoc:command{\background} command which usually requires at least one of the following parameters:
\begin{itemize}
\item{\autodoc:parameter{color=<color specification>} sets the background of the current and all following pages to that color. The color specification has the same syntax as specified in the \autodoc:package{color} package.}
\item{\autodoc:parameter{src=<file>} sets the background of the current and all following pages to the specified image. The latter will be scaled to the target dimension.}
\end{itemize}

The background color extends to the page trim area (“page bleed”) if the latter is defined.
This is to ensure that it indeed “bleeds” off the sides of the page, so as to avoid thin white lignes on an otherwise full color page when the paper sheet is cut to dimension but some pages are trimmed slightly more than others.

When using an image as background, the following options are also available:
\begin{itemize}
\item{\autodoc:parameter{page=<number>} specifies which page of a multi-page image file to use as background (default is 1).}
\item{\autodoc:parameter{scale=<boolean>} specifies whether to scale the image to fit the area (default is true).}
\item{\autodoc:parameter{preserveaspect=<boolean>} specifies whether to preserve the image aspect ratio when scaling (default is false).}
\item{\autodoc:parameter{anchor=<position>} specifies how to position the image when it does not fill the entire area.
  Accepted values are “center” (the default) and compass directions (“n”, “ne”, “sw”, etc.).}
\end{itemize}

The image anchors and its scaling are also based on the page bleed area.
When both a color and an image are specified, the color is drawn first, so that it shows through any transparent areas of the image or in case the image does not fully cover the page area (depending on scaling and aspect ratio preservation).

By default the background applies from the current page onward to all following pages.
If setting only the current page background is desired, an extra parameter \autodoc:parameter{allpages=false} can be passed.

\background[color=#e9d8ba,allpages=false]

So, for example, \autodoc:command{\background[color=#e9d8ba,allpages=false]} will set a sepia tone background on the current page.

Finally, the \autodoc:parameter{disable=true} parameter allows disabling the background on the following pages.
It may be useful when \autodoc:parameter{allpages} is active from a previous invocation.
\end{document}
]]

return package
