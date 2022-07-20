-- Represents a stack of stack frame objects,
-- which describe the call-stack stack of the currently processed document.
-- Stack frames are stored contiguously, treating this object as an array.
-- Most recent and relevant stack frames are in higher indices, up to #traceStack.
-- Do not manipulate the stack directly, use provided push<Type> and pop methods.
-- There are different types of stack frames, see pushFrame for more details.
local traceStack = pl.class({
    -- Stores the frame which was last popped. Reset after a push.
    -- Helps to further specify current location in the processed document.
    afterFrame = nil,
  })

traceStack.defaultFrame = pl.class({

    location = function (self, relative)
      local str = ""
      if self.file and not relative then
        str = str .. self.file .. ":"
      end
      if self.lno then
        str = str .. self.lno .. ":"
        if self.col then
          str = str .. self.col .. ":"
        end
      end
      str = str .. (str:len() > 0 and " " or "") .. "in "
      str = str .. tostring(self)
      return str
    end,

    __tostring = function (self)
      self.file = nil
      self.lno = nil
      self.col = nil
      return #self > 0 and tostring(self) or ""
    end
  })

traceStack.documentFrame = pl.class(traceStack.defaultFrame)

function traceStack.documentFrame:_init (file, snippet)
  self.command = "document"
  self.file = file
  self.snippet = snippet
end

function traceStack.documentFrame:__tostring ()
  return "<file> (" .. self.snippet .. ")"
end

traceStack.commandFrame = pl.class(traceStack.defaultFrame)

function traceStack.commandFrame:_init (command, content, options)
  self.command = command
  self.file = content.file or SILE.currentlyProcessingFile
  self.lno = content.lno
  self.col = content.col
  self.options = options or {}
end

function traceStack.commandFrame:__tostring ()
  local opts = (pl.tablex.size(self.options) > 0 and tostring(self.options):gsub("^{", "["):gsub("}$", "]") or "")
  return "\\" .. self.command .. opts
end

traceStack.contentFrame = pl.class(traceStack.commandFrame)

function traceStack.contentFrame:_init (command, content)
  self:super(command, content, content.options)
end

traceStack.textFrame = pl.class(traceStack.defaultFrame)

function traceStack.textFrame:_init (text)
  self.text = text
end

function traceStack.textFrame:__tostring ()
  if self.text:len() > 20 then
    self.text = luautf8.sub(self.text, 1, 18) .. "…"
  end
  self.text = self.text:gsub("\n", "␤"):gsub("\t", "␉"):gsub("\v", "␋")
  return '"' .. self.text .. '"'
end

local function formatTraceLine (string)
  local prefix = "\t"
  return prefix .. string .. "\n"
end

-- Push a document processing run (input method) onto the stack
function traceStack:pushDocument(file, doc)
  local snippet = doc:sub(1, 100)
  local frame = traceStack.documentFrame(file, snippet)
  return self:pushFrame(frame)
end

-- Push a command frame on to the stack to record the execution trace for debugging.
-- Carries information about the command call, not the command itself.
-- Must be popped with `pop(returnOfPush)`.
function traceStack:pushCommand(command, content, options)
  if not command then
    SU.warn("Command should be specified for SILE.traceStack:pushCommand", true)
  end
  if type(content) == "function" then content = {} end
  local frame = traceStack.commandFrame(command, content, options)
  return self:pushFrame(frame)
end

-- Push a command frame on to the stack to record the execution trace for debugging.
-- Command arguments are inferred from AST content, any item may be overridden.
-- Must be popped with `pop(returnOfPush)`.
function traceStack:pushContent(content, command)
  if type(content) ~= "table" then
    SU.warn("Content parameter of SILE.traceStack:pushContent must be a table", true)
  end
  command = command or content.command
  if not command then
    SU.warn("Command should be specified or inferable for SILE.traceStack:pushContent", true)
  end
  local frame = traceStack.contentFrame(command, content)
  return self:pushFrame(frame)
end

-- Push a text that is going to get typeset on to the stack to record the execution trace for debugging.
-- Must be popped with `pop(returnOfPush)`.
function traceStack:pushText(text)
  local frame = traceStack.textFrame(text)
  return self:pushFrame(frame)
end

-- Internal: Push-pop balance checking ID
local lastPushId = 0

-- Push complete frame onto the stack.
-- Frame is a table with following optional fields:
-- .file = string - name of the file from which this originates
-- .lno = number - line in the file
-- .col = number - column on the line
-- .toStringHelper = function() that serializes extended information about the frame BESIDES location
function traceStack:pushFrame(frame)
  SU.debug("traceStack", string.rep(".", #self) .. "PUSH(" .. frame:location() .. ")")
  self[#self + 1] = frame
  self.afterFrame = nil
  lastPushId = lastPushId + 1
  frame._pushId = lastPushId
  return lastPushId
end

-- Pop previously pushed command from the stack.
-- Return value of `push` function must be provided as argument to check for balanced usage.
function traceStack:pop(pushId)
  if type(pushId) ~= "number" then
    SU.error("SILE.traceStack:pop's argument must be the result value of the corresponding push", true)
  end
  -- First verify that push/pop is balanced
  local popped = self[#self]
  if popped._pushId ~= pushId then
    local message = "Unbalanced content push/pop"
    if SILE.traceback or SU.debugging("traceStack") then
      message = message .. ". Expected " .. popped.pushId .. " - (" .. popped:location() .. "), got " .. pushId
    end
    SU.warn(message, true)
  else
    -- Correctly balanced: pop the frame
    self.afterFrame = popped
    self[#self] = nil
    SU.debug("traceStack", string.rep(".", #self) .. "POP(" .. popped:location() .. ")")
  end
end

-- Returns single line string with location of top most trace frame
function traceStack:locationHead()
  local afterFrame = self.afterFrame
  local top = self[#self]
  if not top then
    -- Stack is empty, there is not much we can do
    return formatTraceLine(afterFrame and "after " .. afterFrame:location() or SILE.currentlyProcessingFile or "<nowhere>")
  end
  local trace = top:location()
  local locationFrame = top
  -- Not all stack traces have to carry location information.
  -- If the first stack trace does not carry it, find a frame which does.
  -- Then append it, because its information may be useful.
  if not locationFrame.lno then
    for i = #self - 1, 1, -1 do
      if self[i].lno then
        locationFrame = self[i]
        trace = trace .. " near " .. locationFrame:location(locationFrame.file == top.file)
        break
      end
    end
  end
  -- Print after, if it is in a relevant file
  if afterFrame and (not locationFrame or afterFrame.file == locationFrame.file) then
    trace = trace .. " after " .. afterFrame:location(true)
  end
  return trace
end

-- Returns multiline trace string with locations of each frame up to maxdepth
function traceStack:locationTrace(maxdepth)
  local depth = maxdepth or #self
  local trace = formatTraceLine(self:locationHead())
  depth = depth - 1
  if depth > 1 then
    repeat
      trace = trace .. formatTraceLine(self[depth]:location())
      depth = depth - 1
    until depth == 1 -- stop at 1 (document) as not useful in trace
  end
  return trace
end

return traceStack
