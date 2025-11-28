local C = require 'constants'
local UI = {}

function UI.drawHUD(player, day, seasonIdx, time, is_raining, message, message_timer)
    love.graphics.setColor(C.COLORS.ui_bg)
    love.graphics.rectangle("fill", 0, 540, 800, 60)
    love.graphics.setColor(C.COLORS.text)
    
    -- Info
    local hour = math.floor(time * 24)
    local seasonStr = C.SEASON_NAMES[seasonIdx]
    local weatherStr = is_raining and "Rainy" or "Sunny"
    love.graphics.print(seasonStr .. " | Day " .. day .. " | " .. hour .. ":00 | " .. weatherStr, 20, 550)

    -- Inventory
    love.graphics.print("$" .. player.inventory.money, 300, 550)
    love.graphics.print("W-Seeds: " .. player.inventory.seeds_wheat, 20, 575)
    love.graphics.print("C-Seeds: " .. player.inventory.seeds_corn, 110, 575)
    love.graphics.print("Wheat: " .. player.inventory.wheat, 200, 575)
    love.graphics.print("Corn: " .. player.inventory.corn, 290, 575)

    -- Energy Bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 600, 550, 100, 15)
    love.graphics.setColor(C.COLORS.energy_bar)
    love.graphics.rectangle("fill", 600, 550, 100 * (player.energy / player.max_energy), 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("E", 585, 550)

    -- Water Bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 600, 570, 100, 15)
    love.graphics.setColor(C.COLORS.water_bar)
    love.graphics.rectangle("fill", 600, 570, 100 * (player.water / player.max_water), 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("W", 585, 570)

    -- Tool
    love.graphics.print("Tool: < " .. C.TOOLS[player.current_tool] .. " >", 380, 550)

    -- Message
    if message_timer > 0 then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(message, 380, 575)
    end
end

function UI.drawMarket(player)
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

function UI.drawDialogue(name, text)
    -- Draw Box at bottom of screen (above HUD)
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 50, 400, 700, 120)
    
    -- Border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 50, 400, 700, 120)
    
    -- Name Tag
    love.graphics.setColor(1, 1, 0)
    love.graphics.print(name, 70, 415)
    
    -- Text
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(text, 70, 445, 660, "left")
    
    -- Hint
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Press SPACE to continue...", 500, 500)
end

return UI