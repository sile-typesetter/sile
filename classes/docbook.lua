local plain = SILE.require("plain", "classes")
docbook = plain { id = "docbook" }
SILE.scratch.docbook = {
  seclevel = 0,
  seccount = {}
}

docbook:loadPackage("image")
docbook:loadPackage("simpletable", {
  tableTag = "tgroup",
  trTag = "row",
  tdTag = "entry"
})

function docbook.push(t, val)
  if not SILE.scratch.docbook[t] then SILE.scratch.docbook[t] = {} end
  local q = SILE.scratch.docbook[t]
  q[#q+1] = val
end
function docbook.pop(t)
  local q = SILE.scratch.docbook[t]
  q[#q] = nil
end
function docbook.val(t)
  local q = SILE.scratch.docbook[t]
  return q[#q]
end
function docbook.wipe(tbl)
  while((#tbl) > 0) do tbl[#tbl] = nil end
end

SILE.registerCommand("article", function (options, content)
  local info = SILE.findInTree(content, "info") or SILE.findInTree(content, "articleinfo")
  local title = SILE.findInTree(content, "title") or (info and SILE.findInTree(info, "title"))
  local author = SILE.findInTree(content, "author") or (info and SILE.findInTree(info, "author"))

  if title then
    SILE.call("docbook-article-title",{},title)
    docbook.wipe(title)
  end
  if author then
    SILE.call("docbook-main-author",{},function()
      for _,t in ipairs(author) do
        if type(t) == "table" then
          SILE.call(t.tag,{},t)
          SILE.typesetter:leaveHmode()
          SILE.call("bigskip")
        end
      end
    end)
  end
  SILE.process(content)
  SILE.typesetter:chuck()
end)

SILE.registerCommand("info", function()end)

SILE.registerCommand("section", function (options, content)
  SILE.scratch.docbook.seclevel = SILE.scratch.docbook.seclevel + 1
  SILE.scratch.docbook.seccount[SILE.scratch.docbook.seclevel] = (SILE.scratch.docbook.seccount[SILE.scratch.docbook.seclevel] or 0) + 1
  while #(SILE.scratch.docbook.seccount) > SILE.scratch.docbook.seclevel do
    SILE.scratch.docbook.seccount[#(SILE.scratch.docbook.seccount)] = nil
  end
  local title = SILE.findInTree(content, "title")
  local number = table.concat(SILE.scratch.docbook.seccount, '.')
  if title then
    SILE.call("docbook-section-"..SILE.scratch.docbook.seclevel.."-title",{},function()
      SILE.typesetter:typeset(number.." ")
      SILE.process(title)
    end)
    docbook.wipe(title)
  end
  SILE.process(content)
  SILE.scratch.docbook.seclevel = SILE.scratch.docbook.seclevel - 1
end)

function countedThing(thing, options, content)
  SILE.call("increment-counter", {id=thing})
  SILE.call("bigskip")
  SILE.call("docbook-line")
  SILE.call("docbook-titling", {}, function()
    SILE.typesetter:typeset(thing.." ".. SILE.formatCounter(SILE.scratch.counters[thing]))
    local t = SILE.findInTree(content, "title")
    if t then
      SILE.typesetter:typeset(": ")
      SILE.process(t)
      docbook.wipe(t)
    end
  end)
  SILE.call("smallskip")
  SILE.process(content)
  SILE.call("docbook-line")
  SILE.call("bigskip")
end

SILE.registerCommand("example", function(options,content)
  countedThing("Example", options, content)
end)

SILE.registerCommand("table", function(options,content)
  countedThing("Table", options, content)
end)
SILE.registerCommand("figure", function(options, content)
  countedThing("Figure", options, content)
end)

SILE.registerCommand("imagedata", function(options, content)
  local width = SILE.parseComplexFrameDimension(options.width or "100%pw") or 0
  SILE.call("img", {
    src = options.fileref,
    width = width / 2
  })
end)


SILE.registerCommand("itemizedlist", function(options,content)
  docbook.push("list", {type = "itemized"})
  SILE.call("medskip")
  -- Indentation
  SILE.process(content)
  SILE.call("medskip")
  docbook.pop("list")
end)


SILE.registerCommand("orderedlist", function(options,content)
  docbook.push("list", {type = "ordered", ctr = 1})
  SILE.call("medskip")
  -- Indentation
  SILE.process(content)
  SILE.call("medskip")
  docbook.pop("list")
end)
SILE.registerCommand("listitem", function(options,content)
  local ctx = docbook.val("list")
  if ctx and ctx.type == "ordered" then
    SILE.typesetter:typeset( ctx.ctr ..". ")
    ctx.ctr = ctx.ctr + 1
  elseif ctx and ctx.type == "itemized" then
    SILE.typesetter:typeset( "• ")
  elseif ctx and ctx.type == "" then
    -- Other types?
  else
    SU.error("Listitem in outer space")
  end
  SILE.call("noindent")
  for i=1, #ctx-1 do SILE.call("qquad") end -- Setting lskip better?
  SILE.process(content)
  SILE.call("medskip")
end)

SILE.registerCommand("link", function(options, content)
  SILE.process(content)
  if (options["xl:href"]) then
    SILE.typesetter:typeset(" (")
    SILE.call("code", {}, {options["xl:href"]})
    SILE.typesetter:typeset(")")
  end
end)
return docbook
