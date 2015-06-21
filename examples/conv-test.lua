#!/usr/bin/env lua
local output = io.open(arg[2], "w+")
output:write("\\begin{document}\n")
for line in io.lines(arg[1]) do
  if(string.sub(line, 1, 2)=="= ") then
    output:write("\\center{"..string.sub(line, 3).."}")
  else
    output:write(line)
  end
  output:write("\n")
end
output:write("\\end{document}\n")
output:close()
