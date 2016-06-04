SILE.registerCommand("ifattop", function (o, c)
  SILE.typesetter:leaveHmode()
  if #(SILE.typesetter.state.outputQueue) == 0 then
    SILE.process(c)
  end
end)

SILE.registerCommand("ifnotattop", function (o, c)
  SILE.typesetter:leaveHmode()
  if #(SILE.typesetter.state.outputQueue) ~= 0 then
    SILE.process(c)
  end
end)