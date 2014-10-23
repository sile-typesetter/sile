-- Gets data on the PPM/PGM/PBM family.
-- Contributed by Carsten Dominik <dominik@strw.LeidenUniv.nl>
local function size (stream, options)
    local header = stream:read(1024)
    if not header or header:len() < 9 then
        return nil, nil, "PNM file header missing"
    end

    local without_comments = header:gsub("\n#[^\n]*", "\n")

    -- PNM file of some sort
    local _, _, n, x, y = without_comments:find("^(P[1-7])%s+(%d+)%s+(%d+)")
    if not n then return nil, nil, "bad PNM header" end
    x, y = tonumber(x), tonumber(y)

    if n == "P1" or n == "P4" then
        return x, y, "image/x-portable-bitmap"
    elseif n == "P2" or n == "P5" then
        return x, y, "image/x-portable-graymap"
    elseif n == "P3" or n == "P6" then
        return x, y, "image/x-portable-pixmap"
    elseif n == "P7" then
        -- John Bradley's XV thumbnail pics (thanks to inwap@jomis.Tymnet.COM)
        _, _, x, y = header:find("IMGINFO:(%d+)x(%d+)")
        if not x then return nil, nil, "bad XV thumbnail header" end
        return tonumber(x), tonumber(y), "image/x-xv-thumbnail"
    else
        assert(false, "this should never happen")
    end
end

return size
-- vi:ts=4 sw=4 expandtab
