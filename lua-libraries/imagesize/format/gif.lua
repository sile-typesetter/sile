local Util = require "imagesize.util"

local MIME_TYPE = "image/gif"

local DEFAULT_GIF_BEHAVIOR = "screen"
local ALLOWED_GIF_BEHAVIOR = { screen = true, first = true, largest = true }

local function _gif_blockskip (stream, skip, typ)
    while true do
        local buf = stream:read(skip)
        if not buf or buf:len() ~= skip then
            return "invalid/corrupted GIF (at EOF in GIF " .. typ .. ")"
        end
        local lbuf = stream:read(1)     -- Block size
        if lbuf and lbuf ~= "" then
            skip = lbuf:byte(1)
            if skip == 0 then break end  -- Block terminator
        end
    end
end

local function _skip_table_based_image (stream)
    local flags = stream:read(1)
    if not flags or flags == "" then return false end
    flags = flags:byte(1)

    -- Skip local color table.
    if flags >= 0x80 then
        local cmapsize = 3 * (2 ^ ((x % 8) + 1))
        local buf = stream:read(cmapsize)
        if not buf or buf:len() ~= cmapsize then return false end
    end

    -- Skip LZW minimum code size byte, then table based image data blocks.
    return not _gif_blockskip(stream, 1, "image")
end

local function size (stream, options)
    local gif_behavior = options.gif_behavior or DEFAULT_GIF_BEHAVIOR
    if not ALLOWED_GIF_BEHAVIOR[gif_behavior] then
        error("invalid 'gif_behavior' option", 3)
    end

    -- Skip over the identifying string, since we already know this is a GIF
    local typ  = stream:read(6)
    local buf = stream:read(7)
    if not typ or not buf or typ:len() ~= 6 or buf:len() ~= 7 then
        return nil, nil, "invalid/corrupted GIF (incomplete header)"
    end

    local sw = Util.get_uint16_le(buf, 1)
    local sh = Util.get_uint16_le(buf, 3)
    local x = buf:byte(5)

    if gif_behavior == "screen" then return sw, sh, MIME_TYPE end

    if x >= 0x80 then
        local cmapsize = 3 * (2 ^ ((x % 8) + 1))
        buf = stream:read(cmapsize)
        if not buf or buf:len() ~= cmapsize then
            return nil, nil,
                   "invalid/corrupted GIF (global color map too small?)"
        end
    end

    -- Before we start this loop, set $sw and $sh to 0s and use them to track
    -- the largest sub-image in the overall GIF.
    sw, sh = 0, 0

    while true do
        buf = stream:read(1)
        if not buf or buf == "" then
            -- At this point, if we haven't returned then the user wants the
            -- largest of the sub-images. So, if $sh and $sw are still 0s, then
            -- we didn't see even one Image Descriptor block. Otherwise, return
            -- those two values.
            if sw > 0 and sh > 0 then
                return sw, sh, MIME_TYPE
            else
                return nil, nil, "invalid/corrupted GIF (no Image Descriptors)"
            end
        end
        x = buf:byte(1)
        if x == 0x2C then
            -- Image Descriptor (GIF87a, GIF89a 20.c.i)
            buf = stream:read(8)
            if not buf or buf:len() ~= 8 then
                return nil, nil, "invalid/corrupted GIF (missing image header?)"
            end
            local w, h = Util.get_uint16_le(buf, 5), Util.get_uint16_le(buf, 7)
            if gif_behavior == "first" then return w, h, MIME_TYPE end
            if w > sw and h > sh then sw, sh = w, h end
            if not _skip_table_based_image(stream) then
                return nil, nil, "incomplete/invalid table based image in GIF"
            end
        elseif x == 0x21 then
            -- Extension Introducer (GIF89a 23.c.i, could also be in GIF87a)
            buf = stream:read(1)
            if buf and buf ~= "" then
                x = buf:byte(1)
                if x == 0xF9 then
                    -- Graphic Control Extension (GIF89a 23.c.ii)
                    stream:read(6)  -- skip it
                elseif x == 0xFE then
                    -- Comment Extension (GIF89a 24.c.ii)
                    local err = _gif_blockskip(stream, 0, "Comment")
                    if err then return nil, nil, err end
                elseif x == 0x01 then
                    -- Plain Text Label (GIF89a 25.c.ii)
                    local err = _gif_blockskip(stream, 13, "text data")
                    if err then return nil, nil, err end
                elseif x == 0xFF then
                    -- Application Extension Label (GIF89a 26.c.ii)
                    local err = _gif_blockskip(stream, 12, "application data")
                    if err then return nil, nil, err end
                else
                    return nil, nil,
                            string.format("invalid/corrupted GIF (unknown" ..
                                          " extension 0x%X)", x)
                end
            end
        elseif x == 0x3B then
            if sw > 0 and sh > 0 then
                return sw, sh, MIME_TYPE
            else
                return nil, nil, "GIF trailer reached with no image size found"
            end
        else
            return nil, nil,
                   string.format("invalid/corrupted GIF (unknown code 0x%X)", x)
        end
    end
end

return size
-- vi:ts=4 sw=4 expandtab
