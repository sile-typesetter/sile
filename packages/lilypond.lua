require "packages/image"

SILE.inputs.TeXlike.passthroughTags.lilypond = true

local lilypond_command = "lilypond"
local lilypond_options = "-dbackend=eps -dno-point-and-click -ddelete-intermediate-files -djob-count=2"

local trim = function (str)
    return str:gsub("^%s*", ""):gsub("%s*$", "")
  end

local renderLilypondSystems = function(input)
    local tmpdir = trim(io.shell("mktemp -d lilypond.XXXXXX"))
    local input = io.slurp(SILE.resolveFile(input))
    local fname = "lilypond.ly"
    local lyfile = io.catfile(tmpdir, fname)
    io.writelines(io.open(lyfile, "w+"), input)
    io.shell("cd " .. tmpdir .. ";" .. lilypond_command .. " " .. lilypond_options .. " " .. fname)
    local systemscount = trim(io.slurp(lyfile:gsub(".ly$", "-systems.count")))
    local systems = {}
    for i=1, systemscount do
      systems[#systems+1] = lyfile:gsub(".ly$", "-" .. i .. ".pdf")
    end
    return systems
  end

SILE.registerCommand("lilypond", function(options, content)
  if options.src then
    for i, system in pairs(renderLilypondSystems(options.src)) do
      SILE.call("img", { src = system })
    end
  end
end)
