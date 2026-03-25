local game = {done = false,name = "Example Game",id = 0}

function game.load()
  print("filler")
end

function game.loop(dt)
  -- hello
end

function game.draw(pass)
  pass:plane(0, -100, 0)
end

return game
