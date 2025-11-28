-- Cozy Farm Sim in Love2D v3
-- Features: Seasons, Weather, Limited Water, Farming
-- Controls:
--   WASD / Arrows: Move
--   SPACE: Use Tool
--   TAB: Switch Tools
--   E: Open Market
--   Z: Sleep (New Day)
--   1-4: Market Shortcuts

function love.load()
    love.window.setTitle("Cozy Farm Sim v3 - Seasons & Weather")
    love.window.setMode(800, 600)

    -- Game Constants
    TILE_SIZE = 40
    MAP_WIDTH = 20
    MAP_HEIGHT = 15
    DAY_LENGTH = 60
    SEASON_LENGTH = 3 -- Days per season

    -- Colors
    colors = {
        soil = { 0.6, 0.4, 0.2 },
        soil_wet = { 0.5, 0.3, 0.2 },
        water = { 0.2, 0.5, 0.9 },
        shop = { 0.8, 0.7, 0.5 },
        house_floor = { 0.5, 0.4, 0.5 },
        player = { 0.9, 0.2, 0.2 },

        -- Seasonal Grass Colors
        seasons = {
            { 0.4, 0.8, 0.4 }, -- Spring (Green)
            { 0.6, 0.8, 0.2 }, -- Summer (Yellow-Green)
            { 0.8, 0.5, 0.2 }, -- Autumn (Orange)
            { 0.9, 0.9, 1.0 } -- Winter (White/Blue)
        },

        -- Crops
        wheat = { { 0.6, 0.8, 0.4 }, { 0.8, 0.8, 0.2 }, { 0.9, 0.7, 0.1 } },
        corn = { { 0.4, 0.8, 0.4 }, { 0.4, 0.7, 0.2 }, { 0.9, 0.9, 0.2 } },

        ui_bg = { 0, 0, 0, 0.7 },
        text = { 1, 1, 1 },
        energy_bar = { 1, 0.8, 0.2 },
        water_bar = { 0.2, 0.6, 1.0 },
        rain = { 0.7, 0.7, 1.0, 0.6 }
    }

    -- Player State
    player = {
        x = 5 * TILE_SIZE,
        y = 5 * TILE_SIZE,
        speed = 200,
        facing = 'down',
        energy = 100,
        max_energy = 100,
        water = 10, -- Current water in can
        max_water = 10,
        inventory = {
            money = 50,
            seeds_wheat = 5,
            seeds_corn = 2,
            wheat = 0,
            corn = 0
        },
        current_tool = 1
    }

    tools = { "Hoe", "Water Can", "Wheat Seeds", "Corn Seeds", "Scythe" }
    season_names = { "Spring", "Summer", "Autumn", "Winter" }

    -- World State
    game_time = 0.25
    day = 1
    current_season = 1 -- 1 to 4
    day_of_season = 1
    is_raining = false

    -- Map Data
    map = {}
    crops = {}
    particles = {}

    -- Initialize Map
    for y = 0, MAP_HEIGHT - 1 do
        map[y] = {}
        for x = 0, MAP_WIDTH - 1 do
            if x > 15 and y > 10 then
                map[y][x] = 3                          -- Pond
            elseif x < 4 and y < 3 then
                map[y][x] = 4                          -- Shop
            elseif x < 3 and y > 11 then
                map[y][x] = 5                          -- House
            else
                map[y][x] = 1
            end                                        -- Grass
        end
    end

    market_open = false
    message = "Welcome! Watch the seasons change."
    message_timer = 5
end

function love.update(dt)
    -- 1. Time Progression
    if not market_open then
        game_time = game_time + (dt / DAY_LENGTH)
        if game_time >= 1.0 then
            startNewDay() -- Auto sleep if day ends
        end
    end

    -- 2. Weather Effects (Rain)
    if is_raining and not market_open then
        -- Spawn rain particles
        if math.random() < 0.4 then
            table.insert(particles, {
                x = math.random(0, 800),
                y = -10,
                dx = -20,
                dy = 300, -- Falling fast
                life = 2,
                size = 2,
                color = colors.rain,
                type = "rain"
            })
        end
    end

    -- 3. Movement
    local moving = false
    local next_x, next_y = player.x, player.y

    if not market_open then
        if love.keyboard.isDown('w', 'up') then
            next_y = next_y - player.speed * dt
            player.facing = 'up'
        elseif love.keyboard.isDown('s', 'down') then
            next_y = next_y + player.speed * dt
            player.facing = 'down'
        end

        if love.keyboard.isDown('a', 'left') then
            next_x = next_x - player.speed * dt
            player.facing = 'left'
        elseif love.keyboard.isDown('d', 'right') then
            next_x = next_x + player.speed * dt
            player.facing = 'right'
        end
    end

    -- Collision
    if next_x >= 0 and next_x <= (MAP_WIDTH * TILE_SIZE) - TILE_SIZE then player.x = next_x end
    if next_y >= 0 and next_y <= (MAP_HEIGHT * TILE_SIZE) - TILE_SIZE then player.y = next_y end

    -- 4. Crop Logic
    for k, crop in pairs(crops) do
        -- Winter kills growth/crops logic could go here, but we'll just pause growth
        if current_season ~= 4 and crop.watered and crop.stage < 3 then
            crop.timer = crop.timer + dt
            local time_needed = (crop.type == "corn") and 6 or 3
            if crop.timer > time_needed then
                crop.stage = crop.stage + 1
                crop.timer = 0
                crop.watered = false
            end
        end
    end

    -- 5. Particles Update
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.life = p.life - dt
        if p.life <= 0 or p.y > 600 then table.remove(particles, i) end
    end

    if message_timer > 0 then message_timer = message_timer - dt end
end

function startNewDay()
    day = day + 1
    day_of_season = day_of_season + 1
    game_time = 0.25 -- 6 AM
    player.energy = player.max_energy

    -- Season Cycle
    if day_of_season > SEASON_LENGTH then
        day_of_season = 1
        current_season = current_season + 1
        if current_season > 4 then current_season = 1 end
        message = "Season Changed: " .. season_names[current_season] .. "!"
        message_timer = 4
    end

    -- Weather Logic
    is_raining = (math.random() < 0.3)                 -- 30% chance of rain
    if current_season == 4 then is_raining = false end -- No rain in winter (simplified)

    -- Auto-water if raining
    if is_raining then
        for k, crop in pairs(crops) do
            crop.watered = true
        end
        if message == "" or message_timer <= 0 then
            message = "It's raining! Crops watered."
            message_timer = 3
        end
    end
end

function love.draw()
    -- 1. Draw Map
    local grassColor = colors.seasons[current_season]

    for y = 0, MAP_HEIGHT - 1 do
        for x = 0, MAP_WIDTH - 1 do
            local tileType = map[y][x]
            local px, py = x * TILE_SIZE, y * TILE_SIZE

            if tileType == 1 then
                love.graphics.setColor(grassColor)
            elseif tileType == 2 then
                love.graphics.setColor(colors.soil)
            elseif tileType == 3 then
                love.graphics.setColor(colors.water)
            elseif tileType == 4 then
                love.graphics.setColor(colors.shop)
            elseif tileType == 5 then
                love.graphics.setColor(colors.house_floor)
            end
            love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)

            -- Grid
            love.graphics.setColor(0, 0, 0, 0.1)
            love.graphics.rectangle("line", px, py, TILE_SIZE, TILE_SIZE)
        end
    end

    -- 2. Draw Crops
    for key, crop in pairs(crops) do
        local x, y = string.match(key, "(%d+),(%d+)")
        x, y = tonumber(x), tonumber(y)
        local px, py = x * TILE_SIZE, y * TILE_SIZE

        if crop.watered then
            love.graphics.setColor(colors.soil_wet)
            love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
        end

        local cTable = (crop.type == "corn") and colors.corn or colors.wheat
        love.graphics.setColor(cTable[crop.stage])

        local cx, cy = px + TILE_SIZE / 2, py + TILE_SIZE / 2
        if crop.type == "corn" then
            local h = 5 + (crop.stage * 8)
            love.graphics.rectangle("fill", cx - 4, cy - h / 2, 8, h)
        else
            local r = 2 + (crop.stage * 4)
            love.graphics.circle("fill", cx, cy, r)
        end
    end

    -- 3. Particles (Rain/Dirt)
    for _, p in ipairs(particles) do
        love.graphics.setColor(p.color)
        if p.type == "rain" then
            love.graphics.line(p.x, p.y, p.x + p.dx * 0.1, p.y + p.dy * 0.1)
        else
            love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
        end
    end

    -- 4. Labels & Player
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("MARKET", 10, 10)
    love.graphics.print("HOME", 10, 500)

    love.graphics.setColor(colors.player)
    love.graphics.circle("fill", player.x + TILE_SIZE / 2, player.y + TILE_SIZE / 2, TILE_SIZE / 2 - 2)

    -- Facing Dot
    love.graphics.setColor(1, 1, 1, 0.5)
    local dx, dy = 0, 0
    if player.facing == 'up' then
        dy = -20
    elseif player.facing == 'down' then
        dy = 20
    elseif player.facing == 'left' then
        dx = -20
    elseif player.facing == 'right' then
        dx = 20
    end
    love.graphics.circle("fill", player.x + TILE_SIZE / 2 + dx, player.y + TILE_SIZE / 2 + dy, 5)

    -- 5. Night Overlay
    local brightness = 0
    if game_time > 0.6 then
        brightness = (game_time - 0.6) * 2
        if brightness > 0.85 then brightness = 0.85 end
    end
    if is_raining then brightness = brightness + 0.1 end -- Darker when raining

    if brightness > 0 then
        love.graphics.setColor(0, 0, 0.2, brightness)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
    end

    drawUI()
    if market_open then drawMarket() end
end

function drawUI()
    -- Bar Background
    love.graphics.setColor(colors.ui_bg)
    love.graphics.rectangle("fill", 0, 540, 800, 60)

    love.graphics.setColor(colors.text)

    -- Info
    local hour = math.floor(game_time * 24)
    local seasonStr = season_names[current_season]
    local weatherStr = is_raining and "Rainy" or "Sunny"
    love.graphics.print(seasonStr .. " | Day " .. day .. " | " .. hour .. ":00 | " .. weatherStr, 20, 550)

    -- Inventory
    love.graphics.print("$" .. player.inventory.money, 300, 550)
    love.graphics.print("W-Seeds: " .. player.inventory.seeds_wheat, 20, 575)
    love.graphics.print("C-Seeds: " .. player.inventory.seeds_corn, 110, 575)
    love.graphics.print("Wheat: " .. player.inventory.wheat, 200, 575)
    love.graphics.print("Corn: " .. player.inventory.corn, 290, 575)

    -- Bars
    -- Energy
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 600, 550, 100, 15)
    love.graphics.setColor(colors.energy_bar)
    love.graphics.rectangle("fill", 600, 550, 100 * (player.energy / player.max_energy), 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("E", 585, 550)

    -- Water
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 600, 570, 100, 15)
    love.graphics.setColor(colors.water_bar)
    love.graphics.rectangle("fill", 600, 570, 100 * (player.water / player.max_water), 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("W", 585, 570)

    -- Tool
    love.graphics.print("Tool: < " .. tools[player.current_tool] .. " >", 380, 550)

    -- Message
    if message_timer > 0 then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(message, 380, 575)
    end
end

function drawMarket()
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 150, 100, 500, 400)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 150, 100, 500, 400)
    love.graphics.printf("GENERAL STORE", 150, 120, 500, "center")
    love.graphics.print("Press 'E' to close", 350, 450)
    love.graphics.print("1. Wheat Seeds ($5)", 200, 180)
    love.graphics.print("2. Corn Seeds  ($10)", 200, 220)
    love.graphics.print("3. Sell Wheat      ($15)", 200, 280)
    love.graphics.print("4. Sell Corn       ($30)", 200, 320)
    love.graphics.setColor(0.5, 1, 0.5)
    love.graphics.print("Current Money: $" .. player.inventory.money, 200, 400)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "z" and not market_open then
        startNewDay()
        message = "Slept until morning."
        message_timer = 2
        return
    end

    if key == "e" then
        local px, py = getGridPos(player.x, player.y)
        if px < 4 and py < 3 then
            market_open = not market_open
        else
            if not market_open then
                message = "Go to the Shop (Top Left)"
                message_timer = 2
            end
        end
    end

    if market_open then
        handleMarketInput(key)
    else
        handleGameInput(key)
    end
end

function handleMarketInput(key)
    local inv = player.inventory
    if key == "1" and inv.money >= 5 then
        inv.money = inv.money - 5
        inv.seeds_wheat = inv.seeds_wheat + 1
    elseif key == "2" and inv.money >= 10 then
        inv.money = inv.money - 10
        inv.seeds_corn = inv.seeds_corn + 1
    elseif key == "3" and inv.wheat > 0 then
        inv.wheat = inv.wheat - 1
        inv.money = inv.money + 15
    elseif key == "4" and inv.corn > 0 then
        inv.corn = inv.corn - 1
        inv.money = inv.money + 30
    end
end

function handleGameInput(key)
    if key == "tab" then
        player.current_tool = player.current_tool + 1
        if player.current_tool > #tools then player.current_tool = 1 end
    elseif key == "space" then
        interact()
    end
end

function getGridPos(x, y)
    return math.floor((x + TILE_SIZE / 2) / TILE_SIZE), math.floor((y + TILE_SIZE / 2) / TILE_SIZE)
end

function createParticles(x, y, color, count)
    for i = 1, count do
        table.insert(particles, {
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

function interact()
    local cx, cy = player.x + TILE_SIZE / 2, player.y + TILE_SIZE / 2
    if player.facing == 'up' then
        cy = cy - TILE_SIZE
    elseif player.facing == 'down' then
        cy = cy + TILE_SIZE
    elseif player.facing == 'left' then
        cx = cx - TILE_SIZE
    elseif player.facing == 'right' then
        cx = cx + TILE_SIZE
    end

    local tx, ty = math.floor(cx / TILE_SIZE), math.floor(cy / TILE_SIZE)
    local key = tx .. "," .. ty

    if tx < 0 or tx >= MAP_WIDTH or ty < 0 or ty >= MAP_HEIGHT then return end

    local tool = tools[player.current_tool]
    local tileType = map[ty][tx]
    local inv = player.inventory

    if player.energy <= 0 then
        message = "Too tired! Sleep (Z)."
        message_timer = 2
        return
    end

    local worked = false

    if tool == "Hoe" then
        if tileType == 1 then
            map[ty][tx] = 2; worked = true
            createParticles(cx, cy, colors.soil, 5)
        elseif tileType == 2 then
            map[ty][tx] = 1; crops[key] = nil; worked = true
            createParticles(cx, cy, colors.seasons[current_season], 5)
        end
    elseif tool == "Water Can" then
        if tileType == 3 then
            player.water = player.max_water
            message = "Refilled Water!"
            message_timer = 2
        elseif crops[key] then
            if player.water > 0 then
                if not crops[key].watered then
                    crops[key].watered = true
                    player.water = player.water - 1
                    worked = true
                    createParticles(cx, cy, colors.water, 8)
                end
            else
                message = "Empty! Go to pond (Bottom Right)."
                message_timer = 2
            end
        end
    elseif tool == "Wheat Seeds" or tool == "Corn Seeds" then
        if tileType == 2 and not crops[key] then
            if current_season == 4 then
                message = "Can't plant in Winter!"
                message_timer = 2
            else
                local seedName = (tool == "Wheat Seeds") and "seeds_wheat" or "seeds_corn"
                local typeName = (tool == "Wheat Seeds") and "wheat" or "corn"

                if inv[seedName] > 0 then
                    inv[seedName] = inv[seedName] - 1
                    crops[key] = { type = typeName, stage = 1, timer = 0, watered = false }
                    worked = true
                else
                    message = "No seeds!"
                    message_timer = 1
                end
            end
        end
    elseif tool == "Scythe" then
        if crops[key] and crops[key].stage == 3 then
            inv[crops[key].type] = inv[crops[key].type] + 1
            if math.random() > 0.5 then
                local sKey = "seeds_" .. crops[key].type
                inv[sKey] = inv[sKey] + 1
            end
            createParticles(cx, cy, { 1, 1, 0.5 }, 10)
            crops[key] = nil
            worked = true
        end
    end

    if worked then
        player.energy = player.energy - 2
        if player.energy < 0 then player.energy = 0 end
    end
end
