local Util = require "imagesize.util"

local MIME_TYPE = "image/tiff"

local function _get_uint8 (s, p) return s:byte(p) end

local function _get_int8 (s, p)
    local n = s:byte(p)
    return (n >= 128) and -(256 - n) or n
end

-- Contributed by Cloyce Spradling <cloyce@headgear.org>
local function size (stream, options)
    -- Figure out how to read numbers, in little or big-endian format.
    local get_uint16, get_uint32 = Util.get_uint16_be, Util.get_uint32_be
    local header = stream:read(4)
    assert(header and header:len() == 4)    -- already checked magic number
    if header:find("^II") then
        get_uint16, get_uint32 = Util.get_uint16_le, Util.get_uint32_le
    end

    -- Set up an association between data types and their corresponding
    -- pack/unpack specification.  Don't take any special pains to deal with
    -- signed numbers; treat them as unsigned because none of the image
    -- dimensions should ever be negative.  (I hope.)
    local packspec = {
        _get_uint8, -- BYTE (8-bit unsigned integer)
        nil,        -- ASCII
        get_uint16, -- SHORT (16-bit unsigned integer)
        get_uint32, -- LONG (32-bit unsigned integer)
        nil,        -- RATIONAL
        _get_int8,  -- SBYTE (8-bit signed integer)
        nil,        -- UNDEFINED
        get_uint16, -- SSHORT (16-bit unsigned integer)
        get_uint32, -- SLONG (32-bit unsigned integer)
    }

    -- Get offset to IFD.
    header = stream:read(4)
    if not header or header:len() ~= 4 then
        return nil, nil, "incomplete header in TIFF file"
    end
    local offset = get_uint32(header, 1)

    -- Get number of directory entries
    local ok, err = stream:seek("set", offset)
    if not ok then
        return nil, nil, "error seeking to TIFF number of dir entries: " .. err
    end
    local ifd = stream:read(2)
    local num_dirent = get_uint16(ifd, 1)   -- Make it useful

    offset = offset + 2
    num_dirent = offset + (num_dirent * 12) -- Calc. maximum offset of IFD

    -- Do all the work
    local x, y
    while not x or not y do
        ok, err = stream:seek("set", offset)
        if not ok then
            return nil, nil, "error seeking to TIFF directory entry: " .. err
        end

        ifd = stream:read(12)
        if not ifd or ifd == "" or offset > num_dirent then break end
        if ifd:len() ~= 12 then
            return nil, nil, "incomplete directory entry in TIFF file"
        end
        offset = offset + 12

        local tag = get_uint16(ifd, 1)  -- ...and decode its tag
        local typ = get_uint16(ifd, 3)  -- ...and the data type

        -- Check the type for sanity.
        if packspec[typ] then
            if tag == 0x0100 then       -- ImageWidth (x)
                -- Decode the value
                x = packspec[typ](ifd, 9)
            elseif tag == 0x0101 then   -- ImageLength (y)
                -- Decode the value
                y = packspec[typ](ifd, 9)
            end
        end
    end

    -- Decide if we were successful or not
    if x and y then
        return x, y, MIME_TYPE
    else
        local id = ""
        if not x then id = "ImageWidth " end
        if not y then
            if id ~= "" then id = id .. "and " end
            id = id .. "ImageLength "
        end
        return nil, nil, id .. "tag(s) could not be found"
    end
end

return size
-- vi:ts=4 sw=4 expandtab
