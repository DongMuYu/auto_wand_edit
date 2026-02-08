-- 玩家信息管理模块
-- 负责获取和管理玩家的各种信息，包括：
-- - 玩家实体
-- - 手持法杖
-- - 位置坐标
-- - 生命值和伤害倍率
-- - 特殊状态（如不朽护甲、仙馔密酒等）

local player_info_manager = {}

-- 加载实验室配置模块
local lab_config = dofile("mods/auto_wand_edit/files/scripts/config/lab_config.lua")

-- 获取玩家信息
-- 返回一个包含玩家所有相关信息的表
function player_info_manager.get_player_info()
    local player_info = {}
    
    -- 获取玩家实体
    player_info.entity = EntityGetWithTag("player_unit")[1]
    
    -- 初始化基本属性
    player_info.held_wand = nil
    player_info.px = nil
    player_info.py = nil
    player_info.hp = 4
    player_info.max_hp = 4
    
    -- 初始化伤害倍率（默认值）
    player_info.damage_multipliers = { 
        curse = 1,
        drill = 1,
        electricity = 1,
        explosion = 0.35,
        fire = 1,
        healing = 1,
        ice = 1,
        melee = 1,
        overeating = 1,
        physics_hit = 1,
        poison = 1,
        projectile = 1,
        radioactive = 1,
        slice = 1
    }
    
    -- 初始化特殊状态
    player_info.n_stainless = 0
    player_info.has_ambrosia = false
    player_info.has_unlimited_spells = false

    -- 如果玩家实体存在，获取详细信息
    if(player_info.entity ~= nil) then
        -- 获取手持法杖
        local inventory = EntityGetFirstComponent(player_info.entity, "Inventory2Component")
        local active_item = ComponentGetValue2(inventory, "mActiveItem")

        if(active_item ~= nil) and EntityHasTag(active_item, "wand") then
            player_info.held_wand = active_item
        end

        -- 获取玩家位置
        player_info.px, player_info.py = EntityGetTransform(player_info.entity)

        -- 获取生命值和伤害倍率
        local comp = EntityGetFirstComponent(player_info.entity, "DamageModelComponent")
        
        if(comp ~= nil) then
            player_info.hp = ComponentGetValue2(comp, "hp")
            player_info.max_hp = ComponentGetValue2(comp, "max_hp")
            
            local damage_multipliers_object = ComponentObjectGetMembers(comp, "damage_multipliers")
            
            for type, multiplier in pairs(damage_multipliers_object) do
                player_info.damage_multipliers[type] = tonumber(multiplier)
            end
        end

        -- 检查特殊效果（不朽护甲、仙馔密酒）
        local player_children = EntityGetAllChildren(player_info.entity)
        
        for c, child in ipairs(player_children) do
            local game_effects = EntityGetComponent(child, "GameEffectComponent")
            
            if(game_effects ~= nil) then
                for i, e in ipairs(game_effects) do
                    if(ComponentGetValue2(e, "effect") == "STAINLESS_ARMOUR") then
                        player_info.n_stainless = player_info.n_stainless + 1
                    end

                    if(ComponentGetValue2(e, "effect") == "PROTECTION_ALL") then
                        player_info.has_ambrosia = true
                    end
                end
            end
        end

        -- 检查无限法术perk
        local world_entity_id = GameGetWorldStateEntity()
        
        if(world_entity_id ~= nil) then
            local comp_worldstate = EntityGetFirstComponent(world_entity_id, "WorldStateComponent")
            
            if(comp_worldstate ~= nil) then
                player_info.has_unlimited_spells = ComponentGetValue2(comp_worldstate, "perk_infinite_spells")
            end
        end
    end

    return player_info
end

-- 设置玩家飞行状态
-- 为玩家启用飞行能力
function player_info_manager.set_player_flying(player_entity)
    if(player_entity == nil) then
        player_entity = EntityGetWithTag("player_unit")[1]
    end
    
    if(player_entity == nil) then
        return
    end
    
    local cp_comp = EntityGetFirstComponent(player_entity, "CharacterPlatformingComponent")
    local cd_comp = EntityGetFirstComponent(player_entity, "CharacterDataComponent")
    
    if(cp_comp ~= nil) then
        -- 设置重力为0，实现飞行
        ComponentSetValue2(cp_comp, "pixel_gravity", 0)
        -- 设置飞行速度
        local speed = 200
        ComponentSetValue2(cp_comp, "velocity_max_x", speed)
        ComponentSetValue2(cp_comp, "velocity_max_y", speed)
        ComponentSetValue2(cp_comp, "velocity_min_x", -speed)
        ComponentSetValue2(cp_comp, "velocity_min_y", -speed)
        ComponentSetValue2(cp_comp, "run_velocity", speed)
        ComponentSetValue2(cp_comp, "fly_velocity_x", speed)
        ComponentSetValue2(cp_comp, "fly_speed_max_up", speed)
        ComponentSetValue2(cp_comp, "fly_speed_max_down", speed)
    end
    
    if(cd_comp ~= nil) then
        -- 设置飞行时间最大值，实现无限飞行
        local fly_time_max = ComponentGetValue2(cd_comp, "fly_time_max")
        ComponentSetValue2(cd_comp, "mFlyingTimeLeft", fly_time_max)
    end
end

-- 更新玩家飞行控制
-- 每帧调用，处理玩家的飞行输入
function player_info_manager.update_flying_control(player_entity)
    if(player_entity == nil) then
        player_entity = EntityGetWithTag("player_unit")[1]
    end
    
    if(player_entity == nil) then
        return
    end
    
    local cp_comp = EntityGetFirstComponent(player_entity, "CharacterPlatformingComponent")
    local cd_comp = EntityGetFirstComponent(player_entity, "CharacterDataComponent")
    local controls_comp = EntityGetFirstComponent(player_entity, "ControlsComponent")
    
    if(cd_comp == nil or controls_comp == nil) then
        return
    end
    
    local speed = 200
    local lerp_speed = 0.60
    
    -- 获取当前速度
    local vx, vy = ComponentGetValue2(cd_comp, "mVelocity")
    local desired_vx = 0
    local desired_vy = 0
    
    -- 获取按键状态
    local move_up = ComponentGetValue2(controls_comp, "mButtonDownUp")
    local move_down = ComponentGetValue2(controls_comp, "mButtonDownDown")
    local move_left = ComponentGetValue2(controls_comp, "mButtonDownLeft")
    local move_right = ComponentGetValue2(controls_comp, "mButtonDownRight")
    
    -- 处理垂直移动
    if move_up and move_down then
        -- 同时按下上下，保持原位
        ComponentSetValue2(cd_comp, "is_on_ground", true)
    elseif move_up then
        desired_vy = desired_vy - speed
    elseif move_down then
        desired_vy = desired_vy + speed
    end
    
    -- 处理水平移动
    if move_left and move_right then
        -- 同时按下左右，不移动
    elseif move_left then
        desired_vx = desired_vx - speed
    elseif move_right then
        desired_vx = desired_vx + speed
    end
    
    -- 平滑过渡到目标速度
    vx = lerp(vx, desired_vx, lerp_speed)
    vy = lerp(vy, desired_vy, lerp_speed)
    
    -- 设置新速度
    ComponentSetValue2(cd_comp, "mVelocity", vx, vy)
    
    -- 确保飞行时间始终最大
    if(cp_comp ~= nil) then
        local fly_time_max = ComponentGetValue2(cd_comp, "fly_time_max")
        ComponentSetValue2(cd_comp, "mFlyingTimeLeft", fly_time_max)
    end
end

-- 设置玩家全视状态
-- 加载全视之眼实体，让玩家能够看到整个地图
function player_info_manager.set_player_all_seeing(player_entity)
    if(player_entity == nil) then
        player_entity = EntityGetWithTag("player_unit")[1]
    end
    
    if(player_entity == nil) then
        return
    end
    
    -- 检查是否已经加载了全视之眼
    local existing_eye = EntityGetWithName("auto_wand_edit_better_all_seeing_eye")
    
    if(existing_eye == 0) then
        -- 加载全视之眼实体
        local eye_entity = EntityLoad("mods/auto_wand_edit/files/entities/better_all_seeing_eye.xml")
        
        if(eye_entity ~= nil) then
            -- 将全视之眼添加为玩家的子实体
            EntityAddChild(player_entity, eye_entity)
        end
    end
end

-- 设置玩家初始血量
-- @param player_entity 玩家实体ID
-- @param hp 血量值（默认1万，Noita中1对应25）
function player_info_manager.set_player_hp(player_entity, hp)
    if(player_entity == nil) then
        player_entity = EntityGetWithTag("player_unit")[1]
    end
    
    if(player_entity == nil) then
        return
    end
    
    local hp_value = hp or 400
    
    local comp = EntityGetFirstComponent(player_entity, "DamageModelComponent")
    if(comp ~= nil) then
        ComponentSetValue2(comp, "hp", hp_value)
        ComponentSetValue2(comp, "max_hp", hp_value)
        -- GamePrint("Player HP set to " .. hp_value)
    end
end

-- 设置玩家初始状态
-- 同时启用飞行和全视
function player_info_manager.set_player_initial_state(player_entity)
    if(player_entity == nil) then
        player_entity = EntityGetWithTag("player_unit")[1]
    end
    
    if(player_entity == nil) then
        return
    end
    
    -- 设置血量
    player_info_manager.set_player_hp(player_entity, lab_config.config.player_hp)
    
    -- 设置飞行状态
    player_info_manager.set_player_flying(player_entity)
    
    -- 设置全视状态
    player_info_manager.set_player_all_seeing()
end

return player_info_manager
