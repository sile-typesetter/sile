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

  findBestBreak = function(vboxlist, target)
    local i
    local totalHeight = 0
    for i = 1,#vboxlist do local vbox = vboxlist[i]
      SU.debug("pagebuilder", "Dealing with VBox " .. vbox)
      if (vbox:isVbox()) then
        totalHeight = totalHeight + vbox.height + vbox.depth;
      elseif vbox:isVglue() then
        totalHeight = totalHeight + vbox.height.length;
      end
      local left = (target - totalHeight).length
      SU.debug("pagebuilder", "I have " .. tostring(left) .. "pts left");
      -- if (left < -20) then SU.error("\nCatastrophic page breaking failure!"); end 
      local pi = 0
      if vbox:isPenalty() then
        pi = vbox.penalty
      end 
      if vbox:isPenalty() and vbox.penalty < inf_bad  or vbox:isVglue() then
        local badness = left > 0 and left * left * left or awful_bad;
        local c
        if badness < awful_bad then 
          if pi <= eject_penalty then c = pi
          elseif badness < inf_bad then c = badness + pi -- plus insert
          else c = deplorable
          end
        else c = badness end

        SU.debug("pagebuilder", "Badness: "..c);
        if c == awful_bad or pi <= eject_penalty then
          SU.debug("pagebuilder", "outputting");
          -- Best break came at i-1
          local onepage = {}
          for j=1,i-1 do
            onepage[j] = table.remove(vboxlist,1)
          end
          return onepage, pi
        end
      end
    end
    return
  end,    
}