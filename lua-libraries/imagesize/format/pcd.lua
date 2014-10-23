local MIME_TYPE = "image/x-kodak-photocd"

-- Kodak photo-CDs are weird. Don't ask me why, you really don't want details.
local PCD_MAP = {
    ["base/16"] = { 192,  128  },
    ["base/4"]  = { 384,  256  },
    ["base"]    = { 768,  512  },
    ["base4"]   = { 1536, 1024 },
    ["base16"]  = { 3072, 2048 },
    ["base64"]  = { 6144, 4096 },
}
-- Default scale for PCD images
local DEFAULT_PCD_SCALE = "base"

-- Suggested by Matt Mueller <mueller@wetafx.co.nz>, and based on a piece of
-- sample Perl code by a currently-unknown author. Credit will be placed here
-- once the name is determined.
local function size (stream, options)
    local buf = stream:read(0xF00)
    if not buf or buf:len() ~= 0xF00 then
        return nil, nil, "PCD image file is not big enough"
    end

    -- Second-tier sanity check
    if buf:sub(0x801, 0x803) ~= "PCD" then
        return nil, nil, "can't find 'PCD' identifier in PCD image file"
    end

    local sizespec = PCD_MAP[options.pcd_scale or DEFAULT_PCD_SCALE]
    if not sizespec then error("invalid 'pcd_scale' option", 3) end

    local orient = (buf:byte(0x0E03) % 1) > 0   -- Clear down to one bit
    if orient then
        return sizespec[1], sizespec[2], MIME_TYPE
    else
        return sizespec[2], sizespec[1], MIME_TYPE
    end
end

return size
-- vi:ts=4 sw=4 expandtab
