game = {}

game.physics = [[
local playerSpeed = 220
local gravity = 900
local jumpPower = 420

function init()
    createNewObject(0, 550, 900, 50, "anchored")
    createNewObject(300, 450, 100, 100, "unanchored")
end

function input(player, input)
    player.vx = input.x * playerSpeed

    if input.jump and player.grounded then
        player.vy = -jumpPower
        player.grounded = false
    end
end

function step(dt)
    for _, player in pairs(getPlayers()) do
        player.vy = player.vy + gravity * dt

        player.x = player.x + player.vx * dt
        player.y = player.y + player.vy * dt

        if player.y + player.h / 2 >= 550 then
            player.y = 550 - player.h / 2
            player.vy = 0
            player.grounded = true
        end
    end

    for _, object in pairs(getObjects()) do
        if not object.anchored then
            object.vy = object.vy + gravity * dt
            object.y = object.y + object.vy * dt

            if object.y + object.h / 2 >= 550 then
                object.y = 550 - object.h / 2
                object.vy = 0
            end
        end
    end
end
]]

game.client = [[
function init()
end

function update(dt)
end

function draw()
    love.graphics.setColor(0.2, 0.8, 0.3)
    love.graphics.print("MULTIPLAYER TEST", 20, 20)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WASD / Arrow Keys = Move", 20, 45)
    love.graphics.print("Space = Jump", 20, 65)
end
]]

return game
