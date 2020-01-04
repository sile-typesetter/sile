SILE = require("core/sile")

describe("SILE.linebreak", function()

  SILE.documentState = { documentClass = { state = { } } }
  SILE.typesetter:init(SILE.newFrame({ id="foo" }))

  -- This is a list of boxes, with their dimensions, extracted from a specially hacked version of TeX.
  local hlist = {}
  local function nnode(spec) table.insert(hlist, SILE.nodefactory.newNnode(spec)) end
  local function glue(spec) table.insert(hlist, SILE.nodefactory.newGlue(spec)) end
  nnode({ text ="To", height =  6.15234, depth = 0.14647, width = 10.14648 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="Sherlock", height =  7.56836, depth = 0.14647, width = 35.82031 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="Holmes", height =  7.56836, depth = 0.14647, width = 30.79102 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="she", height =  7.56836, depth = 0.14647, width = 13.99902 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="is", height =  6.6211, depth = 0.14647, width = 6.57227 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="always", height =  7.56836, depth = 2.44139, width = 27.59766 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="the", height =  7.56836, depth = 0.14647, width = 13.5791 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="woman", height = 4.6875, depth = 0.1953, width = 32.37305 })
  glue({ width = SILE.length.new({ length = 2.93619, stretch = 3.30322, shrink = 0.24467 }) })
  nnode({ text ="I", height =  6.15234, depth = 0.0, width = 2.97852 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.09996, shrink = 0.73477 }) })
  nnode({ text ="have", height =  7.56836, depth = 0.14647, width = 19.26758 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="seldom", height =  7.56836, depth = 0.14647, width = 29.45313 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="heard", height =  7.56836, depth = 0.14647, width = 23.78906 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="him", height =  7.56836, depth = 0.0, width = 16.25977 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="mention", height =  6.6211, depth = 0.14647, width = 34.86816 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="her", height =  7.56836, depth = 0.14647, width = 14.09668 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="under", height =  7.56836, depth = 0.14647, width = 24.59473 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="any", height =  4.6875, depth = 2.44139, width = 15.03906 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="other", height =  7.56836, depth = 0.14647, width = 22.56836 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="name", height = 4.6875, depth = 0.1953, width = 25.04883 })
  glue({ width = SILE.length.new({ length = 2.93619, stretch = 3.30322, shrink = 0.24467 }) })
  nnode({ text ="In", height =  6.15234, depth = 0.0, width = 8.4961 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="his", height =  7.56836, depth = 0.14647, width = 12.08984 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="eyes", height =  4.6875, depth = 2.44139, width = 17.83691 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="she", height =  7.56836, depth = 0.14647, width = 13.99902 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="eclipses", height =  7.56836, depth = 2.34373, width = 31.9043 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="and", height =  7.56836, depth = 0.14647, width = 15.30762 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="predominates", height =  7.56836, depth = 2.34373, width = 56.7334 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="the", height =  7.56836, depth = 0.14647, width = 13.5791 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="whole", height =  7.56836, depth = 0.14647, width = 24.93652 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="of", height =  7.56836, depth = 0.14647, width = 8.13965 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="her", height =  7.56836, depth = 0.14647, width = 14.09668 })
  glue({ width = SILE.length.new({ length = 2.20215, stretch = 1.10107, shrink = 0.73404 }) })
  nnode({ text ="sex.", height =  4.6875, depth = 0.1953, width = 15.6543 })

  it("should sleuth the right break point", function()
    -- print(SILE.linebreak:doBreak(hlist, 30.0))
  end)

end)
