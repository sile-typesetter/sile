require "packages/image"

SILE.inputs.TeXlike.passthroughTags.lilypond = true

local lilypond_command = "lilypond"
local lilypond_options = "-dbackend=eps -dno-point-and-click -ddelete-intermediate-files -djob-count=2"

local runLilypond = function(input)
    local result = os.execute(lilypond_command .. " " .. lilypond_options .. " " .. input)
    return result
  end

local read_file = function (path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read "*a"
    file:close()
    return content
  end

SILE.registerCommand("lilypond", function(options, content)
  if options.src then
    local src = SILE.resolveFile(options.src)
    local out = runLilypond(src)
    local out_systems = options.src:gsub(".ly", "-systems.count")
    local systems = read_file(out_systems)
    local system
    for i=1, systems do
      system = options.src:gsub(".ly", "-" .. i .. ".pdf")
      SILE.call("img", { src = system })
    end
  end
end)
