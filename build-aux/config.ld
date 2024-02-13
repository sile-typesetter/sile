project = "SILE"
description = "The SILE Typesetter"
readme = "../README.md"
dir = "../lua-api-docs"
format = "discount"
file = {
  "../sile-lua",
  "../core/",
  "../classes/",
  "../inputters/",
  "../languages/",
  "../outputters/",
  "../packages/",
  "../pagebuilders/",
  "../shapers/",
  "../types/",
  "../typesetters/",
}
merge = true
no_space_before_args = true
sort_modules = true
new_type("interfaces", "Interfaces", true)
new_type("types", "Types", true)
