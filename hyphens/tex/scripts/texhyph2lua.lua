local function parsePattern (doc)
  local pattern = {}
  for line in doc:gmatch("[^\r\n]+") do
    local content = line:match("[^%%]*") -- ignore comments
    -- Patterns are space separated
    for word in content:gmatch("%S+") do
      table.insert(pattern, word)
    end
  end
  return pattern
end

local function parseTagLeftRight(doc, pos)
  local _, eg, tag = doc:find("[%s]*(%w+):[%s]*", pos)
  if eg then
    -- They might be in any order...
    if tag == "generation" or tag == "typesetting" then
      local _, e1, left = doc:find("left:%s*(%d+)", eg)
      local _, e2, right = doc:find("right:%s*(%d+)", eg)
      if left and right then
        return tag, left, right, e2 > e1 and e2 or e1
      end
    end
  end
end

local function parseFile (doc)
 -- Look for this block:
 -- % hyphenmins:
 -- %     generation:
 -- %         left:  2
 -- %         right: 2
 -- %     typesetting:
 -- %         left: 2
 -- %         right: 2
  local hyphenmins = {}
  local sp, ep = doc:find("%% hyphenmins:[%s]*%%")
  if sp then
    local tag, left, right, nep = parseTagLeftRight(doc, ep)
    if nep then
      hyphenmins[tag] = {left = left, right = right}
      ep = nep
      tag, left, right, nep = parseTagLeftRight(doc, ep)
      if nep then
        hyphenmins[tag] = {left = left, right = right}
      end
    end
  end

  -- Remove all comments
  doc = doc:gsub("%%[^\r\n]*", "")

  -- Look for patterns
  local patterns = doc:match("\\patterns{([^}]+)}")
  local t = {}
  if patterns then
    t = parsePattern(patterns)
  end
  -- Look for exceptions
  local hyphenations = doc:match("\\hyphenation{([^}]+)}")
  local e = {}
  if hyphenations then
    e = parsePattern(hyphenations)
  end
  -- Look for input -- TODO: Can there be more than one in standard files?
  local input = doc:match("\\input %s*([^%s]+)")
  if input then
    input = input:gsub("%.tex$", "")
  end
  return {hyphenmins = hyphenmins, patterns = t, exceptions = e, input = input}
end

local function convertPatternFile (filename)
  local file, err = io.open(filename)
  if not file then
    return nil, err
  end
  local doc = file:read("*a")
  file:close()
  return parseFile(doc)
end

local function writePatternFile (filename, data)
  local file, err = io.open(filename, "w")
  if not file then
    return nil, err
  end
  local headline = ("-- AUTOMATICALLY GENERATED FILE --\n")
  file:write(headline)
  file:write("return {\n")
  file:write("   hyphenmins = {\n")
  for k, v in pairs(data.hyphenmins) do
    file:write("      ", k, " = {left = ", v.left, ", right = ", v.right, "},\n")
  end
  file:write("   },\n")
  file:write("   patterns = {\n")
  for _, v in ipairs(data.patterns) do
    file:write("      \"", v, "\",\n")
  end
  file:write("   },\n")
  if #data.exceptions > 0 then
    file:write("   exceptions = {\n")
    for _, v in ipairs(data.exceptions) do
      file:write("      \"", v, "\",\n")
    end
    file:write("   },\n")
  end
  if data.input then
    file:write("   input = { \"", data.input, "\" },\n")
  end
  file:write("}\n")
  file:close()
end

local input = arg[1]
if not input then
  print("Usage: texhyph2lua.lua <name>")
  os.exit(1)
end
local res, err = convertPatternFile("sources/"..input..".tex")
if not res then
  print(input, "- Error:", err)
  os.exit(1)
end
if #res.patterns == 0 and #res.exceptions == 0 and not res.input then
  print(input, "- Nothing found, skipping")
  os.exit(1)
end
local output =  input:gsub("^hyph%-", "") .. ".lua"
print(input, "- Patterns: " .. #res.patterns .. ", exceptions: " .. #res.exceptions .. (res.input and ", input: " .. res.input or ""))
writePatternFile(output, res)
