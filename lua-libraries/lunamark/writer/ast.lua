-- Return an abstract syntax tree

local M = {}

local format = string.format
local util = require("lunamark.util")
local generic = require("lunamark.writer.generic")
local entities = require("lunamark.entities")

function M.new(options)
  local options = options or {}
  local AST = generic.new(options)

  function AST.merge(result)
    local function walk(t)
      local out = {}
      for i = 1,#t do
        local typ = type(t[i])
        if typ == "string" and #t[i] > 0 then
          if type(out[#out]) == "string" then
            out[#out] = out[#out] .. t[i]
          else
            out[#out+1] = t[i]
          end
        elseif typ == "table" then
          out[#out+1] = walk(t[i])
          out[#out].tag = t[i].tag
          -- Copy attributes
          for key,value in pairs(t[i]) do
            if type(key)=="string" then out[#out][key] = value end
          end
        elseif typ == "function" then
          out[#out+1] = t[i]()
        end
      end
      return out
    end
    return walk(result)
    -- return result
  end

  AST.genericCommand = function(name) return function(s)
      local node = { tag = name }
      node[1] = s
      return node
    end
  end

  AST.strong = AST.genericCommand("strong")
  AST.paragraph = AST.genericCommand("paragraph")
  AST.code = AST.genericCommand("code")
  AST.emphasis = AST.genericCommand("emphasis")
  AST.blockquote = AST.genericCommand("blockquote")
  AST.verbatim = AST.genericCommand("verbatim")
  AST.header = function (s,level)
    return (AST.genericCommand("sect"..level))(s)
  end
  AST.listitem = AST.genericCommand("listitem")
  AST.bulletlist = function (items)
    local node = {tag = "bulletlist"}
    for i=1,#items do node[i] = AST.listitem(items[i]) end
    return node
  end
  AST.link = function(lab, src, tit)
    return { [1] = lab, tag = "link", href = src }
  end
  AST.image = function(lab, src, tit)
    return { tag = "image", src=src, [1]=lab }
  end
  return AST
end

return M
