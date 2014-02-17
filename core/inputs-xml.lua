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
      SILE.inputs.common.init(fn, t)
    end
    SILE.process(t)
    if root then
      SILE.documentState.documentClass:finish()
    end
  end,
}