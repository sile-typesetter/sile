-- Represents a stack of stack frame objects,
-- which describe the call-stack stack of the currently processed document.
-- Stack frames are stored contiguously, treating this object as an array.
-- Most recent and relevant stack frames are in higher indices, up to #traceStack.
-- Do not manipulate the stack directly, use provided push<Type> and pop methods.
-- There are different types of stack frames, see pushFrame for more details.
local traceStack = std.object {
  -- Stores the frame which was last popped. Reset after a push.
  -- Helps to further specify current location in the processed document.
  afterFrame = nil,

  defaultFrame = std.object {
    location = function(self, relative)
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
    end
  },

  defaultHelper = std.object {
    __tostring = function (self)
      self.file = nil
      self.lno = nil
      self.col = nil
      return #self > 0 and tostring(self) or ""
    end
  }

}

-- Internal: Given an collection of frames and an afterFrame, construct and return a human readable info string
-- about the location in processed document. Similar to _frameToLocationString, but takes into account
-- the afterFrame and the fact, that not all frames may carry a location information.
local function formatTraceHead(stack, afterFrame)
  local top = stack[#stack]
  if not top then
    -- Stack is empty, there is not much we can do
    return afterFrame and "after " .. afterFrame:location() or nil
  end
  local info = top:location()
  local locationFrame = top
  -- Not all stack traces have to carry location information.
  -- If the top stack trace does not carry it, find a frame which does.
  -- Then append it, because its information may be useful.
  if not top.lno then
    for i = #stack - 1, 1, -1 do
      if stack[i].lno then
        -- Found a frame which does carry some relevant information.
        locationFrame = stack[i]
        info = info .. " near " .. locationFrame:location(locationFrame.file == top.file)
        break
      end
    end
  end
  -- Print after, if it is in a relevant file
  if afterFrame and (not locationFrame or afterFrame.file == locationFrame.file) then
    info = info .. " after " .. afterFrame:location(true)
  end
  return info
end

function traceStack:pushDocument(file, sniff, document)
  local frame = self.defaultFrame {
    command = "document",
    file = file,
    sniff = sniff
  }
  setmetatable(frame, {
      __tostring = function(self) return "<file> (" .. self.sniff .. ")" end,
    })
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
  local frame = self.defaultFrame {
    command = command,
    file = content.file or SILE.currentlyProcessingFile,
    lno = content.lno,
    col = content.col,
    options = options or {}
  }
  setmetatable(frame, {
    __tostring = function(self)
      local options = (table.nitems(self.options) > 0 and tostring(self.options):gsub("^{", "["):gsub("}$", "]") or "")
      return "\\" .. self.command .. options
    end
  })
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
  local frame = self.defaultFrame {
      command = command,
      file = content.file or SILE.currentlyProcessingFile,
      lno = content.lno,
      col = content.col,
      options = content.options or {}
    }
  setmetatable(frame, {
    __tostring = function(self)
      local options = (table.nitems(self.options) > 0 and tostring(self.options):gsub("^{", "["):gsub("}$", "]") or "")
      return "\\" .. self.command .. options
    end
  })
  return self:pushFrame(frame)
end

-- Push a text that is going to get typeset on to the stack to record the execution trace for debugging.
-- Must be popped with `pop(returnOfPush)`.
function traceStack:pushText(text)
  local frame = self.defaultFrame {
    text = text
  }
  setmetatable(frame, {
    __tostring = function(self)
      local text = self.text
      if text:len() > 20 then
        text = text:sub(1, 18) .. "…"
      end
      text = text:gsub("\n", "␤"):gsub("\t", "␉"):gsub("\v", "␋")
      return '"' .. text .. '"'
    end
  })
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
  SU.debug("commandStack", string.rep(".", #self) .. "PUSH(" .. frame:location() .. ")")
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
    if SILE.traceback or SU.debugging("commandStack") then
      message = message .. ". Expected " .. popped.pushId .. " - (" .. popped:location() .. "), got " .. pushId
    end
    SU.warn(message, true)
  else
    -- Correctly balanced: pop the frame
    self.afterFrame = popped
    self[#self] = nil
    SU.debug("commandStack", string.rep(".", #self) .. "POP(" .. popped:location() .. ")")
  end
end

-- Internal: Call to create a fallback location information, when the stack is empty.
local function fallbackLocation()
  return SILE.currentlyProcessingFile or "<nowhere>"
end

-- Returns short string with most relevant location information for user messages.
function traceStack:locationInfo()
  return formatTraceHead(self, self.afterFrame) or fallbackLocation()
end

-- Returns multiline trace string, with full document location information for user messages.
function traceStack:locationTrace()
  local prefix = "\t"
  local trace = formatTraceHead({ self[#self] } --[[we handle rest of the stack ourselves]], self.afterFrame)
  if not trace then
    -- There is nothing else then
    return prefix .. fallbackLocation() .. "\n"
  end
  trace = prefix .. trace .. "\n"
  -- Iterate backwards, skipping the first (document) last (already displayed) elements
  for i = #self - 1, 2, -1 do
    trace = trace .. prefix .. self[i]:location() .. "\n"
  end
  return trace
end

return traceStack
