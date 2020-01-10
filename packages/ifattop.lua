SILE.registerCommand("ifattop", function (_, content)
  SILE.typesetter:leaveHmode()
  if #(SILE.typesetter.state.outputQueue) == 0 then
    SILE.process(content)
  end
end)

SILE.registerCommand("ifnotattop", function (_, content)
  SILE.typesetter:leaveHmode()
  if #(SILE.typesetter.state.outputQueue) ~= 0 then
    SILE.process(content)
  end
end)
