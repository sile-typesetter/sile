SILE.require("packages/frametricks")
SILE.registerCommand("crop:setup", function (o,c)
  local papersize = SU.required(o, "papersize", "setting up crop marks")
  local size = SILE.paperSizeParser(papersize)
  local oldsize = SILE.documentState.paperSize
  SILE.documentState.paperSize = size
  local offsetx = ( SILE.documentState.paperSize[1] - oldsize[1] ) /2
  local offsety = ( SILE.documentState.paperSize[2] - oldsize[2] ) /2
  local page = SILE.getFrame("page")
  page:constrain("right", page:right() + offsetx)
  page:constrain("left", offsetx)
  page:constrain("bottom", page:bottom() + offsety)
  page:constrain("top", offsety)
  if SILE.scratch.masters then
    for k,v in pairs(SILE.scratch.masters) do
      reconstrainFrameset(v.frames)
    end
  else
    reconstrainFrameset(SILE.documentState.documentClass.pageTemplate.frames)
  end
  reconstrainFrameset(SILE.frames)
  if SILE.typesetter.frame then SILE.typesetter.frame:init() end
end)

function reconstrainFrameset(fs)
  for n,f in pairs(fs) do
    if n ~= "page" then
      if f:isAbsoluteConstraint("right") then
        f.constraints.right = "left(page) + (" .. f.constraints.right .. ")"
      end
      if f:isAbsoluteConstraint("left") then
        f.constraints.left = "left(page) + (" .. f.constraints.left .. ")"
      end
      if f:isAbsoluteConstraint("top") then
        f.constraints.top = "top(page) + (" .. f.constraints.top .. ")"
      end
      if f:isAbsoluteConstraint("bottom") then
        f.constraints.bottom = "top(page) + (" .. f.constraints.bottom .. ")"
      end
      f:invalidate()
    end
  end
end