local game = {done = false, name = "Difficulty Chart Obby", id = 1}

-- Difficulty Colors (Standard Obby Palette)
local colors = {
    {0.1, 0.8, 0.1}, -- Tier 1: Easy (Green)
    {1.0, 0.9, 0.0}, -- Tier 2: Normal (Yellow)
    {1.0, 0.5, 0.0}, -- Tier 3: Hard (Orange)
    {0.9, 0.1, 0.1}, -- Tier 4: Difficult (Red)
    {0.5, 0.0, 0.5}, -- Tier 5: Insane (Purple)
    {0.1, 0.1, 0.1}, -- Tier 6: Extreme (Black)
}

-- Tables to hold our many parts
local platforms = {}
local hazards = {}

-- Generator Settings
local stageCount = 60 -- Total number of stages
local partsPerStage = 4
local startX = 50
local startY = 500

-- Function to add a platform to our tracking table
local function addPlatform(x, y, w, h, color)
    table.insert(platforms, {x = x, y = y, w = w, h = h, color = color})
end

-- Function to add a hazard to our tracking table
local function addHazard(x, y, w, h)
    table.insert(hazards, {x = x, y = y, w = w, h = h})
end

-- Generate the "Very Long" Obby
local currentX = startX
local currentY = startY

for i = 1, stageCount do
    local tier = math.min(math.ceil(i / 10), #colors)
    local tierColor = colors[tier]
    
    -- Create a "Safe" Checkpoint Platform for every stage
    addPlatform(currentX, currentY, 150, 20, tierColor)
    currentX = currentX + 180
    
    -- Generate obstacles for this stage
    for p = 1, partsPerStage do
        -- Platform gets smaller as stages increase
        local pWidth = math.max(100 - (i * 1.2), 30)
        local gap = 80 + (i * 1.5) -- Gaps get wider
        
        -- Add a platform
        addPlatform(currentX, currentY, pWidth, 15, tierColor)
        
        -- Add a "Kill Part" (Laser/Lava) between platforms in later stages
        if i > 5 then
            addHazard(currentX - (gap/2), currentY + 5, 40, 10)
        end
        
        currentX = currentX + gap
        currentY = currentY + math.random(-20, 20) -- Slight height variation
    end
end

function game.load()
    -- Initialize Physics for Platforms
    for _, p in ipairs(platforms) do
        p.body = love.physics.newBody(world, p.x, p.y, "static")
        p.shape = love.physics.newRectangleShape(p.w, p.h)
        p.fixture = love.physics.newFixture(p.body, p.shape)
    end
    
    -- Initialize Physics for Hazards
    for _, h in ipairs(hazards) do
        h.body = love.physics.newBody(world, h.x, h.y, "static")
        h.shape = love.physics.newRectangleShape(h.w, h.h)
        h.fixture = love.physics.newFixture(h.body, h.shape)
    end
end

function game.loop(dt)
    -- Sync positions (for moving parts if added, though here they are static)
    for _, p in ipairs(platforms) do
        p.x, p.y = p.body:getPosition()
    end
    
    -- Collision logic for Hazards
    for _, h in ipairs(hazards) do
        h.x, h.y = h.body:getPosition()
        
        -- plrrlp and checkCollision are assumed globals from your engine
        if checkCollision(plrrlp.x, plrrlp.y, plrrlp.w, plrrlp.h, h.x, h.y, h.w, h.h) then
            if timer > 100 then
                HurtPlayer(100) -- Instant kill for difficulty chart
                timer = 0
            end
        end
    end
end

function game.draw()
    -- Draw Platforms
    for _, p in ipairs(platforms) do
        love.graphics.setColor(unpack(p.color))
        love.graphics.rectangle("fill", p.x - p.w/2, p.y - p.h/2, p.w, p.h)
    end
    
    -- Draw Hazards (Red)
    love.graphics.setColor(1, 0, 0)
    for _, h in ipairs(hazards) do
        love.graphics.rectangle("fill", h.x - h.w/2, h.y - h.h/2, h.w, h.h)
    end
end

function game.drawui()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Difficulty Chart Obby", 10, 10)
    
    -- Calculate progress based on player X position
    local progress = math.floor((plrrlp.x / currentX) * 100)
    love.graphics.print("Progress: " .. math.max(0, progress) .. "%", 10, 30)
end

game.done = true

return game
