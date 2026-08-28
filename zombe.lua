local game = {done = false, name = "Zombie Parkour Infiltration", id = 4}

-- Master structural tables to hold coordinate states
local platforms = {}
local hazards = {}

-- Active entities arrays
local bullets = {}
local zombies = {}
local gunAngle = 0
local playerScore = 0

local mapLength = 8000
local fieldFloorY = 520

-- Helper function to capture nearest multiplayer target variables
local function getNearestPlayer(zx, zy)
    local targetX, targetY = 400, 300
    local closestDist = 999999
    
    if networkPlayers then
        for name, data in pairs(networkPlayers) do
            local px, py = data.body:getPosition()
            local dist = math.abs(px - zx)
            if dist < closestDist then
                closestDist = dist
                targetX, targetY = px, py
            end
        end
        return targetX, targetY
    end
    
    if plrrlp and plrrlp.x then return plrrlp.x, plrrlp.y end
    return targetX, targetY
end

function game.load()
    -- Create master base field platform
    table.insert(platforms, {x = mapLength / 2, y = fieldFloorY, w = mapLength, h = 30, color = {0.2, 0.4, 0.2}})

    -- Procedurally map obstacles across the field length coordinates
    math.randomseed(54321)
    local currentX = 400
    while currentX < mapLength - 600 do
        local pillarW = math.random(70, 110)
        local pillarH = math.random(80, 260)
        local pillarY = fieldFloorY - (pillarH / 2) - 15
        
        table.insert(platforms, {x = currentX, y = pillarY, w = pillarW, h = pillarH, color = {0.35, 0.35, 0.4}})
        
        -- Generate zombie tracking profiles on top of the column ledges
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

    -- Hook static platform layout layers up with Box2D server metrics
    for _, p in ipairs(platforms) do
        if love and love.physics and world then
            p.body = love.physics.newBody(world, p.x, p.y, "static")
            p.shape = love.physics.newRectangleShape(p.w, p.h)
            p.fixture = love.physics.newFixture(p.body, p.shape)
        end
    end
end

function game.loop(dt)
    -- 1. Maintain block syncs with physics coordinates
    for _, p in ipairs(platforms) do
        if p.body and p.body.getPosition then p.x, p.y = p.body:getPosition() end
    end

    -- 2. Sweep the weapon barrel angles continuously
    gunAngle = gunAngle + (2.2 * dt)

    -- 3. Update Zombie Path Behaviors
    for _, z in ipairs(zombies) do
        if z.hp > 0 then
            local tx, ty = getNearestPlayer(z.x, z.y)
            local horizontalDistance = math.abs(tx - z.x)

            if horizontalDistance < 400 and math.abs(ty - z.y) < 200 then
                z.state = "hunting"
                if z.x < tx then z.x = z.x + (z.speed * dt) else z.x = z.x - (z.speed * dt) end
                if z.y < fieldFloorY - 45 then z.y = z.y + (300 * dt) end
            else
                z.state = "patrol"
                z.x = z.x + (z.speed * 0.4 * dt)
                if math.abs(z.x - z.originX) > z.range then z.speed = -z.speed end
            end

            -- REPLICATED DAMAGE EVALUATOR: Triggers when the server forces checkCollision to true
            if checkCollision() then
                _damageCooldown = (_damageCooldown or 0) - dt
                if _damageCooldown <= 0 then
                    HurtPlayer(20) -- Deals server-authorized damage
                    _damageCooldown = 1.0 
                end
            end
        end
    end

    -- 4. Vector Bullet Mechanics and Impact Checking
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + (b.vx * dt)
        b.y = b.y + (b.vy * dt)
        b.life = b.life - dt
        
        if b.life <= 0 then
            table.remove(bullets, i)
        else
            for _, z in ipairs(zombies) do
                -- Bullet bounding box test
                if z.hp > 0 and b.x > z.x - z.w/2 and b.x < z.x + z.w/2 and b.y > z.y - z.h/2 and b.y < z.y + z.h/2 then
                    z.hp = z.hp - 35
                    b.life = 0
                    if z.hp <= 0 then playerScore = playerScore + 100 end
                end
            end
        end
    end

    -- 5. REPLICATED FIRING SYSTEM (Bypasses love.mouse using the server network tokens)
    if plrrlp and plrrlp.wantsFire == 1 then
        _shotCooldown = (_shotCooldown or 0) - dt
        if _shotCooldown <= 0 then
            local gunRadius = 70
            local fireX = plrrlp.x + math.cos(gunAngle) * gunRadius
            local fireY = plrrlp.y + math.sin(gunAngle) * gunRadius
            
            local bulletSpeed = 950
            local vx = math.cos(gunAngle) * bulletSpeed
            local vy = math.sin(gunAngle) * bulletSpeed
            
            table.insert(bullets, {x = fireX, y = fireY, vx = vx, vy = vy, life = 1.8})
            _shotCooldown = 0.18 -- Snappy weapon click delay rates
        end
    else
        _shotCooldown = (_shotCooldown or 0) - dt
    end
    
    if _damageCooldown then _damageCooldown = _damageCooldown - dt end
end

function game.draw()
    -- Render platforms
    for _, p in ipairs(platforms) do
        if p.color then love.graphics.setColor(unpack(p.color)) else love.graphics.setColor(1, 1, 1) end
        love.graphics.rectangle("fill", p.x - p.w/2, p.y - p.h/2, p.w, p.h)
    end

    -- Render Zombies
    for _, z in ipairs(zombies) do
        if z.hp > 0 then
            if z.state == "hunting" then love.graphics.setColor(0.7, 0.1, 0.1) else love.graphics.setColor(0.15, 0.45, 0.2) end
            love.graphics.rectangle("fill", z.x - z.w/2, z.y - z.h/2, z.w, z.h)
            
            -- Zombie Health Line Bar rendering
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", z.x - 20, z.y - z.h/2 - 12, 40, 6)
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", z.x - 20, z.y - z.h/2 - 12, (z.hp / 100) * 40, 6)
        end
    end

    -- Render Bullets
    love.graphics.setColor(1, 0.9, 0.3)
    for _, b in ipairs(bullets) do love.graphics.circle("fill", b.x, b.y, 5) end

    -- Render Rotating Gun Barrels
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
end

game.done = true
return game
