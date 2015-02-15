local function utf8encode(code)
  if code < 0 then
    error('Code point must not be negative.')
  elseif code <= 0x7f then
    return string.char(code)
  elseif code <= 0x7ff then
    local c1 = code / 64 + 192
    local c2 = code % 64 + 128
    return string.char(c1, c2)
  elseif code <= 0xffff then
    local c1 = code / 4096 + 224
    local c2 = code % 4096 / 64 + 128
    local c3 = code % 64 + 128
    return string.char(c1, c2, c3)
  elseif code <= 0x10ffff then
    local c1 = code / 262144 + 240
    local c2 = code % 262144 / 4096 + 128
    local c3 = code % 4096 / 64 + 128
    local c4 = code % 64 + 128
    return string.char(c1, c2, c3, c4)
  end
  return ''
end

SILE.registerCommand("unichar", function(options, content)
  local cp = content[1]
  if type(cp) ~= "string" then SU.error("Bad argument to \\unicode") end
  hex = (cp:match("[Uu]%+(%x+)") or cp:match("0[xX](%x+)"))
  if hex then
    cp = tonumber("0x"..hex)
  elseif tonumber(cp) then 
    cp = tonumber(cp)
  end
  SILE.typesetter:typeset(utf8encode(cp))
end)
