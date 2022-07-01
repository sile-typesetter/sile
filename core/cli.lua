local cli = pl.class()

cli.parseArguments = function ()
  local cliargs = require("cliargs")
  local print_version = function()
    print(SILE.full_version)
    os.exit(0)
  end
  cliargs:set_colsz(0, 120)
  cliargs:set_name("sile")
  cliargs:set_description([[
      The SILE typesetter reads a single input file, by default in either SIL or XML format,
      and processes it to generate a single output file, by default in PDF format. The
      output file will be written to the same name as the input file with the extension
      changed to .pdf. Additional input or output formats can be handled by requiring a
      module that adds support for them first.
    ]])
  cliargs:splat("INPUT", "input document, by default in SIL or XML format")
  cliargs:option("-b, --backend=VALUE", "choose an alternative output backend")
  cliargs:option("-c, --class=VALUE", "override default document class")
  cliargs:option("-d, --debug=VALUE", "show debug information for tagged aspects of SILE’s operation", {})
  cliargs:option("-e, --evaluate=VALUE", "evaluate Lua expression before processing input", {})
  cliargs:option("-E, --evaluate-after=VALUE", "evaluate Lua expression after processing input", {})
  cliargs:option("-f, --fontmanager=VALUE", "choose an alternative font manager")
  cliargs:option("-m, --makedeps=FILE", "generate a list of dependencies in Makefile format")
  cliargs:option("-o, --output=FILE", "explicitly set output file name")
  cliargs:option("-O, --options=PARAMETER=VALUE", "set document class options", {})
  cliargs:option("-I, --include=FILE", "deprecated, see --require, --preamble, or --postamble", {})
  cliargs:option("-r, --require=MODULE", "require a resource to be loaded before processing input", {})
  cliargs:option("-p, --preamble=FILE", "include an SIL, XML, or other content before the input document", {})
  cliargs:option("-P, --postamble=FILE", "include an SIL, XML, or other content after the input document", {})
  cliargs:flag("-t, --traceback", "display detailed location trace on errors and warnings")
  cliargs:flag("-h, --help", "display this help, then exit")
  cliargs:flag("-v, --version", "display version information, then exit", print_version)
  -- Work around cliargs not processing - as an alias for STDIO streams:
  -- https://github.com/amireh/lua_cliargs/issues/67
  local _arg = pl.tablex.imap(luautf8.gsub, _G.arg, "^-$", "STDIO")
  local opts, parse_err = cliargs:parse(_arg)
  if not opts and parse_err then
    print(parse_err)
    os.exit(1)
  end
  if opts.INPUT then
    if opts.INPUT == "STDIO" then
      opts.INPUT = "-"
    end
    -- Turn slashes around in the event we get passed a path from a Windows shell
    SILE.inputFile = opts.INPUT:gsub("\\", "/")
    -- Strip extension
    SILE.masterFilename = string.match(SILE.inputFile, "(.+)%..-$") or SILE.inputFile
    SILE.masterDir = SILE.masterFilename:match("(.-)[^%/]+$")
  end
  if opts.backend then
    SILE.backend = opts.backend
  end
  for _, flags in ipairs(opts.debug) do
    for _, flag in ipairs(pl.stringx.split(flags, ",")) do
      SILE.debugFlags[flag] = true
    end
  end
  for _, statement in ipairs(opts.evaluate) do
    local func, err = load(statement)
    if err then SU.error(err) end
    SILE.dolua[#SILE.dolua+1] = func
  end
  if opts.fontmanager then
    SILE.forceFontManager = opts.fontmanager
  end
  if opts.makedeps then
    SILE.makeDeps = require("core.makedeps")
    SILE.makeDeps.filename = opts.makedeps
  end
  if opts.output then
    if opts.output == "STDIO" then
      opts.output = "-"
    end
    SILE.outputFilename = opts.output
  end
  for _, include in ipairs(opts.include) do
    SILE.preamble[#SILE.preamble+1] = include
  end
  -- http://lua-users.org/wiki/VarargTheSecondClassCitizen
  local identity = function (...) return table.unpack({...}, 1, select('#', ...)) end
  SILE.errorHandler = opts.traceback and debug.traceback or identity
  SILE.traceback = opts.traceback
end

return cli
