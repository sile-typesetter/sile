local MIME_TYPE = "image/x-xbitmap"

local function size (stream, options)
    local input = stream:read(1024)
    assert(input, "error reading")

    local _, _, x, y = input:find("#define%s*%S*%s*(%d+)%s*\n" ..
                                  "#define%s*%S*%s*(%d+)")
    if x then return tonumber(x), tonumber(y), MIME_TYPE end
    return nil, nil, "can't find size definitions in XBM file"
end

return size
-- vi:ts=4 sw=4 expandtab
