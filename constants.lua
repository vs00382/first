local Constants = {}

Constants.TILE_SIZE = 40
Constants.MAP_WIDTH = 20
Constants.MAP_HEIGHT = 15
Constants.DAY_LENGTH = 60
Constants.SEASON_LENGTH = 3

Constants.TOOLS = { "Hoe", "Water Can", "Wheat Seeds", "Corn Seeds", "Scythe" }
Constants.SEASON_NAMES = { "Spring", "Summer", "Autumn", "Winter" }

Constants.COLORS = {
    soil = {0.6, 0.4, 0.2},
    soil_wet = {0.5, 0.3, 0.2},
    water = {0.2, 0.5, 0.9},
    shop = {0.8, 0.7, 0.5},
    house_floor = {0.5, 0.4, 0.5},
    player = {0.9, 0.2, 0.2},
    
    seasons = {
        {0.4, 0.8, 0.4}, -- Spring
        {0.6, 0.8, 0.2}, -- Summer
        {0.8, 0.5, 0.2}, -- Autumn
        {0.9, 0.9, 1.0}  -- Winter
    },
    
    crops = {
        wheat = {{0.6, 0.8, 0.4}, {0.8, 0.8, 0.2}, {0.9, 0.7, 0.1}},
        corn = {{0.4, 0.8, 0.4}, {0.4, 0.7, 0.2}, {0.9, 0.9, 0.2}}
    },
    
    ui_bg = {0, 0, 0, 0.7},
    text = {1, 1, 1},
    energy_bar = {1, 0.8, 0.2},
    water_bar = {0.2, 0.6, 1.0},
    rain = {0.7, 0.7, 1.0, 0.6}
}

return Constants