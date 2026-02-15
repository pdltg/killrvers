local game = {}

local sing = {
    x = 50,
    y = 50,
    w = 1000,
    h = 20
}

function game.load()
    sing.body = love.physics.newBody(wold, sing.x, sing.y, "static")
    sing.shape = love.physics.newRectangleShape(sing.w, sing.h)
    sing.fixture = love.physics.newFixture(sing.body, sing.shape)
end

function game.loop(dt)

end

function game.draw()
    love.graphics.rectangle("fill", sing.x, sing.y, sing.w, sing.h)
end

function game.drawui()
    love.graphics.rectangle("line", 100, 1, 10, 10)
end

return game
