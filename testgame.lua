local game = {done = false,name = "Example Game",id = 0}

-- game code

local sing = {
    x = 50,
    y = 100,
    w = 1000,
    h = 20,
    coll = HC.rectangle(sing.x,sing.y,sing.w,sing.h)
}

function game.load()
    if world == nil then
        print("weird bug. worked before like this and now it refuses to work. if this debug checker is not appearing. then love2d is broken beyond repair")
    else
        sing.body = love.physics.newBody(world, sing.x, sing.y, "static")
        sing.shape = love.physics.newRectangleShape(sing.w, sing.h)
        sing.fixture = love.physics.newFixture(sing.body, sing.shape)
    end
end

function game.loop(dt)
    sing.x,sing.y = sing.body:getPosition()
end

function game.draw()
    love.graphics.rectangle("fill", sing.x - sing.w/2, sing.y - sing.h/2, sing.w, sing.h)
end

function game.drawui()
    love.graphics.rectangle("line", 100, 1, 10, 10)
end

game.done = true

return game
