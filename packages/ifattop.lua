SILE.registerCommand("ifattop", function (options, content)
  SILE.typesetter:leaveHmode()
  if #(SILE.typesetter.state.outputQueue) == 0 then
    SILE.process(content)
  end
end)

SILE.registerCommand("ifnotattop", function (options, content)
  SILE.typesetter:leaveHmode()
  if #(SILE.typesetter.state.outputQueue) ~= 0 then
    SILE.process(content)
  end
end)
