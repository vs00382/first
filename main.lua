local C = require 'constants'
local Player = require 'player'
local Map = require 'map'
local UI = require 'ui'
local Villager = require 'villager'

function love.load()
    Player.load()
    Map.load()
    Villager.load()

    -- Global State
    market_open = false
    message = "Welcome! Say hi to the villagers!"
    message_timer = 5
    game_time = 0.25
    day = 1
    day_of_season = 1

    -- Dialogue State
    talking_to = nil -- The villager object
    current_line = ""
end

function love.update(dt)
    -- Pause game logic if in market OR talking
    if not market_open and not talking_to then
        -- Time Progression
        game_time = game_time + (dt / C.DAY_LENGTH)
        if game_time >= 1.0 then startNewDay() end

        -- Updates
        Player.update(dt)
        Map.updateCrops(dt)
        Map.updateParticles(dt)

        -- Weather
        if Map.is_raining then Map.spawnRain() end
    end

    if message_timer > 0 then message_timer = message_timer - dt end
end

function love.draw()
    Map.draw()
    Villager.draw() -- Draw NPCs on top of map
    Player.draw()

    -- Night Overlay
    local brightness = 0
    if game_time > 0.6 then
        brightness = (game_time - 0.6) * 2
        if brightness > 0.85 then brightness = 0.85 end
    end
    if Map.is_raining then brightness = brightness + 0.1 end

    if brightness > 0 then
        love.graphics.setColor(0, 0, 0.2, brightness)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
    end

    UI.drawHUD(Player, day, Map.season, game_time, Map.is_raining, message, message_timer)

    if market_open then
        UI.drawMarket(Player)
    elseif talking_to then
        UI.drawDialogue(talking_to.name, current_line)
    end
end

function startNewDay()
    day = day + 1
    day_of_season = day_of_season + 1
    game_time = 0.25
    Player.energy = Player.max_energy

    -- Season Cycle
    if day_of_season > C.SEASON_LENGTH then
        day_of_season = 1
        Map.season = Map.season + 1
        if Map.season > 4 then Map.season = 1 end
        message = "Season Changed: " .. C.SEASON_NAMES[Map.season] .. "!"
        message_timer = 4
    end

    -- Weather Logic
    Map.is_raining = (math.random() < 0.3)
    if Map.season == 4 then Map.is_raining = false end

    -- Auto-water
    if Map.is_raining then
        for k, crop in pairs(Map.crops) do crop.watered = true end
        if message == "" or message_timer <= 0 then
            message = "It's raining! Crops watered."
            message_timer = 3
        end
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    if key == "z" and not market_open and not talking_to then
        startNewDay()
        message = "Slept until morning."
        message_timer = 2
        return
    end

    if key == "e" and not talking_to then
        local px, py = getGridPos(Player.x, Player.y)
        if px < 4 and py < 3 then
            market_open = not market_open
        else
            if not market_open then
                message = "Go to the Shop (Top Left)"
                message_timer = 2
            end
        end
    end

    if key == "tab" and not talking_to and not market_open then
        Player.switchTool()
    end

    if market_open then
        handleMarketInput(key)
    elseif key == "space" then
        if talking_to then
            -- Close dialogue
            talking_to = nil
        else
            -- Try to interact (Villager first, then Farm)
            local npc = Villager.getNearby(Player.x, Player.y, Player.facing)
            if npc then
                talking_to = npc
                current_line = npc.dialogues[math.random(#npc.dialogues)]
            else
                interact()
            end
        end
    end
end

function handleMarketInput(key)
    local inv = Player.inventory
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

function getGridPos(x, y)
    return math.floor((x + C.TILE_SIZE / 2) / C.TILE_SIZE), math.floor((y + C.TILE_SIZE / 2) / C.TILE_SIZE)
end

function interact()
    local cx, cy = Player.x + C.TILE_SIZE / 2, Player.y + C.TILE_SIZE / 2
    if Player.facing == 'up' then
        cy = cy - C.TILE_SIZE
    elseif Player.facing == 'down' then
        cy = cy + C.TILE_SIZE
    elseif Player.facing == 'left' then
        cx = cx - C.TILE_SIZE
    elseif Player.facing == 'right' then
        cx = cx + C.TILE_SIZE
    end

    local tx, ty = math.floor(cx / C.TILE_SIZE), math.floor(cy / C.TILE_SIZE)
    local key = tx .. "," .. ty

    if tx < 0 or tx >= C.MAP_WIDTH or ty < 0 or ty >= C.MAP_HEIGHT then return end

    local tool = C.TOOLS[Player.current_tool]
    local tileType = Map.grid[ty][tx]
    local inv = Player.inventory

    if Player.energy <= 0 then
        message = "Too tired! Sleep (Z)."
        message_timer = 2
        return
    end

    local worked = false

    if tool == "Hoe" then
        if tileType == 1 then
            Map.grid[ty][tx] = 2; worked = true
            Map.createDust(cx, cy, C.COLORS.soil)
        elseif tileType == 2 then
            Map.grid[ty][tx] = 1; Map.crops[key] = nil; worked = true
            Map.createDust(cx, cy, C.COLORS.seasons[Map.season])
        end
    elseif tool == "Water Can" then
        if tileType == 3 then
            Player.water = Player.max_water
            message = "Refilled Water!"
            message_timer = 2
        elseif Map.crops[key] then
            if Player.water > 0 then
                if not Map.crops[key].watered then
                    Map.crops[key].watered = true
                    Player.water = Player.water - 1
                    worked = true
                    Map.createDust(cx, cy, C.COLORS.water)
                end
            else
                message = "Empty! Go to pond."
                message_timer = 2
            end
        end
    elseif tool == "Wheat Seeds" or tool == "Corn Seeds" then
        if tileType == 2 and not Map.crops[key] then
            if Map.season == 4 then
                message = "Can't plant in Winter!"
                message_timer = 2
            else
                local seedName = (tool == "Wheat Seeds") and "seeds_wheat" or "seeds_corn"
                local typeName = (tool == "Wheat Seeds") and "wheat" or "corn"

                if inv[seedName] > 0 then
                    inv[seedName] = inv[seedName] - 1
                    Map.crops[key] = { type = typeName, stage = 1, timer = 0, watered = false }
                    worked = true
                else
                    message = "No seeds!"
                    message_timer = 1
                end
            end
        end
    elseif tool == "Scythe" then
        if Map.crops[key] and Map.crops[key].stage == 3 then
            inv[Map.crops[key].type] = inv[Map.crops[key].type] + 1
            if math.random() > 0.5 then
                local sKey = "seeds_" .. Map.crops[key].type
                inv[sKey] = inv[sKey] + 1
            end
            Map.createDust(cx, cy, { 1, 1, 0.5 })
            Map.crops[key] = nil
            worked = true
        end
    end

    if worked then
        Player.energy = Player.energy - 2
        if Player.energy < 0 then Player.energy = 0 end
    end
end
