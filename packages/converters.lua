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
    return nil -- source not found
  end

  local targetTime = lfs.attributes(targetFile, "modification")
  if((targetTime~=nil) and (targetTime>sourceTime)) then
    return targetFile -- already converted
  end

  command = string.gsub(converter.command, "%$(%w+)", {
    SOURCE = source,
    TARGET = targetFile
  })

  if(os.execute(command)) then
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
end

SILE.registerCommand("converters:register", function(o, c)
  register(o.from, o.to, o.command)
end)

SILE.registerCommand("converters:check", function(o, c)
  checkConverters(o.source)
end)

SILE.registerCommand("converters:include", function(o, c)
  local result = checkConverters(o.src)
  if(result~=nil) then
    SILE.call("include", {src=result})
  end
end)

return {
  exports = {
    register= register,
    check= checkConverters
  }
}

