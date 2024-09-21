local base = require("inputters.base")

local _variant = "epnf"
local parser
local function load_parser ()
   parser = require("inputters.sil-" .. _variant)
end

local inputter = pl.class(base)
inputter._name = "sil"

inputter.order = 50

inputter.appropriate = function (round, filename, doc)
   if not parser then
      load_parser()
   end
   if round == 1 then
      return filename:match(".sil$")
   elseif round == 2 then
      local sniff = doc:sub(1, 100)
      local promising = sniff:match("\\begin") or sniff:match("\\document") or sniff:match("\\sile")
      return promising and inputter.appropriate(3, filename, doc) or false
   elseif round == 3 then
      local status, _ = pcall(parser, doc)
      return status
   end
end

function inputter:_init (options)
   options = options or {}
   if options.variant then
      _variant = options.variant
      load_parser()
   else
      if not parser then
         load_parser()
      end
   end
   -- Save time when parsing strings by only setting up the grammar once per
   -- instantiation then re-using it on every use.
   self._parser = parser
   base._init(self)
end

local linecache = {}
local lno, col, lastpos
local function resetCache ()
   lno = 1
   col = 1
   lastpos = 0
   linecache = { { lno = 1, pos = 1 } }
end

local function getline (str, pos)
   local start = 1
   lno = 1
   if pos > lastpos then
      lno = linecache[#linecache].lno
      start = linecache[#linecache].pos + 1
      col = 1
   else
      for j = 1, #linecache - 1 do
         if linecache[j + 1].pos >= pos then
            lno = linecache[j].lno
            col = pos - linecache[j].pos
            return lno, col
         end
      end
   end
   for i = start, pos do
      if string.sub(str, i, i) == "\n" then
         lno = lno + 1
         col = 1
         linecache[#linecache + 1] = { pos = i, lno = lno }
         lastpos = i
      end
      col = col + 1
   end
   return lno, col
end

local function ast_from_parse_tree (tree, doc, depth)
   if type(tree) == "string" then
      return tree
   end

   if tree.pos then
      tree.lno, tree.col = getline(doc, tree.pos)
      tree.pos = nil
   end

   local sep -- luacheck: ignore 211
   if SU.debugging("inputter") then
      depth = depth + 1
      sep = ("   "):rep(depth)
   end
   SU.debug("inputter", sep and (sep .. "Processing ID:"), tree.id)

   local res
   if tree.id == "comment" then
      -- Drop comments
      SU.debug("inputter", sep and (sep .. "Discarding comment"))
      res = {}
   elseif
      false
      or tree.id == "document"
      or tree.id == "braced_content"
      or tree.id == "passthrough_content"
      or tree.id == "braced_passthrough_content"
      or tree.id == "env_passthrough_content"
      or tree.id == "text"
      or tree.id == "passthrough_text"
      or tree.id == "braced_passthrough_text"
      or tree.id == "env_passthrough_text"
   then
      -- These nodes have only one child, which needs recursion.
      SU.debug("inputter", sep and (sep .. "Massaging a node"))
      res = ast_from_parse_tree(tree[1], doc, depth)
      --res = #res > 1 and not res.id and res or res[1]
   elseif false or tree.id == "environment" or tree.id == "command" then
      -- These nodes have multiple children, which need recursion.
      SU.debug("inputter", sep and (sep .. "Processing command"), tree.command, #tree, "subtrees")
      local newtree = { -- I don't think we can avoid a shallow copy here
         command = tree.command,
         options = tree.options,
         id = tree.id,
         lno = tree.lno,
         col = tree.col,
      }
      for _, node in ipairs(tree) do
         if type(node) == "table" then
            SU.debug("inputter", sep and (sep .. " -"), node.id or "table")
            local ast_node = ast_from_parse_tree(node, doc, depth)
            if type(ast_node) == "table" and not ast_node.id then
               SU.debug("inputter", sep and (sep .. " -"), "Collapsing subtree")
               -- Comments can an empty table, skip them
               if #ast_node > 0 then
                  -- Simplify the tree if it's just a plain list
                  for _, child in ipairs(ast_node) do
                     if type(child) ~= "table" or child.id or #child > 0 then
                        table.insert(newtree, child)
                     end
                  end
               end
            else
               table.insert(newtree, ast_node)
            end
         end
         -- Non table nodes are skipped (e.g. extraneous text from 'raw' commands)
      end
      res = newtree
   elseif tree.id == "content" then
      -- This node has multiple children, which need recursion
      -- And the node itself needs to be replaced with its children
      SU.debug("inputter", sep and (sep .. "Massage content node"), #tree, "subtrees")
      local newtree = {} -- I don't think we can avoid a shallow copy here
      for i, node in ipairs(tree) do
         SU.debug("inputter", sep and (sep .. " -"), node.id)
         newtree[i] = ast_from_parse_tree(node, doc, depth)
      end
      -- Simplify the tree if it has only one child
      res = #newtree == 1 and not newtree.id and newtree[1] or newtree
   elseif tree.id then
      -- Shouldn't happen, or we missed something
      SU.error("Unknown node type: " .. tree.id)
   else
      SU.debug("inputter", sep and (sep .. "Table node"), #tree, "subtrees")
      res = #tree == 1 and tree[1] or tree
   end
   SU.debug("inputter", sep and (sep .. "Returning a"), type(res) == "table" and res.id or "string")
   return res
end

function inputter:parse (doc)
   local status, result = pcall(self._parser, doc)
   if not status then
      return SU.error(([[Unable to parse input document to an AST tree. Parser error:

%s  thrown from document beginning]]):format(pl.stringx.indent(result, 6)))
   end
   resetCache()
   local top = ast_from_parse_tree(result[1], doc, 0)
   local tree
   -- Content not part of a tagged command could either be part of a document
   -- fragment or junk (e.g. comments, whitespace) outside of a document tag. We
   -- need to either capture the document tag only or decide this is a fragment
   -- and wrap it in a document tag.
   if top.command == "document" or top.command == "sile" then
      tree = top
   elseif type(top) == "table" then
      for _, leaf in ipairs(top) do
         if leaf.command and (leaf.command == "document" or leaf.command == "sile") then
            tree = leaf
            break
         end
      end
   end
   -- In the event we didn't isolate a top level document tag above, assume this
   -- is a fragment and wrap it in one.
   if not tree then
      tree = { top, command = "document" }
   end
   return { tree }
end

return inputter
