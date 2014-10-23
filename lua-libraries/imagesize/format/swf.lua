local MIME_TYPE = "application/x-shockwave-flash"

local function _bytes_to_bits (s)
    local bits = ""
    for i = 1, s:len() do
        local c = s:byte(i)
        bits = bits .. (c >= 0x80          and "1" or "0")
                    .. ((c % 0x80) >= 0x40 and "1" or "0")
                    .. ((c % 0x40) >= 0x20 and "1" or "0")
                    .. ((c % 0x20) >= 0x10 and "1" or "0")
                    .. ((c % 0x10) >= 0x08 and "1" or "0")
                    .. ((c % 0x08) >= 0x04 and "1" or "0")
                    .. ((c % 0x04) >= 0x02 and "1" or "0")
                    .. ((c % 0x02) >= 0x01 and "1" or "0")
    end
    return bits
end

local function _bin2int (s)
    local n = 0
    for i = 1, s:len() do
        n = n * 2
        if s:sub(i, i) == "1" then n = n + 1 end
    end
    return n
end

-- Determine size of ShockWave/Flash files. Adapted from code sent by
-- Dmitry Dorofeev <dima@yasp.com>
local function size (stream, options)
    local buf = stream:read(33)
    if not buf or buf:len() ~= 33 then
        return nil, nil, "SWF file header incomplete"
    end

    local bs
    if buf:sub(1, 1) == "C" then
        -- Decompress enough of the file to get the FrameSize RECT.
        -- TODO - decompress into bs, update docs about module required
        return nil, nil, "compressed SWF files are currently not supported"
    else
        bs = _bytes_to_bits(buf:sub(9, 25))
    end

    local bits = _bin2int(bs:sub(1, 5))
    local x = _bin2int(bs:sub(6 + bits, 5 + bits * 2))
    local y = _bin2int(bs:sub(6 + bits * 3, 5 + bits * 4))

    return math.floor((x + 19) / 20), math.floor((y + 19) / 20), MIME_TYPE
end

return size
-- vi:ts=4 sw=4 expandtab
