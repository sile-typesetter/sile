require "packages/image"

SILE.inputs.TeXlike.passthroughTags.lilypond = true

local lilypond_command = "lilypond"
local lilypond_options = "-dbackend=eps -dno-point-and-click -ddelete-intermediate-files -djob-count=2"

local trim = function (str)
    return str:gsub("^%s*", ""):gsub("%s*$", "")
  end

local schemeBoolean = function (input)
    return input and "##t" or "##f"
  end

local makePreamble = function (options)
    return trim(string.format([[
#(set-global-staff-size %s)
\layout {
  indent = %s\pt
  ragged-right = %s
}
      ]], options.staffsize,
          options.indent,
          schemeBoolean(options.raggedright)))
  end

local renderLilypondSystems = function(options)
    local tmpdir = trim(io.shell("mktemp -d lilypond.XXXXXX"))
    local input = io.slurp(SILE.resolveFile(options.src))
    local fname = "lilypond.ly"
    local lyfile = io.catfile(tmpdir, fname)
    local preamble = makePreamble(options)
    io.writelines(io.open(lyfile, "w+"), preamble, input)
    io.shell("cd " .. tmpdir .. ";" .. lilypond_command .. " " .. lilypond_options .. " " .. fname)
    local systemscount = trim(io.slurp(lyfile:gsub(".ly$", "-systems.count")))
    local systems = {}
    for i=1, systemscount do
      systems[#systems+1] = lyfile:gsub(".ly$", "-" .. i .. ".pdf")
    end
    return systems
  end

SILE.registerCommand("lilypond", function(options, content)
  options.staffsize = options.staffsize or SILE.settings.get("document.baselineskip").height:absolute().length
  options.indent = options.indent or (SILE.settings.get("document.parindent") or SILE.nodefactory.zeroGlue).width:absolute().length
  options.raggedright = SU.boolean(options.raggedright, (SILE.settings.get("document.rskip") and SILE.settings.get("document.rskip").width.stretch > 1000 or false))
  if options.src then
    for i, system in pairs(renderLilypondSystems(options)) do
      SILE.call("img", { src = system })
    end
  end
end)
