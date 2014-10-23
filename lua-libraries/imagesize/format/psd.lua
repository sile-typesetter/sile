local Util = require "imagesize.util"

local MIME_TYPE = "image/x-photoshop"

-- Determine the size of a PhotoShop save-file (*.PSD)
local function size (stream, options)
    local buf = stream:read(26)
    if not buf or buf:len() ~= 26 then
        return nil, nil, "PSD image header incomplete"
    end

    return Util.get_uint32_be(buf, 19), Util.get_uint32_be(buf, 15), MIME_TYPE
end

return size
-- vi:ts=4 sw=4 expandtab
