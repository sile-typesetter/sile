local Util = require "imagesize.util"

local MIME_TYPE=  "image/png"

-- Re-written and tested by tmetro@vl.com
local function size (stream, options)
    -- Offset to first Chunk Type code = 8-byte ident + 4-byte chunk length + 1
    local offset = 12
    local length = 4

    local ok, err = stream:seek("set", offset)
    if not ok then return nil, nil, "error seeking in PNG file: " .. err end

    local buf = stream:read(length)
    if not buf or buf:len() ~= length then
        return nil, nil, "PNG file not big enough to contain header data"
    end

    if buf == "IHDR" then
        -- IHDR = Image Header
        length = 8
        buf = stream:read(length)
        if not buf or buf:len() ~= length then
            return nil, nil, "PNG file not big enough to contain header data"
        end
        return Util.get_uint32_be(buf, 1), Util.get_uint32_be(buf, 5), MIME_TYPE
    else
        return nil, nil, "can't find header data in PNG file"
    end
end

return size
-- vi:ts=4 sw=4 expandtab
