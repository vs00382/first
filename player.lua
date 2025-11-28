local C = require 'constants'
local Player = {}

function Player.load()
    Player.x = 5 * C.TILE_SIZE
    Player.y = 5 * C.TILE_SIZE
    Player.speed = 200
    Player.facing = 'down'
    Player.energy = 100
    Player.max_energy = 100
    Player.water = 10
    Player.max_water = 10
    Player.current_tool = 1
    
    Player.inventory = {
        money = 50,
        seeds_wheat = 5,
        seeds_corn = 2,
        wheat = 0,
        corn = 0
    }
end

function Player.update(dt)
    local moving = false
    local next_x, next_y = Player.x, Player.y

    if love.keyboard.isDown('w', 'up') then
        next_y = next_y - Player.speed * dt
        Player.facing = 'up'
    elseif love.keyboard.isDown('s', 'down') then
        next_y = next_y + Player.speed * dt
        Player.facing = 'down'
    end

    if love.keyboard.isDown('a', 'left') then
        next_x = next_x - Player.speed * dt
        Player.facing = 'left'
    elseif love.keyboard.isDown('d', 'right') then
        next_x = next_x + Player.speed * dt
        Player.facing = 'right'
    end

    -- Collision
    if next_x >= 0 and next_x <= (C.MAP_WIDTH * C.TILE_SIZE) - C.TILE_SIZE then Player.x = next_x end
    if next_y >= 0 and next_y <= (C.MAP_HEIGHT * C.TILE_SIZE) - C.TILE_SIZE then Player.y = next_y end
end

function Player.draw()
    -- Draw Player Body
    love.graphics.setColor(C.COLORS.player)
    love.graphics.circle("fill", Player.x + C.TILE_SIZE/2, Player.y + C.TILE_SIZE/2, C.TILE_SIZE/2 - 2)
    
    -- Draw Facing Dot
    love.graphics.setColor(1, 1, 1, 0.5)
    local dx, dy = 0, 0
    if Player.facing == 'up' then dy = -20
    elseif Player.facing == 'down' then dy = 20
    elseif Player.facing == 'left' then dx = -20
    elseif Player.facing == 'right' then dx = 20
    end
    love.graphics.circle("fill", Player.x + C.TILE_SIZE/2 + dx, Player.y + C.TILE_SIZE/2 + dy, 5)
end

function Player.switchTool()
    Player.current_tool = Player.current_tool + 1
    if Player.current_tool > #C.TOOLS then Player.current_tool = 1 end
end

return Player