local repeat_hyphen = require("languages.repeat-hyphen-nodemaker")

local nodemaker = pl.class(repeat_hyphen)
nodemaker._name = "cs"

return nodemaker
