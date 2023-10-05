local cli = pl.class()

cli.parseArguments = function ()
  local cliargs = require("cliargs")
  local print_version = function(flag)
    print(flag == "V" and "SILE " .. SILE.version or SILE.full_version)
    os.exit(0)
  end
  cliargs:set_colsz(0, 120)
  cliargs:set_name("sile")
  cliargs:set_description([[
      The SILE typesetter reads an input file(s), by default in either SIL or XML format, and
      processes them to generate an output file, by default in PDF format. The output will be written
      to a file with the same name as the first input file with the extension changed to .pdf unless
      the `--output` argument is used. Additional input or output formats can be handled by loading
      a module with the `--use` argument to add support for them first.
    ]])
  cliargs:splat("INPUTS", "input document(s), by default in SIL or XML format", nil, 999)
  cliargs:option("-b, --backend=VALUE", "choose an alternative output backend")
  cliargs:option("-c, --class=VALUE", "override default document class")
  cliargs:option("-d, --debug=VALUE", "show debug information for tagged aspects of SILE’s operation", {})
  cliargs:option("-e, --evaluate=VALUE", "evaluate Lua expression before processing input", {})
  cliargs:option("-E, --evaluate-after=VALUE", "evaluate Lua expression after processing input", {})
  cliargs:option("-f, --fontmanager=VALUE", "choose an alternative font manager")
  cliargs:option("-I, --include=FILE", "deprecated, see --use, --preamble, or --postamble", {})
  cliargs:option("-m, --makedeps=FILE", "generate a list of dependencies in Makefile format")
  cliargs:option("-o, --output=FILE", "explicitly set output file name")
  cliargs:option("-O, --options=PARAMETER=VALUE[,PARAMETER=VALUE]", "set document class options", {})
  cliargs:option("-p, --preamble=FILE", "process SIL, XML, or other content before the input document", {})
  cliargs:option("-P, --postamble=FILE", "process SIL, XML, or other content after the input document", {})
  cliargs:option("-u, --use=MODULE[[PARAMETER=VALUE][,PARAMETER=VALUE]]", "load and initialize a module before processing input", {})
  cliargs:flag("-q, --quiet", "suppress warnings and informational messages during processing")
  cliargs:flag("-t, --traceback", "display detailed location trace on errors and warnings")
  cliargs:flag("-h, --help", "display this help, then exit")
  cliargs:flag("-V, --version", "display version information, then exit", print_version)
  -- Work around cliargs not processing - as an alias for STDIO streams:
  -- https://github.com/amireh/lua_cliargs/issues/67
  local _arg = pl.tablex.imap(luautf8.gsub, _G.arg, "^-$", "STDIO")
  local opts, parse_err = cliargs:parse(_arg)
  if not opts and parse_err then
    print(parse_err)
    local code = parse_err:match("^Usage:") and 0 or 1
    os.exit(code)
  end
  if opts.INPUTS and #opts.INPUTS > 0 then
    local has_input_filename = false
    pl.tablex.foreachi(opts.INPUTS, function (v, k)
      if v == "STDIO" then
        opts.INPUTS[k] = "-"
      elseif not has_input_filename then
        has_input_filename = true
      end
    end)
    if not has_input_filename and not opts.output then
      SU.error("Unable to derive an output filename (perhaps because input is a STDIO stream).\n"..
               "  Please use --output to set one explicitly.")
    end
    SILE.input.filenames = opts.INPUTS
  end
  if opts.backend then
    SILE.backend = opts.backend
  end
  if opts.class then
    SILE.input.class = opts.class
  end
  for _, flags in ipairs(opts.debug) do
    for _, flag in ipairs(pl.stringx.split(flags, ",")) do
      SILE.debugFlags[flag] = true
    end
  end
  for _, statement in ipairs(opts["evaluate"]) do
    table.insert(SILE.input.evaluates, statement)
  end
  for _, statement in ipairs(opts["evaluate-after"]) do
    table.insert(SILE.input.evaluateAfters, statement)
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
  for _, option in ipairs(opts.options) do
    local options = SILE.parserBits.parameters:match(option)
    SILE.input.options = pl.tablex.merge(SILE.input.options, options, true)
  end
  for _, use in ipairs(opts.use) do
    local spec = SILE.parserBits.cliuse:match(use)
    table.insert(SILE.input.uses, spec)
  end
  for _, path in ipairs(opts.preamble) do
    table.insert(SILE.input.preambles, path)
  end
  for _, path in ipairs(opts.postamble) do
    table.insert(SILE.input.postambles, path)
  end
  for _, path in ipairs(opts.include) do
    SU.deprecated("-I/--include", "-u/--use or -p/--preamble", "0.14.0", "0.15.0")
    table.insert(SILE.input.includes, path)
  end
  -- http://lua-users.org/wiki/VarargTheSecondClassCitizen
  local summary = function (...)
    local contentloc = SILE.traceStack:locationHead()
    local codeloc = table.unpack({...}, 1, select('#', ...))
    return ("Processing at: %s\n\tUsing code at: %s"):format(contentloc, codeloc)
  end
  local unexpected = function ()
    if not SILE.scratch.caughterror then
      io.stderr:write("\n! Unexpected Lua error\n")
    end
  end
  local trace = function (...)
    unexpected()
    io.stderr:write(debug.traceback("", 2) or "\t! debug.traceback() did not identify code location")
    io.stderr:write("\n")
    return summary(...)
  end
  local identity = function (...)
    unexpected()
    return summary(...) .. "\n\nRun with --traceback for more detailed trace leading up to errors."
  end
  SILE.errorHandler = opts.traceback and trace or identity
  SILE.quiet = opts.quiet
  SILE.traceback = opts.traceback
end

return cli
