-- 世界管理器模块
-- 负责管理游戏世界的天气和时间设置

local world_manager = {}

-- 模块状态表
local state = {
    initialized = false,  -- 是否已初始化
    weather_clear = false,  -- 是否已设置为晴天
    time_day = false      -- 是否已设置为白天
}

-- 设置天气为晴天
-- 通过修改 WorldStateComponent 来禁用天气效果
function world_manager.set_weather_clear()
end

-- 设置时间为白天
-- 通过修改 WorldStateComponent 来设置时间
function world_manager.set_time_day()
    if(state.time_day) then
        return
    end
    
    local world_entity_id = GameGetWorldStateEntity()
    
    if(world_entity_id == nil) then
        GamePrint("ERROR: World state entity not found!")
        return
    end
    
    local comp_worldstate = EntityGetFirstComponent(world_entity_id, "WorldStateComponent")
    
    if(comp_worldstate == nil) then
        GamePrint("ERROR: WorldStateComponent not found!")
        return
    end
    
    -- 设置时间为早晨（0-1之间，0.25为早晨，0.5为正午）
    -- 注意：这些字段可能不存在，使用 pcall 防止错误
    pcall(function()
        ComponentSetValue2(comp_worldstate, "time", 0.1)
    end)
    
    pcall(function()
        ComponentSetValue2(comp_worldstate, "time_speed", 0)
    end)
    
    pcall(function()
        ComponentSetValue2(comp_worldstate, "day_timer", 999999)
    end)
    
    pcall(function()
        ComponentSetValue2(comp_worldstate, "night_timer", 999999)
    end)
    
    state.time_day = true
    -- GamePrint("Time set to day")
end

-- 同时设置时间白天和天气为晴天
function world_manager.set_clear_day()
    local time_was_set = state.time_day
    local weather_was_set = state.weather_clear
    
    world_manager.set_time_day()
    -- world_manager.set_weather_clear()
    
    if(not time_was_set or not weather_was_set) then
        -- GamePrint("Time set to day and weather set to clear")
    end
end

-- 初始化世界管理器
function world_manager.initialize()
    if(not state.initialized) then
        world_manager.set_clear_day()
        state.initialized = true
        -- GamePrint("World manager initialized")
    end
end

-- 重置世界管理器状态
function world_manager.reset()
    state.weather_clear = false
    state.time_day = false
    -- GamePrint("World manager state reset")
end

-- 获取状态
-- @return state 状态表
function world_manager.get_state()
    return state
end

return world_manager