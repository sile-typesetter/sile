local function process (ast)
   if not ast then
      return
   end
   if SU.debugging("ast") then
      SU.debugAST(ast, 0)
   end
   if type(ast) == "function" then
      return ast()
   end
   for _, content in ipairs(ast) do
      if type(content) == "string" then
         SILE.typesetter:typeset(content)
      elseif type(content) == "function" then
         content()
      elseif SILE.Commands[content.command] then
         SILE.call(content.command, content.options, content)
      elseif not content.command and not content.id then
         local pId = SILE.traceStack:pushContent(content, "content")
         SILE.process(content)
         SILE.traceStack:pop(pId)
      elseif type(content) ~= "nil" then
         local pId = SILE.traceStack:pushContent(content)
         SU.error("Unknown command " .. (tostring(content.command or content.id)))
         SILE.traceStack:pop(pId)
      end
   end
end

local preloadedinputters = { "xml", "lua", "sil" }

local function detectFormat (doc, filename)
   -- Preload default reader types so content detection has something to work with
   if #SILE.inputters == 0 then
      for _, format in ipairs(preloadedinputters) do
         local _ = SILE.inputters[format]
      end
   end
   local contentDetectionOrder = {}
   for _, inputter in pairs(SILE.inputters) do
      if inputter.order then
         table.insert(contentDetectionOrder, inputter)
      end
   end
   table.sort(contentDetectionOrder, function (a, b)
      return a.order < b.order
   end)
   local initialround = filename and 1 or 2
   for round = initialround, 3 do
      for _, inputter in ipairs(contentDetectionOrder) do
         SU.debug("inputter", "Running content type detection round", round, "with", inputter._name)
         if inputter.appropriate(round, filename, doc) then
            return inputter._name
         end
      end
   end
   SU.error(("Unable to pick inputter to process input from '%s'"):format(filename))
end

local function processString (doc, format, filename, options)
   local cpf
   if not filename then
      cpf = SILE.currentlyProcessingFile
      local caller = debug.getinfo(2, "Sl")
      SILE.currentlyProcessingFile = caller.short_src .. ":" .. caller.currentline
   end
   -- In the event we're processing the master file *and* the user gave us
   -- a specific inputter to use, use it at the exclusion of all content type
   -- detection
   local inputter
   if
      filename
      and pl.path.normcase(pl.path.normpath(filename)) == pl.path.normcase(SILE.input.filenames[1])
      and SILE.inputter
   then
      inputter = SILE.inputter
   else
      format = format or detectFormat(doc, filename)
      if not SILE.quiet then
         io.stderr:write(("<%s> as %s\n"):format(SILE.currentlyProcessingFile, format))
      end
      inputter = SILE.inputters[format](options)
      -- If we did content detection *and* this is the master file, save the
      -- inputter for posterity and postambles
      if filename and pl.path.normcase(filename) == pl.path.normcase(SILE.input.filenames[1]:gsub("^-$", "STDIN")) then
         SILE.inputter = inputter
      end
   end
   local pId = SILE.traceStack:pushDocument(SILE.currentlyProcessingFile, doc)
   inputter:process(doc)
   SILE.traceStack:pop(pId)
   if cpf then
      SILE.currentlyProcessingFile = cpf
   end
end

local function processFile (filename, format, options)
   local lfs = require("lfs")
   local doc
   if filename == "-" then
      filename = "STDIN"
      doc = io.stdin:read("*a")
   else
      -- Turn slashes around in the event we get passed a path from a Windows shell
      filename = filename:gsub("\\", "/")
      if not SILE.masterFilename then
         SILE.masterFilename = pl.path.splitext(pl.path.normpath(filename))
      end
      if SILE.input.filenames[1] and not SILE.masterDir then
         SILE.masterDir = pl.path.dirname(SILE.input.filenames[1])
      end
      if SILE.masterDir and SILE.masterDir:len() >= 1 then
         _G.extendSilePath(SILE.masterDir)
         _G.extendSilePathRocks(SILE.masterDir .. "/lua_modules")
      end
      filename = SILE.resolveFile(filename) or SU.error("Could not find file")
      local mode = lfs.attributes(filename).mode
      if mode ~= "file" and mode ~= "named pipe" then
         SU.error(filename .. " isn't a file or named pipe, it's a " .. mode .. "!")
      end
      if SILE.makeDeps then
         SILE.makeDeps:add(filename)
      end
      local file, err = io.open(filename)
      if not file then
         print("Could not open " .. filename .. ": " .. err)
         return
      end
      doc = file:read("*a")
   end
   local cpf = SILE.currentlyProcessingFile
   SILE.currentlyProcessingFile = filename
   local pId = SILE.traceStack:pushDocument(filename, doc)
   local ret = SILE.processString(doc, format, filename, options)
   SILE.traceStack:pop(pId)
   SILE.currentlyProcessingFile = cpf
   return ret
end

return {
   process = process,
   processString = processString,
   processFile = processFile,
}
