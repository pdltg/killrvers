local game={done=false,name="My Vibe Game",id=0}

-- objects
local obj1 = {x=180,y=400,w=40,h=640,coll=HC.rectangle(180,400,40,640)}
local obj2 = {x=780,y=740,w=1240,h=40,coll=HC.rectangle(780,740,1240,40)}
local obj4 = {x=1380,y=420,w=40,h=600,coll=HC.rectangle(1380,420,40,600)}
local obj5 = {x=500,y=620,w=40,h=200,coll=HC.rectangle(500,620,40,200)}
local obj6 = {x=980,y=620,w=40,h=200,coll=HC.rectangle(980,620,40,200)}
local obj8 = {x=740,y=320,w=680,h=400,coll=HC.rectangle(740,320,680,400)}
local obj9 = {x=740,y=320,w=600,h=320,coll=HC.rectangle(740,320,600,320)}

function game.load()
    if world==nil then
        print("world is nil!")
    else
    obj1.body=love.physics.newBody(world,obj1.x,obj1.y,"static")
    obj1.shape=love.physics.newRectangleShape(obj1.w,obj1.h)
    obj1.fixture=love.physics.newFixture(obj1.body,obj1.shape)
    obj2.body=love.physics.newBody(world,obj2.x,obj2.y,"static")
    obj2.shape=love.physics.newRectangleShape(obj2.w,obj2.h)
    obj2.fixture=love.physics.newFixture(obj2.body,obj2.shape)
    obj4.body=love.physics.newBody(world,obj4.x,obj4.y,"static")
    obj4.shape=love.physics.newRectangleShape(obj4.w,obj4.h)
    obj4.fixture=love.physics.newFixture(obj4.body,obj4.shape)
    obj5.body=love.physics.newBody(world,obj5.x,obj5.y,"static")
    obj5.shape=love.physics.newRectangleShape(obj5.w,obj5.h)
    obj5.fixture=love.physics.newFixture(obj5.body,obj5.shape)
    obj6.body=love.physics.newBody(world,obj6.x,obj6.y,"static")
    obj6.shape=love.physics.newRectangleShape(obj6.w,obj6.h)
    obj6.fixture=love.physics.newFixture(obj6.body,obj6.shape)
    obj8.body=love.physics.newBody(world,obj8.x,obj8.y,"static")
    obj8.shape=love.physics.newRectangleShape(obj8.w,obj8.h)
    obj8.fixture=love.physics.newFixture(obj8.body,obj8.shape)
    obj9.body=love.physics.newBody(world,obj9.x,obj9.y,"static")
    obj9.shape=love.physics.newRectangleShape(obj9.w,obj9.h)
    obj9.fixture=love.physics.newFixture(obj9.body,obj9.shape)
    end
end

function game.loop(dt)
    obj1.x,obj1.y=obj1.body:getPosition()
    obj2.x,obj2.y=obj2.body:getPosition()
    obj4.x,obj4.y=obj4.body:getPosition()
    obj5.x,obj5.y=obj5.body:getPosition()
    obj6.x,obj6.y=obj6.body:getPosition()
    obj8.x,obj8.y=obj8.body:getPosition()
    obj9.x,obj9.y=obj9.body:getPosition()
end

function game.draw()
    love.graphics.setColor(0.56,0.56,0.56)
    love.graphics.rectangle("fill",obj1.x-obj1.w/2,obj1.y-obj1.h/2,obj1.w,obj1.h)
    love.graphics.setColor(0.56,0.56,0.56)
    love.graphics.rectangle("fill",obj2.x-obj2.w/2,obj2.y-obj2.h/2,obj2.w,obj2.h)
    love.graphics.setColor(0.56,0.56,0.56)
    love.graphics.rectangle("fill",obj4.x-obj4.w/2,obj4.y-obj4.h/2,obj4.w,obj4.h)
    love.graphics.setColor(0.56,0.56,0.56)
    love.graphics.rectangle("fill",obj5.x-obj5.w/2,obj5.y-obj5.h/2,obj5.w,obj5.h)
    love.graphics.setColor(0.56,0.56,0.56)
    love.graphics.rectangle("fill",obj6.x-obj6.w/2,obj6.y-obj6.h/2,obj6.w,obj6.h)
    love.graphics.setColor(0.56,0.56,0.56)
    love.graphics.rectangle("fill",obj8.x-obj8.w/2,obj8.y-obj8.h/2,obj8.w,obj8.h)
    love.graphics.setColor(0.56,0.56,0.56)
    love.graphics.rectangle("fill",obj9.x-obj9.w/2,obj9.y-obj9.h/2,obj9.w,obj9.h)
end

function game.drawui()
    love.graphics.rectangle("line",100,1,10,10)
end

game.done=true
return game
