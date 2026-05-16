local game = {name = "Game Deleted", id = 404, done = false}

function game.load()
  
end

function game.loop()

end

function game.draw()

end

function game.drawui()
  love.graphics.print("This Game Was Deleted.", 0, 100)
end
    
game.done = true

return game
