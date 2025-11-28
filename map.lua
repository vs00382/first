local C = require 'constants'
local Map = {}

function Map.load()
    Map.grid = {}
    Map.crops = {}
    Map.particles = {}
    Map.is_raining = false
    Map.season = 1

    -- Initialize Grid
    for y = 0, C.MAP_HEIGHT - 1 do
        Map.grid[y] = {}
        for x = 0, C.MAP_WIDTH - 1 do
            if x > 15 and y > 10 then Map.grid[y][x] = 3      -- Pond
            elseif x < 4 and y < 3 then Map.grid[y][x] = 4    -- Shop
            elseif x < 3 and y > 11 then Map.grid[y][x] = 5   -- House
            else Map.grid[y][x] = 1 end                       -- Grass
        end
    end
end

function Map.updateCrops(dt)
    for k, crop in pairs(Map.crops) do
        -- No growth in winter (season 4)
        if Map.season ~= 4 and crop.watered and crop.stage < 3 then
            crop.timer = crop.timer + dt
            local time_needed = (crop.type == "corn") and 6 or 3
            if crop.timer > time_needed then
                crop.stage = crop.stage + 1
                crop.timer = 0
                crop.watered = false
            end
        end
    end
end

function Map.updateParticles(dt)
    for i = #Map.particles, 1, -1 do
        local p = Map.particles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.life = p.life - dt
        if p.life <= 0 or p.y > 600 then table.remove(Map.particles, i) end
    end
end

function Map.spawnRain()
    if math.random() < 0.4 then
        table.insert(Map.particles, {
            x = math.random(0, 800),
            y = -10,
            dx = -20,
            dy = 300,
            life = 2,
            size = 2,
            color = C.COLORS.rain,
            type = "rain"
        })
    end
end

function Map.createDust(x, y, color)
    for i=1, 5 do
        table.insert(Map.particles, {
            x = x + math.random(-10, 10),
            y = y + math.random(-10, 10),
            dx = math.random(-50, 50),
            dy = math.random(-50, 50),
            life = 0.5 + math.random() * 0.5,
            size = math.random(2, 5),
            color = color,
            type = "dust"
        })
    end
end

function Map.draw()
    -- Draw Terrain
    local grassColor = C.COLORS.seasons[Map.season]
    for y = 0, C.MAP_HEIGHT - 1 do
        for x = 0, C.MAP_WIDTH - 1 do
            local tileType = Map.grid[y][x]
            local px, py = x * C.TILE_SIZE, y * C.TILE_SIZE

            if tileType == 1 then love.graphics.setColor(grassColor)
            elseif tileType == 2 then love.graphics.setColor(C.COLORS.soil)
            elseif tileType == 3 then love.graphics.setColor(C.COLORS.water)
            elseif tileType == 4 then love.graphics.setColor(C.COLORS.shop)
            elseif tileType == 5 then love.graphics.setColor(C.COLORS.house_floor)
            end
            love.graphics.rectangle("fill", px, py, C.TILE_SIZE, C.TILE_SIZE)
            love.graphics.setColor(0, 0, 0, 0.1)
            love.graphics.rectangle("line", px, py, C.TILE_SIZE, C.TILE_SIZE)
        end
    end

    -- Draw Crops
    for key, crop in pairs(Map.crops) do
        local x, y = string.match(key, "(%d+),(%d+)")
        x, y = tonumber(x), tonumber(y)
        local px, py = x * C.TILE_SIZE, y * C.TILE_SIZE

        if crop.watered then
            love.graphics.setColor(C.COLORS.soil_wet)
            love.graphics.rectangle("fill", px, py, C.TILE_SIZE, C.TILE_SIZE)
        end

        local cTable = (crop.type == "corn") and C.COLORS.crops.corn or C.COLORS.crops.wheat
        love.graphics.setColor(cTable[crop.stage])

        local cx, cy = px + C.TILE_SIZE/2, py + C.TILE_SIZE/2
        if crop.type == "corn" then
            local h = 5 + (crop.stage * 8)
            love.graphics.rectangle("fill", cx - 4, cy - h/2, 8, h)
        else
            local r = 2 + (crop.stage * 4)
            love.graphics.circle("fill", cx, cy, r)
        end
    end

    -- Draw Particles
    for _, p in ipairs(Map.particles) do
        love.graphics.setColor(p.color)
        if p.type == "rain" then
            love.graphics.line(p.x, p.y, p.x + p.dx*0.1, p.y + p.dy*0.1)
        else
            love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
        end
    end
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("MARKET", 10, 10)
    love.graphics.print("HOME", 10, 500)
end

return Map