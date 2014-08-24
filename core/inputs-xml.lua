require("lxp.lom")
SILE.inputs.XML = {
  process = function (fn)
    local fh = io.open(fn)
    local t = lxp.lom.parse(fh:read("*all"))
    local root = SILE.documentState.documentClass == nil
    if root then
      if not(t.tag == "sile") then
        SU.error("This isn't a SILE document!")
      end
      SILE.inputs.common.init(fn, t)
    end
    if SILE.Commands[t.tag] then
      SILE.Commands[t.tag](t.attr,t)
    else
      SILE.process(t)
    end
    if root and not SILE.preamble then
      SILE.documentState.documentClass:finish()
    end
  end,
}