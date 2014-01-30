require("lxp.lom")
SILE.inputs.XML = {
  process = function (fn)
    local fh = io.open(fn)
    local t = lxp.lom.parse(fh:read("*all"))
    local root = SILE.documentState.documentClass == nil
    if root then
      if not(t.tag == "sile") then
        error("This isn't a SILE document!")
      end
      dclass = t.attr.class or "plain"
      SILE.documentState.documentClass = SILE.require("classes/"..dclass)
      for k,v in pairs(t.attr) do
        if SILE.documentState.documentClass.options[k] then
          SILE.documentState.documentClass.options[k](v)
        end
      end
      SILE.outputFilename= fn..".pdf"
      local ff = SILE.documentState.documentClass:init()
      SILE.typesetter:init(ff)
    end
    SILE.process = function(t)
      for k,v in ipairs(t) do
        if type(v) == "string" then
          SILE.typesetter:typeset(v)
        elseif SILE.Commands[v.tag] then
          SILE.Commands[v.tag](v.attr,v)
        else
          error("Unknown command "..v.tag)
        end
      end
    end
    SILE.process(t)
    if root then
      SILE.documentState.documentClass:finish()
    end
  end,
}