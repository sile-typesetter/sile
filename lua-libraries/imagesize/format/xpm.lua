local MIME_TYPE = "image/x-xpixmap"

-- Added by Randy J. Ray, 30 Jul 1996
-- Size an XPM file by looking for the "X Y N W" line, where X and Y are
-- dimensions, N is the total number of colors defined, and W is the width of a
-- color in the ASCII representation, in characters. We only care about X & Y.
local function size (stream, options)
    for line in stream:lines() do
        local _, _, x, y = line:find('"%s*(%d+)%s+(%d+)[%s%d]+"')
        if x then return tonumber(x), tonumber(y), MIME_TYPE end
    end

    return nil, nil, "can't find image size in XPM file"
end

return size
-- vi:ts=4 sw=4 expandtab
