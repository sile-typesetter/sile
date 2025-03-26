local base = require("packages.base")

local package = pl.class(base)
package._name = "image"

function package:registerCommands ()
   self:registerCommand("img", function (options, _)
      SU.required(options, "src", "including image file")
      local width = SU.cast("measurement", options.width or 0):tonumber()
      local height = SU.cast("measurement", options.height or 0):tonumber()
      local pageno = SU.cast("integer", options.page or 1)
      local src = SILE.resolveFile(options.src) or SU.error("Couldn't find file " .. options.src)
      local box_width, box_height, _, _ = SILE.outputter:getImageSize(src, pageno)
      local sx, sy = 1, 1
      if width > 0 and height > 0 then
         sx, sy = box_width / width, box_height / height
      elseif width > 0 then
         sx = box_width / width
         sy = sx
      elseif height > 0 then
         sy = box_height / height
         sx = sy
      end
      SILE.typesetter:pushHbox({
         width = box_width / sx,
         height = box_height / sy,
         depth = 0,
         value = src,
         outputYourself = function (node, typesetter, _)
            SILE.outputter:drawImage(
               node.value,
               typesetter.frame.state.cursorX,
               typesetter.frame.state.cursorY - node.height,
               node.width,
               node.height,
               pageno
            )
            typesetter.frame:advanceWritingDirection(node.width)
         end,
      })
   end, "Inserts the image specified with the <src> option in a box of size <width> by <height>")
end

package.documentation = [[
\begin{document}
Loading the \autodoc:package{image} package gives you the \autodoc:command{\img} command, fashioned after the HTML equivalent.
It takes the following parameters: \autodoc:parameter{src=<file>} must be the path to an image file; you may also give \autodoc:parameter{height} and/or \autodoc:parameter{width} parameters to specify the output size of the image on the paper.
If the size parameters are not given, then the image will be output at its “natural” size, honoring its resolution if available.
The command also supports a \autodoc:parameter{page=<number>} option, to specify the selected page in formats supporting
several pages (such as PDF).

\begin{autodoc:note}
With the libtexpdf backend (the default), the images can be in JPEG, PNG, EPS, or PDF formats.
\end{autodoc:note}

Here is a 200x243 pixel image output with \autodoc:command{\img[src=documentation/gutenberg.png]}.
The image has a claimed resolution of 100 pixels per inch, so ends up being two inches (144pt) wide on the page:\par
\img[src=documentation/gutenberg.png]

\raggedright{
Here it is with (respectively)
\autodoc:command{\img[src=documentation/gutenberg.png,width=120pt]},
\autodoc:command{\img[src=documentation/gutenberg.png,height=200pt]}, and
\autodoc:command{\img[src=documentation/gutenberg.png,width=120pt,height=200pt]}:}

\img[src=documentation/gutenberg.png,width=120pt]
\img[src=documentation/gutenberg.png,height=200pt]
\img[src=documentation/gutenberg.png,width=120pt,height=200pt]

Notice that images are typeset on the baseline of a line of text, rather like a very big letter.
\end{document}
]]

return package
