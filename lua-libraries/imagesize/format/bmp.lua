local Util = require "imagesize.util"

local MIME_TYPE = "image/x-ms-bmp"

-- Size a Windows-ish BitMaP image
-- Adapted from code contributed by Aldo Calpini <a.calpini@romagiubileo.it>
local function size (stream, options)
    local buf = stream:read(26)
    if not buf or buf:len() ~= 26 then
        return nil, nil, "file isn't big enough to contain a BMP header"
    end

    if Util.get_uint32_le(buf, 15) == 12 then
        -- Old OS/2 BITMAPCOREHEADER with 16 bit width and height.
        return Util.get_uint16_le(buf, 19), Util.get_uint16_le(buf, 21),
               MIME_TYPE
    else
        -- Some variant of Windows BITMAPINFOHEADER with 32 bit width & height.
        return Util.get_uint32_le(buf, 19), Util.get_uint32_le(buf, 23),
               MIME_TYPE
    end
end

return size
-- vi:ts=4 sw=4 expandtab
