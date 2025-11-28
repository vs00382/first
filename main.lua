-- Cozy Farm Sim in Love2D
-- A complete single-file farming prototype
-- Controls:
--   WASD / Arrows: Move
--   SPACE: Use currently selected tool
--   TAB: Switch Tools (Hoe, Water, Seeds, Harvest)
--   E: Open/Close Market (when standing near the shop zone)
--   1/2/3: Buy/Sell shortcuts in Market

function love.load()
    love.window.setTitle("Cozy Farm Sim")
    love.window.setMode(800, 600)

    -- Game Constants
    TILE_SIZE = 40
    MAP_WIDTH = 20
    MAP_HEIGHT = 15

    -- Colors
    colors = {
        grass = { 0.4, 0.8, 0.4 },
        soil = { 0.6, 0.4, 0.2 },
        soil_wet = { 0.5, 0.3, 0.2 },
        water = { 0.2, 0.5, 0.9 },
        shop = { 0.8, 0.7, 0.5 },
        player = { 0.9, 0.2, 0.2 },
        wheat_1 = { 0.6, 0.8, 0.4 },
        wheat_2 = { 0.8, 0.8, 0.2 },
        wheat_3 = { 0.9, 0.7, 0.1 }, -- Ready to harvest
        ui_bg = { 0, 0, 0, 0.7 },
        text = { 1, 1, 1 }
    }

    -- Player State
    player = {
        x = 5 * TILE_SIZE,
        y = 5 * TILE_SIZE,
        speed = 200,
        facing = 'down', -- up, down, left, right
        inventory = {
            money = 50,
            seeds = 5,
            wheat = 0
        },
        current_tool = 1 -- Index for tools list
    }

    tools = {
        "Hoe (Till Soil)",
        "Water Can",
        "Seeds (Plant)",
        "Scythe (Harvest)"
    }

    -- Map Data
    -- 1: Grass, 2: Soil, 3: Water, 4: Shop Floor
    map = {}
    crops = {} -- Key: "x,y", Value: {stage=1, timer=0, watered=false}

    -- Initialize Map
    for y = 0, MAP_HEIGHT - 1 do
        map[y] = {}
        for x = 0, MAP_WIDTH - 1 do
            -- Create a little pond
            if x > 15 and y > 10 then
                map[y][x] = 3
                -- Create a shop area
            elseif x < 4 and y < 3 then
                map[y][x] = 4
            else
                map[y][x] = 1
            end
        end
    end

    -- Market State
    market_open = false
    message = "Welcome to the Farm!"
    message_timer = 3
end

function love.update(dt)
    -- Handle Movement
    local moving = false
    local next_x, next_y = player.x, player.y

    if love.keyboard.isDown('w', 'up') then
        next_y = next_y - player.speed * dt
        player.facing = 'up'
        moving = true
    elseif love.keyboard.isDown('s', 'down') then
        next_y = next_y + player.speed * dt
        player.facing = 'down'
        moving = true
    end

    if love.keyboard.isDown('a', 'left') then
        next_x = next_x - player.speed * dt
        player.facing = 'left'
        moving = true
    elseif love.keyboard.isDown('d', 'right') then
        next_x = next_x + player.speed * dt
        player.facing = 'right'
        moving = true
    end

    -- Collision Check (Simple bounds)
    if next_x >= 0 and next_x <= (MAP_WIDTH * TILE_SIZE) - TILE_SIZE then
        player.x = next_x
    end
    if next_y >= 0 and next_y <= (MAP_HEIGHT * TILE_SIZE) - TILE_SIZE then
        player.y = next_y
    end

    -- Crop Logic
    for k, crop in pairs(crops) do
        if crop.watered and crop.stage < 3 then
            crop.timer = crop.timer + dt
            if crop.timer > 3 then -- 3 seconds per stage for testing (usually longer)
                crop.stage = crop.stage + 1
                crop.timer = 0
                crop.watered = false -- Dry out after growing
            end
        end
    end

    -- Message Timer
    if message_timer > 0 then
        message_timer = message_timer - dt
    end
end

function love.draw()
    -- 1. Draw Map
    for y = 0, MAP_HEIGHT - 1 do
        for x = 0, MAP_WIDTH - 1 do
            local tileType = map[y][x]
            local tileX, tileY = x * TILE_SIZE, y * TILE_SIZE

            -- Draw Tile Base
            if tileType == 1 then
                love.graphics.setColor(colors.grass)
            elseif tileType == 2 then
                love.graphics.setColor(colors.soil)
            elseif tileType == 3 then
                love.graphics.setColor(colors.water)
            elseif tileType == 4 then
                love.graphics.setColor(colors.shop)
            end
            love.graphics.rectangle("fill", tileX, tileY, TILE_SIZE, TILE_SIZE)

            -- Draw Tile Outline for grid effect
            love.graphics.setColor(0, 0, 0, 0.1)
            love.graphics.rectangle("line", tileX, tileY, TILE_SIZE, TILE_SIZE)
        end
    end

    -- 2. Draw Crops & Wet Soil Overlay
    for key, crop in pairs(crops) do
        local x, y = string.match(key, "(%d+),(%d+)")
        x, y = tonumber(x), tonumber(y)
        local px, py = x * TILE_SIZE, y * TILE_SIZE

        -- Wet Soil Indicator
        if crop.watered then
            love.graphics.setColor(colors.soil_wet)
            love.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
        end

        -- Crop Sprite (Procedural)
        if crop.stage == 1 then
            love.graphics.setColor(colors.wheat_1)
            love.graphics.circle("fill", px + TILE_SIZE / 2, py + TILE_SIZE / 2, 5)
        elseif crop.stage == 2 then
            love.graphics.setColor(colors.wheat_2)
            love.graphics.circle("fill", px + TILE_SIZE / 2, py + TILE_SIZE / 2, 10)
        elseif crop.stage == 3 then
            love.graphics.setColor(colors.wheat_3)
            -- Draw a simple wheat shape
            love.graphics.ellipse("fill", px + TILE_SIZE / 2, py + TILE_SIZE / 2, 8, 15)
        end
    end

    -- 3. Draw Shop Indicator
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("MARKET", 10, 10)

    -- 4. Draw Player
    love.graphics.setColor(colors.player)
    love.graphics.circle("fill", player.x + TILE_SIZE / 2, player.y + TILE_SIZE / 2, TILE_SIZE / 2 - 2)

    -- Draw Direction Indicator
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

    -- 5. Draw UI
    drawUI()

    -- 6. Draw Market Menu if open
    if market_open then
        drawMarket()
    end
end

function drawUI()
    -- Bottom Bar Background
    love.graphics.setColor(colors.ui_bg)
    love.graphics.rectangle("fill", 0, 550, 800, 50)

    -- Stats
    love.graphics.setColor(colors.text)
    love.graphics.print("Money: $" .. player.inventory.money, 20, 565)
    love.graphics.print("Seeds: " .. player.inventory.seeds, 150, 565)
    love.graphics.print("Wheat: " .. player.inventory.wheat, 250, 565)

    -- Tool Selection
    love.graphics.print("Tool (TAB): < " .. tools[player.current_tool] .. " >", 450, 565)

    -- Feedback Message
    if message_timer > 0 then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(message, 10, 530)
    end
end

function drawMarket()
    -- Modal Background
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 200, 150, 400, 300)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 200, 150, 400, 300)

    love.graphics.printf("MARKET", 200, 170, 400, "center")

    love.graphics.print("Press 'E' to close", 350, 420)

    love.graphics.print("1. Buy Seeds ($5)  [You have: $" .. player.inventory.money .. "]", 230, 220)
    love.graphics.print("2. Sell Wheat ($15) [You have: " .. player.inventory.wheat .. "]", 230, 260)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if key == "e" then
        -- Toggle Market if near shop tiles (top left corner)
        local px, py = getGridPos(player.x, player.y)
        if px < 4 and py < 3 then
            market_open = not market_open
            message = market_open and "Entered Market" or "Left Market"
            message_timer = 2
        else
            if not market_open then
                message = "Go to the brown floor (Top Left) to open Market"
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
    if key == "1" then
        if player.inventory.money >= 5 then
            player.inventory.money = player.inventory.money - 5
            player.inventory.seeds = player.inventory.seeds + 1
            message = "Bought Seeds!"
            message_timer = 1
        else
            message = "Not enough money!"
            message_timer = 1
        end
    elseif key == "2" then
        if player.inventory.wheat > 0 then
            player.inventory.wheat = player.inventory.wheat - 1
            player.inventory.money = player.inventory.money + 15
            message = "Sold Wheat!"
            message_timer = 1
        else
            message = "No wheat to sell!"
            message_timer = 1
        end
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

function interact()
    -- Calculate target tile based on direction
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

    -- Bounds check
    if tx < 0 or tx >= MAP_WIDTH or ty < 0 or ty >= MAP_HEIGHT then return end

    local tool = tools[player.current_tool]
    local tileType = map[ty][tx]

    if tool == "Hoe (Till Soil)" then
        if tileType == 1 then -- Turn Grass to Soil
            map[ty][tx] = 2
            message = "Tilled soil"
        elseif tileType == 2 then
            map[ty][tx] = 1   -- Turn back to grass
            crops[key] = nil  -- Destroy crop
            message = "Flattened soil"
        end
    elseif tool == "Water Can" then
        if crops[key] then
            crops[key].watered = true
            message = "Watered crop"
        elseif tileType == 3 then
            message = "Refilled Water Can (Automatic)"
        end
    elseif tool == "Seeds (Plant)" then
        if tileType == 2 and not crops[key] then
            if player.inventory.seeds > 0 then
                player.inventory.seeds = player.inventory.seeds - 1
                crops[key] = { stage = 1, timer = 0, watered = false }
                message = "Planted seeds"
            else
                message = "Out of seeds!"
            end
        else
            message = "Needs tilled soil (empty)"
        end
    elseif tool == "Scythe (Harvest)" then
        if crops[key] and crops[key].stage == 3 then
            crops[key] = nil -- Remove crop
            player.inventory.wheat = player.inventory.wheat + 1
            -- Chance to get seed back
            if math.random() > 0.5 then player.inventory.seeds = player.inventory.seeds + 1 end
            message = "Harvested Wheat!"
        end
    end
    message_timer = 2
end
