return function()
    local plain = require "classes.plain"
    local class = plain()
    SILE.documentState.documentClass = class

    class:loadPackage("unichar")

    local chars = {
        ["victory-hand"] = "U+270C", -- ✌
        ["writing-hand"] = "U+270D", -- ✍
        ["check-mark"] = "U+2713 ", -- ✓
        ["greek-cross"] = "U+2719", -- ✙
        ["maltese-cross"] = "U+2720", --  ✠
        ["syriac-cross"] = "U+2670", -- ♰
        ["star-of-david"] = "U+2721", -- ✡
        ["snowflake"] = "U+2744", -- ❄. There are these variants: ❅ ❆.
        ["bullseye"] = "U+25CE", -- ◎
        ["skull"] = "U+2620", -- ☠
        ["chi-rho"] = "U+2627", -- ☧
        ["dharmachakra"] = "U+2638", -- ☸
        ["hammer-and-sickle"] = "U+262D", -- ☭
        ["recycling-symbol"] = "U+267B", -- ♻
        ["gear"] = "U+2699", -- ⚙ 
        ["balance"] = "U+2696", -- ⚖
        ["anchor"] = "U+2693", -- ⚓
        ["female-sign"] = "U+2640", -- ♀
        ["male-sign"] = "U+2642", -- ♂
        ["unisex-sign"] = "U+26A5", -- ⚥
        ["atom"] = "U+269B" -- ⚛
    }

    for k, v in pairs(chars) do
        SILE.typesetter:typeset(k .. ": ")
        SILE.call(k)
        -- SILE.typesetter:typeset("\t"..v)
        SILE.call("par")
    end
end
