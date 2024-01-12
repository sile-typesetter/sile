local bits = SILE.parserBits

local passthroughCommands = {
  ftl = true,
  lua = true,
  math = true,
  raw = true,
  script = true,
  sil = true,
  use = true,
  xml = true
}

local isPassthrough = function (_, _, command)
  return passthroughCommands[command] or false
end

local isNotPassthrough = function (...)
  return not isPassthrough(...)
end

local isMatchingEndEnv = function (_, _, thisCommand, lastCommand)
  return thisCommand == lastCommand
end

-- luacheck: push ignore
---@diagnostic disable: undefined-global, unused-local, lowercase-global
local function grammar (_ENV)
  local _ = WS^0
  local eol = S"\r\n"
  local specials = S"\\{}%"
  local escaped_specials = P"\\" * specials
  local unescapeSpecials = function (str)
    return str:gsub('\\([{}%%\\])', '%1')
  end
  local myID = C(bits.silidentifier) / 1
  local cmdID = myID - P"begin" - P"end"
  local wrapper = function (a) return type(a)=="table" and a or {} end
  local parameters = (P"[" * bits.parameters * P"]")^-1 / wrapper

  local pass_end =
      P"\\end{" *
      ( cmdID * Cb"command" ) *
      ( P"}" * _ ) + E"Environment begun but never ended"
  local notpass_end =
      P"\\end{" *
      ( Cmt(cmdID * Cb"command", isMatchingEndEnv) + E"Environment mismatch") *
      ( P"}" * _ ) + E"Environment begun but never ended"

  env_passthrough_content = Cg(
      V"env_passthrough_text"
    )^0
  env_passthrough_text = C((1 - (P"\\end{" * Cmt(cmdID * Cb"command", isMatchingEndEnv) * P"}"))^1)
  passthrough_content = C(Cg(
      V"passthrough_text" +
      V"debraced_passthrough_text"
    )^0)
  passthrough_text = C((1-S("{}"))^1)
  debraced_passthrough_text = C(V"braced_passthrough_text")
  braced_passthrough_text = P"{" * V"passthrough_content" * ( P"}" + E("} expected") )

  START"document"
  document = V"content" * EOF"Unexpected character at end of input"
  content = Cg(
      V"environment" +
      V"comment" +
      V"text" +
      V"braced_content" +
      V"command"
    )^0
  environment =
    P"\\begin" *
    Cg(parameters, "options") *
    P"{" *
    Cg(cmdID, "command") *
    P"}" *
    (
      (Cmt(Cb"command", isPassthrough) * V"env_passthrough_content" * pass_end) +
      (Cmt(Cb"command", isNotPassthrough) * V"content" * notpass_end)
    )
  comment = C( P"%" * P(1-eol)^0 * eol^-1 / "" )
  text = C((1 - specials + escaped_specials)^1) / unescapeSpecials
  braced_content = P"{" * V"content" * ( P"}" + E("} expected") )
  command = (
      P"\\" *
      Cg(cmdID, "command") *
      Cg(parameters, "options") *
      (
        (Cmt(Cb"command", isPassthrough) * V"braced_passthrough_text") +
        (Cmt(Cb"command", isNotPassthrough) * V"braced_content")
      )^0
    )
end

return grammar
