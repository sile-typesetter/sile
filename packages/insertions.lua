SILE.scratch.insertions = {
  classes = {},
  thispage = {},
  nextpage = {}
}

local initInsertionClass = function (self, classname, options)
  SU.required(options, "insertInto", "initializing insertions")
  SU.required(options, "stealFrom", "initializing insertions")
  SU.required(options, "maxHeight", "initializing insertions")
  SU.required(options, "topSkip", "initializing insertions")

  SILE.scratch.insertions.classes[classname] = options
end

local reduceHeight = function(classname, amount)
  SU.debug("insertions", "Shrinking main box by "..amount.length)
  local opts = SILE.scratch.insertions.classes[classname]
  local reduceList = opts["stealFrom"]
  if type(reduceList) == "string" then reduceList = { reduceList } end
  local stealPosition = opts["steal-position"] or "bottom"
  for i = 1,#reduceList do local f = SILE.getFrame(reduceList[i])
    local newHeight = f:height() - amount.length
    f.height = function () return newHeight end
    -- This will have to change when cassowary is implemented
    if stealPosition == "bottom" then
      local newBottom = f:bottom() - amount.length
      f.bottom = function () return newBottom end
    else
      local newTop = f:top() - amount.length
      f.top = function () return newTop end
    end
  end
  local f = SILE.getFrame(opts["insertInto"])
  local newHeight = f:height() + amount.length
  f.height = function () return newHeight end
  if stealPosition == "bottom" then 
    local newTop = f:top() - amount.length
    f.top = function () return newTop end
  end
end

local addInsertion = function(classname, material)
  reduceHeight(classname, material.height + material.depth)
  if material:isVbox() then 
    material.height = SILE.length.new({ length =  0 })
  end
  table.insert(SILE.scratch.insertions.thispage[classname], material)
end

local heightSoFar = function(classname)
  local h = 0
  for i = 1,#(SILE.scratch.insertions.thispage[classname]) do 
    local ins = SILE.scratch.insertions.thispage[classname][i]
    h = h + ins.height.length + ins.depth
  end
  return h
end

local insert = function (self, classname, vbox)
  local thisclass = SILE.scratch.insertions.classes[classname]
  if not thisclass then SU.error("Uninitialized insertion class "..classname) end
  local opts = SILE.scratch.insertions.classes[classname]

  if not SILE.scratch.insertions.thispage[classname] then
    SILE.scratch.insertions.thispage[classname] = {}
    if thisclass["topSkip"] then
      local vglue = SILE.nodefactory.newVglue({ height = thisclass["topSkip"] })
      addInsertion(classname, vglue)
      -- HACK?
      local f = SILE.getFrame(opts["insertInto"])
      local newTop = f:top() + vglue.height.length
      f.top = function () return newTop end
    end
  end

  SU.debug("insertions", "Maxheight is "..thisclass["maxHeight"])
  SU.debug("insertions", "height is "..(heightSoFar(classname) + vbox.height + vbox.depth))
  if heightSoFar(classname) + vbox.height + vbox.depth < thisclass["maxHeight"] and
    ( (vbox.height + vbox.depth).length < 0 or
    true -- XXX "\pagetotal plus \pagedepth minus \pageshrink plus the effective
         -- size of the insertion should be less than \pagegoal"
    ) then
    addInsertion(classname, vbox)
  else
    SU.error("I need to split this insertion and I don't know how")
  end
end

local outputInsertions = function(self)

  for classname,vboxes in pairs(SILE.scratch.insertions.thispage) do
    local opts = SILE.scratch.insertions.classes[classname]
    local f = SILE.getFrame(opts["insertInto"])
    local t = SILE.defaultTypesetter {}
    t:init(f)
    for i = 1,#vboxes do 
      SU.debug("insertions", "Cursor now "..t.frame.state.cursorY)
      vboxes[i]:outputYourself(t,vboxes[i])
    end
    SILE.scratch.insertions.thispage[classname] = SILE.scratch.insertions.nextpage[classname]
  end
end

return {
  init = function () end,
  exports = {
    initInsertionClass = initInsertionClass,
    insert = insert,
    outputInsertions = outputInsertions
  }
}