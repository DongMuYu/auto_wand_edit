-- 伤害统计模块
-- 负责统计玩家和假人受到的伤害，并通过GUI显示

local damage_stats = {}

-- 加载实验室配置模块
local lab_config = dofile("mods/auto_wand_edit/files/scripts/config/lab_config.lua")

-- 获取指定名称的VariableStorageComponent组件
-- @param entity_id 实体ID
-- @param name 组件名称
-- @return component 组件对象，如果未找到则返回nil
local function get_variable_storage_component(entity_id, name)
    local components = EntityGetComponent(entity_id, "VariableStorageComponent") or {}
    for _, component in ipairs(components) do
        if(ComponentGetValue2(component, "name") == name) then
            return component
        end
    end
    return nil
end

-- 模块状态表
local stats_state = {
    dummy_damage = {},               -- 假人受到的伤害统计（总伤害）
    dummy_dps = {},                  -- 假人的当前DPS
    dummy_highest_dps = {},          -- 假人的最高DPS
    dummy_average_dps = {},          -- 假人的平均DPS
    dummy_last_frame_damage = {},    -- 假人的最近一帧伤害
    player_damage = 0,               -- 玩家受到的伤害统计
    player_max_hp = 0,               -- 玩家最大血量
    initialized = false              -- 是否已初始化
}

-- 初始化伤害统计
function damage_stats.initialize()
    stats_state.dummy_damage = {}
    stats_state.dummy_dps = {}
    stats_state.dummy_highest_dps = {}
    stats_state.dummy_average_dps = {}
    stats_state.dummy_last_frame_damage = {}
    stats_state.player_damage = 0
    stats_state.player_max_hp = 0
    stats_state.initialized = true
    -- GamePrint("Damage stats initialized")
end

-- 更新假人列表（当假人被重新生成时调用）
-- @param dummies 新的假人实体列表
-- @param reset_damage 是否重置伤害数据（默认为true）
function damage_stats.update_dummies(dummies, reset_damage)
    reset_damage = reset_damage or true
    
    -- if(#dummies == 0) then
    --     GamePrint("WARNING: damage_stats.update_dummies: No dummies provided")
    -- else
    --     GamePrint("damage_stats.update_dummies: Processing " .. #dummies .. " dummies")
    -- end
    -- GamePrint("[DamageStats] reset_damage = " .. tostring(reset_damage))
    GamePrint("[DamageStats] Dummy count: " .. #dummies)
    if reset_damage then
        -- 如果需要重置伤害数据
        stats_state.dummy_damage = {}
        stats_state.dummy_dps = {}
        stats_state.dummy_highest_dps = {}
        stats_state.dummy_average_dps = {}
        stats_state.dummy_last_frame_damage = {}
        for i =1, #dummies do
            table.insert(stats_state.dummy_damage, 0)
            table.insert(stats_state.dummy_dps, 0)
            table.insert(stats_state.dummy_highest_dps, 0)
            table.insert(stats_state.dummy_average_dps, 0)
            table.insert(stats_state.dummy_last_frame_damage, 0)
        end
    else
        -- 保留伤害数据，如果新假人数量比之前多，补充0值
        while #stats_state.dummy_damage < #dummies do
            table.insert(stats_state.dummy_damage, 0)
            table.insert(stats_state.dummy_dps, 0)
            table.insert(stats_state.dummy_highest_dps, 0)
            table.insert(stats_state.dummy_average_dps, 0)
            table.insert(stats_state.dummy_last_frame_damage, 0)
        end
    end
    stats_state.initialized = true
end

-- 更新假人伤害统计
-- 从每个假人的VariableStorageComponent中读取累计伤害值
-- 假人的伤害由dps_tracker.lua脚本在每次受伤时累加到各个组件中
-- @param dummies 假人实体列表
function damage_stats.update_dummy_damage(dummies)
    for i, dummy_id in ipairs(dummies) do
        -- 检查假人是否存活
        if(EntityGetIsAlive(dummy_id)) then
            -- 使用辅助函数获取各个伤害存储组件
            local total_damage_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_total_damage")
            local current_dps_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_current_dps")
            local highest_dps_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_highest_dps")
            local average_dps_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_average_dps")
            local last_frame_damage_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_last_frame_damage")
            
            -- 读取总伤害
            if(total_damage_comp ~= nil) then
                stats_state.dummy_damage[i] = ComponentGetValue2(total_damage_comp, "value_float") or 0
            else
                stats_state.dummy_damage[i] = 0
            end
            
            -- 读取当前DPS
            if(current_dps_comp ~= nil) then
                stats_state.dummy_dps[i] = ComponentGetValue2(current_dps_comp, "value_float") or 0
            else
                stats_state.dummy_dps[i] = 0
            end
            
            -- 读取最高DPS
            if(highest_dps_comp ~= nil) then
                stats_state.dummy_highest_dps[i] = ComponentGetValue2(highest_dps_comp, "value_float") or 0
            else
                stats_state.dummy_highest_dps[i] = 0
            end
            
            -- 读取平均DPS
            if(average_dps_comp ~= nil) then
                stats_state.dummy_average_dps[i] = ComponentGetValue2(average_dps_comp, "value_float") or 0
            else
                stats_state.dummy_average_dps[i] = 0
            end
            
            -- 读取最近一帧伤害
            if(last_frame_damage_comp ~= nil) then
                stats_state.dummy_last_frame_damage[i] = ComponentGetValue2(last_frame_damage_comp, "value_float") or 0
            else
                stats_state.dummy_last_frame_damage[i] = 0
            end
            
            -- 每stats_update_interval帧打印一次调试信息
            if(GameGetFrameNum() % lab_config.config.stats_update_interval == 0) then
                -- GamePrint("Dummy " .. i .. " damage: " .. stats_state.dummy_damage[i] .. ", ID: " .. dummy_id)
            end
        else
            -- 如果假人已死亡，将所有伤害数据设为0
            stats_state.dummy_damage[i] = 0
            stats_state.dummy_dps[i] = 0
            stats_state.dummy_highest_dps[i] = 0
            stats_state.dummy_average_dps[i] = 0
            stats_state.dummy_last_frame_damage[i] = 0
            GamePrint("Dummy " .. i .. " is dead!")
        end
    end
end

-- 更新玩家伤害统计
-- 实时计算玩家累计受到的伤害：初始最大生命值 - 当前生命值
function damage_stats.update_player_damage()
    -- 获取玩家实体
    local player = EntityGetWithTag("player_unit")[1]
    if(player == nil) then
        return
    end
    
    -- 获取玩家的伤害模型组件，该组件包含玩家的血量信息
    local damage_model = EntityGetFirstComponent(player, "DamageModelComponent")
    if(damage_model == nil) then
        return
    end
    
    -- 获取玩家当前血量和最大血量
    local current_hp = ComponentGetValue2(damage_model, "hp") or 0
    local max_hp = ComponentGetValue2(damage_model, "max_hp") or 0
        
    -- 如果是第一次调用（player_max_hp为0），初始化血量值
    if(stats_state.player_max_hp == 0) then
        stats_state.player_max_hp = max_hp
        stats_state.player_damage = 0
        -- GamePrint("Player damage initialized: max_hp=" .. max_hp .. ", current_hp=" .. current_hp)
    else
        -- 实时计算累计受到的伤害：初始最大生命值 - 当前生命值
        stats_state.player_damage = stats_state.player_max_hp - current_hp
    end
end

-- 更新伤害统计（每帧调用）
-- @param dummies 假人实体列表
function damage_stats.update(dummies)
    if(not stats_state.initialized) then
        return
    end
    
    damage_stats.update_dummy_damage(dummies)
    damage_stats.update_player_damage()
end

-- 重置伤害统计
function damage_stats.reset()
    stats_state.player_damage = 0
    stats_state.player_max_hp = 0
    stats_state.dummy_damage = {}
    stats_state.dummy_dps = {}
    stats_state.dummy_highest_dps = {}
    stats_state.dummy_average_dps = {}
    stats_state.dummy_last_frame_damage = {}
    
    -- 同时重置所有假人实体上的 VariableStorageComponent 值
    local all_dummies = EntityGetWithTag("auto_wand_edit_target_dummy") or {}
    for _, dummy_id in ipairs(all_dummies) do
        if(EntityGetIsAlive(dummy_id)) then
            local total_damage_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_total_damage")
            if(total_damage_comp ~= nil) then
                ComponentSetValue2(total_damage_comp, "value_float", 0)
            end
            
            local current_dps_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_current_dps")
            if(current_dps_comp ~= nil) then
                ComponentSetValue2(current_dps_comp, "value_float", 0)
            end
            
            local highest_dps_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_highest_dps")
            if(highest_dps_comp ~= nil) then
                ComponentSetValue2(highest_dps_comp, "value_float", 0)
            end
            
            local average_dps_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_average_dps")
            if(average_dps_comp ~= nil) then
                ComponentSetValue2(average_dps_comp, "value_float", 0)
            end
            
            local last_frame_damage_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_last_frame_damage")
            if(last_frame_damage_comp ~= nil) then
                ComponentSetValue2(last_frame_damage_comp, "value_float", 0)
            end
            
            local last_hit_frame_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_last_hit_frame")
            if(last_hit_frame_comp ~= nil) then
                ComponentSetValue2(last_hit_frame_comp, "value_int", 0)
            end
            
            local first_hit_frame_comp = get_variable_storage_component(dummy_id, "auto_wand_edit_first_hit_frame")
            if(first_hit_frame_comp ~= nil) then
                ComponentSetValue2(first_hit_frame_comp, "value_int", 0)
            end
        end
    end
    
    -- GamePrint("Damage stats reset")
    -- GamePrint("[reset()][DamageStats] Dummy count: " .. #stats_state.dummy_damage)
end

-- 获取状态
-- @return stats_state 状态表
function damage_stats.get_state()
    return stats_state
end

return damage_stats