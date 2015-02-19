local awful_bad = 1073741823
local inf_bad = 10000
local eject_penalty = -inf_bad
local deplorable = 100000

SILE.pagebuilder = {
  collateVboxes = function(vboxlist)
    local i
    local output = SILE.nodefactory.newVbox({nodes = {} })
    local h = SILE.length.new({})
    for i=1,#vboxlist do
      table.insert(output.nodes, vboxlist[i])
      h = h + vboxlist[i].height + vboxlist[i].depth
    end
    output.ratio = 1
    output.height = h
    output.depth = 0
    return output
  end,

  badness = function (t,s)
    local bad = 100 * (t/s)^3
    bad = math.floor(bad) -- TeX uses integer math for this stuff, so for compatibility...

    if bad > inf_bad then return inf_bad else return bad end
  end,

  findBestBreak = function(vboxlist, target)
    local i
    local totalHeight = SILE.length.new()
    local bestBreak = nil
    local leastC = inf_bad
    SU.debug("pagebuilder", "Page builder called with "..#vboxlist.." nodes, "..target)
    for i = 1,#vboxlist do local vbox = vboxlist[i]
      SU.debug("pagebuilder", "Dealing with VBox " .. vbox)
      if (vbox:isVbox()) then
        totalHeight = totalHeight + vbox.height + vbox.depth;
      elseif vbox:isVglue() then
        totalHeight = totalHeight + vbox.height
      end
      local left = target - totalHeight.length
      SU.debug("pagebuilder", "I have " .. tostring(left) .. "pts left");
      -- if (left < -20) then SU.error("\nCatastrophic page breaking failure!"); end 
      local pi = 0
      if vbox:isPenalty() then
        pi = vbox.penalty
      end 
      if vbox:isPenalty() and vbox.penalty < inf_bad  or (vbox:isVglue() and i > 1 and not vboxlist[i-1]:isDiscardable()) then
        local badness
        if totalHeight.length < target then -- TeX #1039
          -- Account for infinite stretch?
          badness = SILE.pagebuilder.badness(left, totalHeight.stretch)
        elseif left < totalHeight.shrink then badness = awful_bad
        else badness = SILE.pagebuilder.badness(-left, totalHeight.shrink)
        end

        local c
        if badness < awful_bad then 
          if pi <= eject_penalty then c = pi
          elseif badness < inf_bad then c = badness + pi -- plus insert
          else c = deplorable
          end
        else c = badness end
        if c < leastC then
          leastC = c
          bestBreak = i
        end
        SU.debug("pagebuilder", "Badness: "..c);
        if c == awful_bad or pi <= eject_penalty then
          SU.debug("pagebuilder", "outputting");
          local onepage = {}
          if not bestBreak then bestBreak = i-1 end
          for j=1,bestBreak do
            onepage[j] = table.remove(vboxlist,1)
          end
          return onepage, pi
        end
      end
    end
    SU.debug("pagebuilder", "No page break here")
    return
  end,    
}