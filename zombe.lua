local game = {done = false, name = "Zombie Parkour Infiltration", id = 4}

-- Master tables to map coordinates back to your engine server
local platforms = {}
local hazards = {}

-- Game element arrays
local bullets = {}
local zombies = {}
local gunAngle = 0
local playerScore = 0

-- Configuration Parameters
local mapLength = 8000
local fieldFloorY = 520
local maxZombies = 35

-- Helper function to find the nearest player on the server framework
local function getNearestPlayer(zx, zy)
    -- In multiplayer, players are tracked inside the global 'players' table on client,
    -- or 'networkPlayers' on the server. We parse dynamically depending on scope context.
    local closestName = nil
    local closestDist = 999999
    local targetX, targetY = 400, 300 -- Fallback center coordinates

    -- 1. Try evaluating server tracking arrays (networkPlayers)
    if networkPlayers then
        for name, data in pairs(networkPlayers) do
            local px, py = data.body:getPosition()
            local dist = math.abs(px - zx)
            if dist < closestDist then
                closestDist = dist
                targetX, targetY = px, py
                closestName = name
            end
        end
        return targetX, targetY, closestName
    end

    -- 2. Fallback to client proxy loops (plrrlp or players array)
    if plrrlp and plrrlp.x then
        return plrrlp.x, plrrlp.y, "Local"
    end
    return targetX, targetY, nil
end

function game.load()
    -- 1. Generate the main long ground plate
    table.insert(platforms, {x = mapLength / 2, y = fieldFloorY, w = mapLength, h = 30, color = {0.2, 0.4, 0.2}})

    -- 2. Procedurally generate tall parkour pillars across the field
    math.randomseed(54321) -- Keeps map layout identical on server and client
    local currentX = 400
    while currentX < mapLength - 600 do
        local pillarW = math.random(70, 110)
        local pillarH = math.random(80, 260)
        local pillarY = fieldFloorY - (pillarH / 2) - 15
        
        table.insert(platforms, {x = currentX, y = pillarY, w = pillarW, h = pillarH, color = {0.35, 0.35, 0.4}})
        
        -- Spawn a zombie on top of every column platform natively
        table.insert(zombies, {
            x = currentX,
            y = pillarY - (pillarH / 2) - 30,
            w = 50,
            h = 60,
            hp = 100,
            speed = math.random(50, 90),
            state = "patrol",
            originX = currentX,
            range = pillarW / 2
        })
        
        currentX = currentX + math.random(180, 260)
    end

    -- 3. Initialize server-authoritative physics boxes for regular platforms
    for _, p in ipairs(platforms) do
        if love and love.physics and world then
            p.body = love.physics.newBody(world, p.x, p.y, "static")
            p.shape = love.physics.newRectangleShape(p.w, p.h)
            p.fixture = love.physics.newFixture(p.body, p.shape)
        end
    end
    
    print("Obby field successfully populated with " .. #zombies .. " AI zombies.")
end

function game.loop(dt)
    -- 1. Sync static platform shapes from Box2D body matrices
    for _, p in ipairs(platforms) do
        if p.body and p.body.getPosition then
            p.x, p.y = p.body:getPosition()
        end
    end

    -- 2. Progress the weapon barrel rotation angle
    gunAngle = gunAngle + (2.2 * dt)

    -- 3. Run AI logic controllers for the active zombie array (Runs on Server updates)
    for _, z in ipairs(zombies) do
        if z.hp > 0 then
            -- Fetch the location vector coordinates of the nearest survival player
            local tx, ty, targetName = getNearestPlayer(z.x, z.y)
            local horizontalDistance = math.abs(tx - z.x)

            if horizontalDistance < 400 and math.abs(ty - z.y) < 200 then
                -- AGGRO HUNT MODE: Target player if they climb or walk nearby
                z.state = "hunting"
                if z.x < tx then z.x = z.x + (z.speed * dt) else z.x = z.x - (z.speed * dt) end
                
                -- Gravity pull fallback simulation for zombies tracking off pillar edges
                if z.y < fieldFloorY - 45 then z.y = z.y + (300 * dt) end
            else
                -- GENERAL PATROL MODE: Paces back and forth relative to pillar origin
                z.state = "patrol"
                z.x = z.x + (z.speed * 0.4 * dt)
                if math.abs(z.x - z.originX) > z.range then
                    z.speed = -z.speed -- Bounce directions
                end
            end

            -- Collision damage logic: If a zombie impacts a player, deduct health points dynamically
            if checkCollision(plrrlp.x - 50, plrrlp.y - 50, 100, 100, z.x - z.w/2, z.y - z.h/2, z.w, z.h) then
                -- HurtPlayer uses the server's context inversion hook to damage the correct player
                _damageCooldown = (_damageCooldown or 0) - dt
                if _damageCooldown <= 0 then
                    HurtPlayer(20) -- Inflicts 20 points of server damage
                    _damageCooldown = 1.0 -- 1 second damage internal cooldown rate
                end
            end
        end
    end

    -- 4. Move active bullet paths forward
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + (b.vx * dt)
        b.y = b.y + (b.vy * dt)
        b.life = b.life - dt
        
        if b.life <= 0 then
            table.remove(bullets, i)
        else
            -- Check for bullet hits against the zombie target collection
            for _, z in ipairs(zombies) do
                if z.hp > 0 and checkCollision(b.x - 4, b.y - 4, 8, 8, z.x - z.w/2, z.y - z.h/2, z.w, z.h) then
                    z.hp = z.hp - 35 -- Direct impact bullet damage
                    b.life = 0 -- Terminate projectile lifecycle
                    
                    if z.hp <= 0 then
                        playerScore = playerScore + 100 -- Award point tokens
                    end
                end
            end
        end
    end

    -- 5. Left-click input tracking system
    if love and love.mouse and love.mouse.isDown(1) then
        _shotCooldown = (_shotCooldown or 0) - dt
        if _shotCooldown <= 0 then
            local gunRadius = 70
            local fireX = plrrlp.x + math.cos(gunAngle) * gunRadius
            local fireY = plrrlp.y + math.sin(gunAngle) * gunRadius
            
            local bulletSpeed = 850
            local vx = math.cos(gunAngle) * bulletSpeed
            local vy = math.sin(gunAngle) * bulletSpeed
            
            table.insert(bullets, {x = fireX, y = fireY, vx = vx, vy = vy, life = 1.8})
            _shotCooldown = 0.20 -- Fast 200ms weapon fire rate threshold intervals
        end
    else
        _shotCooldown = (_shotCooldown or 0) - dt
    end
    
    if _damageCooldown then _damageCooldown = _damageCooldown - dt end
end

function game.draw()
    -- Client-side Render Logic: Draw all ground surfaces and pillars
    for _, p in ipairs(platforms) do
        if p.color then love.graphics.setColor(unpack(p.color)) else love.graphics.setColor(1, 1, 1) end
        love.graphics.rectangle("fill", p.x - p.w/2, p.y - p.h/2, p.w, p.h)
    end

    -- Client-side Render Logic: Draw the AI Zombies (Sickly Dark Green Shapes)
    for _, z in ipairs(zombies) do
        if z.hp > 0 then
            -- Change visibility color tone if zombie enters aggro hunt states
            if z.state == "hunting" then
                love.graphics.setColor(0.7, 0.1, 0.1) -- Alert hunting red tint
            else
                love.graphics.setColor(0.15, 0.45, 0.2) -- Normal green
            end
            
            love.graphics.rectangle("fill", z.x - z.w/2, z.y - z.h/2, z.w, z.h)
            
            -- Render a miniature zombie health line indicator bar above their bounds head area
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", z.x - 20, z.y - z.h/2 - 12, 40, 6)
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", z.x - 20, z.y - z.h/2 - 12, (z.hp / 100) * 40, 6)
        end
    end

    -- Client-side Render Logic: Draw high speed glowing projectile bullets
    love.graphics.setColor(1, 0.9, 0.3)
    for _, b in ipairs(bullets) do
        love.graphics.circle("fill", b.x, b.y, 5)
    end

    -- Client-side Render Logic: Draw the line weapon assembly tracking player center coordinates
    if plrrlp and plrrlp.x then
        local gunRadius = 70
        local gunX = plrrlp.x + math.cos(gunAngle) * gunRadius
        local gunY = plrrlp.y + math.sin(gunAngle) * gunRadius
        
        love.graphics.setLineWidth(7 * (scale or 1))
        love.graphics.setColor(0.25, 0.25, 0.28)
        love.graphics.line(plrrlp.x, plrrlp.y, gunX, gunY)
        
        love.graphics.setColor(1, 0.4, 0)
        love.graphics.circle("fill", gunX, gunY, 9 * (scale or 1))
        love.graphics.setLineWidth(1)
    end
end

function game.drawui()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("MISSION INSTANCE: Zombie Obby Field", 20, 210)
    love.graphics.print("Survival Score Accumulation: " .. playerScore .. " PTS", 20, 235)
    love.graphics.print("Alert Status: Keep high ground! Zombies track player height alignments.", 20, 260)
end

game.done = true
return game
