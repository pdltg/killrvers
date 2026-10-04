game = {}

game.physics = [[
physics = {}
function physics.init()
    hello = createNewObject(0, 100, 900, 50, "anchored")
    cat = createNewObject(300, 0, 100, 100, "unanchored")
end
return physics
]]

game.client = [[
cli = {}
function cli.init()
end

function cli.update(dt)
end

function cli.draw()
    love.graphics.setColor(0.2, 0.8, 0.3)
    love.graphics.print("MULTIPLAYER TEST", 20, 20)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WASD / Arrow Keys = Move", 20, 45)
    love.graphics.print("Space = Jump", 20, 65)
    love.graphics.rectangle("fill", hello.x, hello.y, hello.w, hello.h)
    love.graphics.rectangle("fill", cat.x, cat.y, cat.w, cat.h)
end

function cli.drawui()
end
return cli
]]

return game
