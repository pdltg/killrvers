local game = {done = false,name = "ARDUINO KLUED QUEST",id = 3}

local port = "/dev/ttyACM0"
local baud = 9600

os.execute(string.format("stty -F %s %d raw -echo", port, baud))


local serial, err = io.open(port, "w")

if serial then
    
    serial:setvbuf("no") 
    

    serial:write("Hello World\n")
    serial:flush()
    

    serial:close()
else
    print("Error opening port: " .. tostring(err))
end

-- game code

function game.load()
    
end

function game.loop(dt)
    
end

function game.draw()
    
end

function game.drawui()
    
end

game.done = true

return game
