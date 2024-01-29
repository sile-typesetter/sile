local lpeg = require("lpeg")
local re = require("re")
local bits = require("core.parserbits")

local P, C, S = lpeg.P, lpeg.C, lpeg.S
local myID = C(bits.silidentifier) / 1

local wrapper = function (a) return type(a)=="table" and a or {} end
local specials = S"{}%\\"

local expression = [=[

document         <- texlike_stuff !.

texlike_stuff    <- {: environment / comment / texlike_text / texlike_braced_stuff / texlike_command :}*

environment      <- '\begin' {:options: %parameters :}
                   ('{' {:command: passthrough_cmd :} '}' passthrough_env_stuff pass_end /
                    '{' {:command: %cmdID :} '}' texlike_stuff notpass_end)

comment          <- ('%' (!%eol .)* %eol ) -> ''

texlike_text     <- { (!%specials . / %escaped_specials)+ } -> unescapeSpecials

texlike_braced_stuff <- '{' texlike_stuff '}'

texlike_command  <- '\' ({:command: passthrough_cmd :} {:options: %parameters :}
                    passthrough_braced_stuff / {:command: %cmdID :} {:options: %parameters :}
                    texlike_braced_stuff)

passthrough_cmd  <- 'ftl' / 'lua' / 'math' / 'raw' / 'script' / 'sil' / 'use' / 'xml'

passthrough_stuff <- { {: passthrough_text / passthrough_debraced_stuff :} }

passthrough_env_stuff <- {: passthrough_env_text :}*

passthrough_text <- { [^{}]+ }

passthrough_env_text <- { (!('\end{' =command '}') .)+ }

passthrough_braced_stuff <- '{' passthrough_stuff '}'

passthrough_debraced_stuff <- { passthrough_braced_stuff }

notpass_end <- '\end{' =command '}' _

pass_end <- '\end{' =command '}' _

_   <- %s*

]=]

local grammar = re.compile(expression, {
  unescapeSpecials = function (str)
    return str:gsub('\\([{}%%\\])', '%1')
  end,
  cmdID = myID - P"begin" - P"end",
  parameters = (P"[" * bits.parameters * P"]")^-1 / wrapper,
  eol = S"\r\n",
  specials = specials,
  escaped_specials = P"\\" * specials
})

local function parser (string)
  return re.match(string, grammar)
end

return parser
