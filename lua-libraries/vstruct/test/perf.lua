-- Test vstruct performance.

local vstruct = require "vstruct"
local read,write = vstruct.read,vstruct.write

local SIZE = 2^14

local data = {
  strings = {};
  numbers = {};
  booleans = {};
  masks = {};
}

for i=1,SIZE do
  data.strings[i] = "xxxx"
  data.numbers[i] = i
  data.booleans[i] = i % 2 == 0
  data.masks[i] = { true, true, false, true, false, false, true, true }
end

local function perf(format, data, file)
  format = '@0 ' .. SIZE .. ' * ' .. format
  local wstart,rstart,stop
  if not file then
    wstart = os.clock()
    local buf = write(format, data)
    rstart = os.clock()
    read(format, buf)
    stop = os.clock()
  else
    local fd = io.open(file, 'w+')
    wstart = os.clock()
    write(format, fd, data)
    rstart = os.clock()
    read(format, fd)
    stop = os.clock()
    fd:close()
  end
  return stop - rstart,rstart - wstart
end

local wtotal,rtotal = 0,0

local function report(format, read, write)
  print(("%4s%8.4f%8.4f"):format(format, read, write))
  rtotal = rtotal + read
  wtotal = wtotal + write
end

local formats = {
  strings = {'c', 's', 'z'};
  numbers = {'f', 'i', 'p8,', 'u'};
  booleans = {'b'};
  masks = {'m'};
}

for _,file in ipairs { false, "/tmp/vstruct_perf" } do
  if file then print('---- using file ----')
  else print('---- using string ----') end
  for type,formats in pairs(formats) do
    for _,format in ipairs(formats) do
      for _,size in ipairs { 4, 8 } do
        report(format..size, perf(format..size, data[type], file))
      end
    end
  end
end
print('---- -----')
print("total", rtotal, wtotal)
