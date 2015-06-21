local lfs = require('lfs')

SILE.scratch.converters = {}

local register = function(sourceExt, targetExt, command)
  table.insert(SILE.scratch.converters, {
    sourceExt = sourceExt,
    targetExt = targetExt,
    command = command
  })
end

local applyConverter = function(source, converter)
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

  command = string.gsub(converter.command, "%$(%w+)", {
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

local checkConverters = function(source)
  for _, converter in ipairs(SILE.scratch.converters) do
    local extLen = string.len(converter.sourceExt)
    if ((string.len(source) > extLen) and
        (string.sub(source, -extLen) == converter.sourceExt)) then
      return applyConverter(source, converter)
    end
  end
  return source -- No conversion needed.
end

SILE.registerCommand("converters:register", function(o, c)
  register(o.from, o.to, o.command)
end)

SILE.registerCommand("converters:check", function(o, c)
  checkConverters(o.source)
end)

local function extendCommand(name, f)
  -- Wrap an existing command
  local original = SILE.Commands[name]
  if(original) then
    SILE.Commands[name] = function(options, content)
      f(options, content, original)
    end
  else
    SU.debug("converters", "Can not extend command "..name)
  end
end

extendCommand("include", function(o, c, original)
  local result = checkConverters(o.src)
  if(result~=nil) then
    o["src"] = result
    original(o, c)
  end
end)

extendCommand("img", function(o, c, original)
  local result = checkConverters(o.src)
  if(result~=nil) then
    o["src"] = result
    original(o, c)
  end
end)

return {
  exports = {
    register= register,
    check= checkConverters
  }
}

