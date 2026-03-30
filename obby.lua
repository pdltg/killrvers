local game = {done = false, name = "Long Obby", id = 1}

-- CONFIG
local GRAVITY = 9.81
local DAMAGE_INTERVAL = 200
local LAVA_DAMAGE = 10

-- STATE
local platforms = {}
local hazards = {}
local movingPlatforms = {}
local checkpoints = {}
local currentCheckpoint = {x = 50, y = 50}
local finish = nil

local timer = 0

-- helpers (assumes you already have these in your engine)
-- checkCollision(ax,ay,aw,ah,bx,by,bw,bh)
-- HurtPlayer(amount)
-- RespawnPlayer(x,y)

--------------------------------------------------
-- PLATFORM / HAZARD CREATION HELPERS
--------------------------------------------------

local function createPlatform(x, y, w, h)
    local p = {
        x = x, y = y, w = w, h = h,
        coll = HC.rectangle(x, y, w, h)
    }
    if world then
        p.body = love.physics.newBody(world, x, y, "static")
        p.shape = love.physics.newRectangleShape(w, h)
        p.fixture = love.physics.newFixture(p.body, p.shape)
    end
    table.insert(platforms, p)
    return p
end

local function createHazard(x, y, w, h)
    local hzd = {
        x = x, y = y, w = w, h = h,
        coll = HC.rectangle(x, y, w, h)
    }
    if world then
        hzd.body = love.physics.newBody(world, x, y, "static")
        hzd.shape = love.physics.newRectangleShape(w, h)
        hzd.fixture = love.physics.newFixture(hzd.body, hzd.shape)
    end
    table.insert(hazards, hzd)
    return hzd
end

local function createMovingPlatform(x, y, w, h, pathLength, speed, horizontal)
    local mp = {
        x = x, y = y, w = w, h = h,
        baseX = x, baseY = y,
        pathLength = pathLength,
        speed = speed,
        t = 0,
        horizontal = horizontal,
        coll = HC.rectangle(x, y, w, h)
    }
    if world then
        mp.body = love.physics.newBody(world, x, y, "kinematic")
        mp.shape = love.physics.newRectangleShape(w, h)
        mp.fixture = love.physics.newFixture(mp.body, mp.shape)
    end
    table.insert(movingPlatforms, mp)
    return mp
end

local function createCheckpoint(x, y)
    local cp = {x = x, y = y, w = 20, h = 40}
    table.insert(checkpoints, cp)
    return cp
end

--------------------------------------------------
-- LEVEL LAYOUT
--------------------------------------------------

local function buildLevel()
    -- Start platform
    createPlatform(50, 100, 200, 20)
    currentCheckpoint = {x = 50, y = 50}

    -- Simple jumps
    createPlatform(300, 90, 120, 20)
    createPlatform(480, 80, 120, 20)
    createPlatform(660, 70, 120, 20)

    -- First hazard pit
    createHazard(420, 110, 200, 20)

    -- Checkpoint 1
    createCheckpoint(660, 40)

    -- Narrow platforms
    createPlatform(820, 60, 80, 15)
    createPlatform(940, 50, 80, 15)
    createPlatform(1060, 40, 80, 15)

    -- Lava strip under them
    createHazard(820, 90, 320, 20)

    -- Moving platforms section
    createMovingPlatform(1250, 80, 100, 15, 120, 40, true)   -- horizontal
    createMovingPlatform(1450, 70, 100, 15, 80, 30, false)   -- vertical
    createPlatform(1600, 60, 120, 20)

    -- Checkpoint 2
    createCheckpoint(1600, 30)

    -- Zig-zag platforms
    createPlatform(1750, 50, 100, 15)
    createPlatform(1870, 65, 100, 15)
    createPlatform(1990, 80, 100, 15)
    createPlatform(2110, 65, 100, 15)
    createPlatform(2230, 50, 100, 15)

    -- Lava floor under zig-zag
    createHazard(1750, 110, 600, 20)

    -- Tight jumps
    createPlatform(2400, 60, 60, 15)
    createPlatform(2520, 55, 60, 15)
    createPlatform(2640, 50, 60, 15)

    -- Moving platform over big lava pool
    createHazard(2400, 110, 400, 20)
    createMovingPlatform(2600, 80, 100, 15, 150, 50, true)

    -- Final stretch
    createPlatform(2800, 70, 120, 20)
    createPlatform(2950, 60, 120, 20)
    createPlatform(3100, 50, 120, 20)

    -- Finish platform
    finish = createPlatform(3250, 40, 200, 30)
end

--------------------------------------------------
-- LOAD
--------------------------------------------------

function game.load()
    if world == nil then
        print("world is nil – physics not initialized")
    end

    love.graphics.setBackgroundColor(0.2, 0.6, 1)

    platforms = {}
    hazards = {}
    movingPlatforms = {}
    checkpoints = {}
    finish = nil

    buildLevel()
end

--------------------------------------------------
-- LOOP
--------------------------------------------------

function game.loop(dt)
    timer = timer + dt * 1000

    -- Update moving platforms
    for _, mp in ipairs(movingPlatforms) do
        mp.t = mp.t + dt * mp.speed
        local offset = math.sin(mp.t) * mp.pathLength

        if mp.horizontal then
            mp.x = mp.baseX + offset
            mp.y = mp.baseY
        else
            mp.x = mp.baseX
            mp.y = mp.baseY + offset
        end

        if mp.body then
            mp.body:setPosition(mp.x, mp.y)
        end
    end

    -- Sync static platforms/hazards with physics bodies
    for _, p in ipairs(platforms) do
        if p.body then
            p.x, p.y = p.body:getPosition()
        end
    end
    for _, h in ipairs(hazards) do
        if h.body then
            h.x, h.y = h.body:getPosition()
        end
    end

    -- Player collision with hazards
    for _, h in ipairs(hazards) do
        if checkCollision(plrrlp.x, plrrlp.y, plrrlp.w, plrrlp.h,
                          h.x - h.w/2, h.y - h.h/2, h.w, h.h) then
            if timer > DAMAGE_INTERVAL then
                HurtPlayer(LAVA_DAMAGE)
                timer = 0
            end
        end
    end

    -- Checkpoints
    for _, cp in ipairs(checkpoints) do
        if checkCollision(plrrlp.x, plrrlp.y, plrrlp.w, plrrlp.h,
                          cp.x, cp.y, cp.w, cp.h) then
            currentCheckpoint.x = cp.x
            currentCheckpoint.y = cp.y - 20
        end
    end

    -- Finish
    if finish then
        if checkCollision(plrrlp.x, plrrlp.y, plrrlp.w, plrrlp.h,
                          finish.x - finish.w/2, finish.y - finish.h/2, finish.w, finish.h) then
            game.done = true
        end
    end

    -- Example: if you have a death condition elsewhere, call RespawnPlayer(currentCheckpoint.x, currentCheckpoint.y)
end

--------------------------------------------------
-- DRAW
--------------------------------------------------

function game.draw()
    -- Platforms
    love.graphics.setColor(1, 1, 1)
    for _, p in ipairs(platforms) do
        love.graphics.rectangle("fill", p.x - p.w/2, p.y - p.h/2, p.w, p.h)
    end

    -- Hazards (lava)
    love.graphics.setColor(1, 0, 0)
    for _, h in ipairs(hazards) do
        love.graphics.rectangle("fill", h.x - h.w/2, h.y - h.h/2, h.w, h.h)
    end

    -- Moving platforms (highlighted)
    love.graphics.setColor(0.2, 1, 0.2)
    for _, mp in ipairs(movingPlatforms) do
        love.graphics.rectangle("fill", mp.x - mp.w/2, mp.y - mp.h/2, mp.w, mp.h)
    end

    -- Checkpoints
    love.graphics.setColor(1, 1, 0)
    for _, cp in ipairs(checkpoints) do
        love.graphics.rectangle("fill", cp.x, cp.y, cp.w, cp.h)
    end

    -- Finish flag
    if finish then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", finish.x - finish.w/2, finish.y - finish.h/2, finish.w, finish.h)
        love.graphics.print("FINISH", finish.x - 25, finish.y - 30)
    end
end

--------------------------------------------------
-- UI
--------------------------------------------------

function game.drawui()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Checkpoint: (" .. math.floor(currentCheckpoint.x) .. ", " .. math.floor(currentCheckpoint.y) .. ")", 10, 10)
    love.graphics.print("Reach the end of the obby!", 10, 30)
end

game.done = true
return game
