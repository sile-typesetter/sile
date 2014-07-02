SILE.inputs.common = {
  init = function(fn, t)
    local dclass = t.attr.class or "plain"
    SILE.documentState.documentClass = SILE.require("classes/"..dclass)
    for k,v in pairs(t.attr) do
      if SILE.documentState.documentClass.options[k] then
        SILE.documentState.documentClass.options[k](v)
      end
    end
    SILE.outputFilename= string.gsub(fn,".sil$", ".pdf")
    local ff = SILE.documentState.documentClass:init()
    SILE.typesetter:init(ff)
  end
}

SILE.process = function(t)
  if type(t) == "function" then return t() end
  for k,v in ipairs(t) do
    if type(v) == "string" then
      SILE.typesetter:typeset(v)
    elseif SILE.Commands[v.tag] then
      SILE.Commands[v.tag](v.attr,v)
    else
      SU.error("Unknown command "..(v.tag or v.id))
    end
  end
end