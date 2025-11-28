local C = require 'constants'
local Villager = {}

function Villager.load()
    -- Define our friends
    Villager.list = {
        {
            x = 8 * C.TILE_SIZE,
            y = 8 * C.TILE_SIZE,
            name = "Mayor Lewis",
            color = {0.5, 0.5, 0.8},
            dialogues = {
                "Welcome to our little farm!",
                "The economy is tough, keep selling that wheat!",
                "I love this town."
            }
        },
        {
            x = 2 * C.TILE_SIZE,
            y = 13 * C.TILE_SIZE,
            name = "Granny",
            color = {0.9, 0.5, 0.5},
            dialogues = {
                "My knees hurt... rain is coming.",
                "Have you been eating enough corn?",
                "It was better in the old days."
            }
        },
        {
            x = 18 * C.TILE_SIZE,
            y = 12 * C.TILE_SIZE,
            name = "Fisherman",
            color = {0.2, 0.8, 0.8},
            dialogues = {
                "The pond is peaceful today.",
                "I wish I had a fishing rod.",
                "Watering crops is hard work, eh?"
            }
        }
    }
end

function Villager.draw()
    for _, v in ipairs(Villager.list) do
        -- Draw Body
        love.graphics.setColor(v.color)
        love.graphics.circle("fill", v.x + C.TILE_SIZE/2, v.y + C.TILE_SIZE/2, C.TILE_SIZE/2 - 2)
        
        -- Draw 'NPC' label above head slightly
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print("?", v.x + 12, v.y - 15)
    end
end

-- Check if player is facing a villager and close enough
function Villager.getNearby(px, py, facing)
    local cx, cy = px + C.TILE_SIZE/2, py + C.TILE_SIZE/2
    
    -- Project point in front of player
    if facing == 'up' then cy = cy - C.TILE_SIZE
    elseif facing == 'down' then cy = cy + C.TILE_SIZE
    elseif facing == 'left' then cx = cx - C.TILE_SIZE
    elseif facing == 'right' then cx = cx + C.TILE_SIZE
    end

    -- Check collision with any villager
    for _, v in ipairs(Villager.list) do
        local vx = v.x + C.TILE_SIZE/2
        local vy = v.y + C.TILE_SIZE/2
        
        -- Simple distance check (within 20 pixels of center of tile)
        local dist = math.sqrt((cx - vx)^2 + (cy - vy)^2)
        if dist < 30 then
            return v
        end
    end
    return nil
end

return Villager