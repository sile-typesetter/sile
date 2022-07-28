local base = require("packages.base")

local package = pl.class(base)
package._name = "converters"

local lfs = require('lfs')

local applyConverter = function (source, converter)
  local extLen = string.len(converter.sourceExt)
  local targetFile = string.sub(source, 1, -extLen-1) .. converter.targetExt

  local sourceTime = lfs.attributes(source, "modification")

  if (sourceTime==nil) then
    SU.debug("converters", "Source file not found "..source)
    return nil -- source not found
  end

  local targetTime = lfs.attributes(targetFile, "modification")
  if((targetTime~=nil) and (targetTime>sourceTime)) then
    SU.debug("converters", "Source file already converted "..source)
    return targetFile -- already converted
  end

  local command = string.gsub(converter.command, "%$(%w+)", {
    SOURCE = source,
    TARGET = targetFile
  })

  local result = os.execute(command)
  if type(result) ~= "boolean" then result = (result == 0) end
  if result then
    SU.debug("converters", "Converted "..source.." to "..targetFile)
    return targetFile
  else
    return nil
  end
end

-- TODO Make this a standard utility function
local function extendCommand (name, func)
  -- Wrap an existing command
  local original = SILE.Commands[name]
  if original then
    SILE.Commands[name] = function (options, content)
      func(options, content, original)
    end
  else
    SU.debug("converters", "Can not extend command "..name)
  end
end

function package.register (_, sourceExt, targetExt, command)
  table.insert(SILE.scratch.converters, {
    sourceExt = sourceExt,
    targetExt = targetExt,
    command = command
  })
end

function package.checkConverters (_, source)
  for _, converter in ipairs(SILE.scratch.converters) do
    local extLen = string.len(converter.sourceExt)
    if ((string.len(source) > extLen) and
        (string.sub(source, -extLen) == converter.sourceExt)) then
      return applyConverter(source, converter)
    end
  end
  return source -- No conversion needed.
end

function package:_init ()
  base._init(self)
  if not SILE.scratch.converters then
    SILE.scratch.converters = {}
  end
  extendCommand("include", function (options, content, original)
    local result = self:checkConverters(options.src)
    if not result then
      options["src"] = result
      original(options, content)
    end
  end)
  extendCommand("img", function (options, content, original)
    local result = self:checkConverters(options.src)
    if not result then
      options["src"] = result
      original(options, content)
    end
  end)
  self:deprecatedExport("register", self.register)
  self:deprecatedExport("checkConverters", self.checkConverters)
end

function package:registerCommands ()

  self.class:registerCommand("converters:register", function (options, _)
    self:register(options.from, options.to, options.command)
  end)

  self.class:registerCommand("converters:check", function (options, _)
    self:checkConverters(options.source)
  end)

end


package.documentation = [[
\begin{document}
The \autodoc:package{converters} package allows you to register additional handlers to process included files and images.
That sounds a bit abstract, so it’s best explained by example.
Suppose you have a GIF image that you would like to include in your document.
You read the documentation for the \autodoc:package{image} package and you discover that sadly GIF images are not supported.
What \autodoc:package{converters} does is allow you to teach SILE how to get the GIF format into something that \em{is} supported.
We can use the ImageMagick toolkit to turn a GIF into a JPG, and JPGs are supported.

We do this by registering a converter with the \autodoc:command{\converters:register} command:

\begin{verbatim}
\line
\\use[module=packages.converters]
\\converters:register[from=.gif,to=.jpg,command=convert $SOURCE $TARGET]
\line
\end{verbatim}

And now it just magically works:

\begin{verbatim}
\line
\\img[src=hello.gif, width=50px]
\line
\end{verbatim}

This will execute the command \code{convert hello.gif hello.jpg} and include the converted \code{hello.jpg} file.

This trick also works for text file:

\begin{verbatim}
\line
\\converters:register[from=.md, to=.sil, command=pandoc -o $TARGET $SOURCE]

\\include[src=document.md]
\line
\end{verbatim}
\end{document}
]]

return package
