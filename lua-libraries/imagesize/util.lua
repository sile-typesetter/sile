local M = { _NAME = "imagesize.util" }

function M.get_uint16_le (s, p)
    local a, b = s:byte(p, p + 1)
    return a + b * 256
end

function M.get_uint16_be (s, p)
    local a, b = s:byte(p, p + 1)
    return a * 256 + b
end

function M.get_uint32_le (s, p)
    local a, b, c, d = s:byte(p, p + 3)
    return a + b * 256 + c * 65536 + d * 16777216
end

function M.get_uint32_be (s, p)
    local a, b, c, d = s:byte(p, p + 3)
    return a * 16777216 + b * 65536 + c * 256 + d
end

return M
-- vi:ts=4 sw=4 expandtab
