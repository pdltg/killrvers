local game = {done = false, name = "Procedural Laser Tower", id = 2}

-- Theme Colors for the Tower Sections
local zoneColors = {
    {0.2, 0.6, 1.0}, -- Blue Zone
    {0.9, 0.2, 0.6}, -- Pink Zone
    {0.2, 0.9, 0.4}, -- Neon Green Zone
    {1.0, 0.6, 0.0}, -- Orange Grid Zone
}

-- Master tables to pass tracking metrics back to the server
local platforms = {}
local hazards = {}

-- Moving elements internal table (Processed by loop)
local movingHazards = {}

-- Configuration settings for the infinite builder
local currentTowerHeight = 500 -- Starts near bottom, builds UPWARD (negative Y)
local towerFloorWidth = 600
local wallLeftX = 100
local wallRightX = 700

-- Helper function to instantiate platform blocks safely
local function spawnPlatform(x, y, w, h, color)
    local platform = {x = x, y = y, w = w, h = h, color = color}
    table.insert(platforms, platform)
    return platform
end

-- Helper function to instantiate static or moving kill parts
local function spawnHazard(x, y, w, h, speed, rangeX)
    local hazard = {x = x, y = y, w = w, h = h, color = {1, 0, 0}}
    table.insert(hazards, hazard)
    
    if speed and speed > 0 then
        table.insert(movingHazards, {
            data = hazard,
            startX = x,
            speed = speed,
            range = rangeX or 150,
            direction = 1
        })
    end
    return hazard
end

-- Procedural Stage Generation Function
local function buildNextFloor(floorNumber)
    local zoneIndex = math.min(math.ceil(floorNumber / 5), #zoneColors)
    local themeColor = zoneColors[zoneIndex] or {1, 1, 1}
    
    -- Raise the target assembly floor height
    currentTowerHeight = currentTowerHeight - 160
    local targetY = currentTowerHeight
    
    if floorNumber == 1 then
        -- Generate giant master assembly base plate floor
        spawnPlatform(400, 550, 800, 40, {0.2, 0.2, 0.25})
    end

    -- Randomly pick a structural layout for this floor variant
    local layoutPattern = math.random(1, 3)
    
    if layoutPattern == 1 then
        -- Layout 1: Split side ledges with a moving horizontal sweep laser in the center
        spawnPlatform(200, targetY, 150, 20, themeColor)
        spawnPlatform(600, targetY, 150, 20, themeColor)
        spawnHazard(400, targetY - 10, 30, 15, 120 + (floorNumber * 5), 180)

    elseif layoutPattern == 2 then
        -- Layout 2: Center island block flanked by static side spikes
        spawnPlatform(400, targetY, 200, 20, themeColor)
        spawnHazard(180, targetY + 30, 40, 15)
        spawnHazard(620, targetY + 30, 40, 15)

    elseif layoutPattern == 3 then
        -- Layout 3: Three ascending staircase steps with drop lasers between gaps
        spawnPlatform(250, targetY + 30, 90, 15, themeColor)
        spawnPlatform(400, targetY, 90, 15, themeColor)
        spawnPlatform(550, targetY - 30, 90, 15, themeColor)
        
        if floorNumber > 2 then
            spawnHazard(325, targetY + 40, 20, 10)
            spawnHazard(475, targetY + 10, 20, 10)
        end
    end
end

-- Generate the initial 15 floors of the obby on startup
for i = 1, 15 do
    buildNextFloor(i)
end

-- =================================================================
-- MASTER GAME LIFECYCLE HOOKS
-- =================================================================

function game.load()
    -- Initialize Server-authoritative physics boxes for regular platforms
    for _, p in ipairs(platforms) do
        if love and love.physics and world then
            p.body = love.physics.newBody(world, p.x, p.y, "static")
            p.shape = love.physics.newRectangleShape(p.w, p.h)
            p.fixture = love.physics.newFixture(p.body, p.shape)
        end
    end
    
    -- Initialize Server-authoritative physics boxes for Hazard items
    for _, h in ipairs(hazards) do
        if love and love.physics and world then
            -- Moving hazards use "kinematic" bodies so scripts can slide them safely without breaking gravity math
            local bodyType = "static"
            for _, m in ipairs(movingHazards) do
                if m.data == h then bodyType = "kinematic" break end
            end
            
            h.body = love.physics.newBody(world, h.x, h.y, bodyType)
            h.shape = love.physics.newRectangleShape(h.w, h.h)
            h.fixture = love.physics.newFixture(h.body, h.shape)
        end
    end
end

function game.loop(dt)
    -- 1. Sync block positions back from Box2D body tracking matrix
    for _, p in ipairs(platforms) do
        if p.body and p.body.getPosition then
            p.x, p.y = p.body:getPosition()
        end
    end

    -- 2. Process translation matrix mechanics for moving sweep lasers
    for _, m in ipairs(movingHazards) do
        if m.data.body and m.data.body.setLinearVelocity then
            local currentX, currentY = m.data.body:getPosition()
            
            -- Bounce direction flags if laser exits its custom horizontal range
            if currentX > m.startX + m.range then
                m.direction = -1
            elseif currentX < m.startX - m.range then
                m.direction = 1
            end
            
            -- Apply direct velocity changes through Box2D kinematic frames
            m.data.body:setLinearVelocity(m.speed * m.direction, 0)
            m.data.x, m.data.y = m.data.body:getPosition()
        end
    end

    -- 3. Run Context-Inverted Collision Checkers natively across the server thread
    for _, h in ipairs(hazards) do
        if h.body and h.body.getPosition then
            h.x, h.y = h.body:getPosition()
        end

        -- Evaluates dynamically against whichever player is currently checking collisions in the server update
        if checkCollision(plrrlp.x, plrrlp.y, plrrlp.w, plrrlp.h, h.x, h.y, h.w, h.h) then
            -- Triggers instant server-side context hook execution
            HurtPlayer(100) 
        end
    end
    
    -- 4. INFINITE GENERATION MACHINE: Check if player climbing height warrants generating a new floor
    -- If the proxy player position rises close to the top of our current map, spawn another floor
    if plrrlp and plrrlp.y < currentTowerHeight + 400 then
        local simulatedFloorCount = math.floor(math.abs(currentTowerHeight) / 160) + 1
        buildNextFloor(simulatedFloorCount)
        
        -- Instantly attach physics parameters onto the freshly generated blocks on the fly!
        local latestPlatform = platforms[#platforms]
        if love and love.physics and world and latestPlatform and not latestPlatform.body then
            latestPlatform.body = love.physics.newBody(world, latestPlatform.x, latestPlatform.y, "static")
            latestPlatform.shape = love.physics.newRectangleShape(latestPlatform.w, latestPlatform.h)
            latestPlatform.fixture = love.physics.newFixture(latestPlatform.body, latestPlatform.shape)
        end
    end
end

function game.draw()
    -- Client-side Render Logic: Draw climbing platforms
    for _, p in ipairs(platforms) do
        if p.color then love.graphics.setColor(unpack(p.color)) else love.graphics.setColor(1,1,1) end
        love.graphics.rectangle("fill", p.x - p.w/2, p.y - p.h/2, p.w, p.h)
    end
    
    -- Client-side Render Logic: Draw flashing hazard lasers
    for _, h in ipairs(hazards) do
        love.graphics.setColor(1, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", h.x - h.w/2, h.y - h.h/2, h.w, h.h)
    end
end

function game.drawui()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("GAME MODE: Infinite Laser Tower", 20, 210)
    
    -- Convert height metrics into an active scoreboard altitude readout
    local currentAltitude = math.max(0, math.floor((500 - plrrlp.y) / 10))
    love.graphics.print("Current Altitude: " .. currentAltitude .. " Studs", 20, 235)
end

game.done = true
return game
