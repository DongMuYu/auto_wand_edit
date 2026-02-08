-- 假人生成器模块
-- 负责在玩家周围生成假人靶标

local dummy_spawner = {}

-- 加载实验室配置模块
local lab_config = dofile("mods/auto_wand_edit/files/scripts/lab_config.lua")

-- 模块状态表
local spawner_state = {
    dummies = {},               -- 已生成的假人实体列表
    damage_stats_ref = nil,     -- 伤害统计模块引用
    dummy_counter = 0           -- 假人计数器（用于生成唯一标识）
}

-- 使用实验室配置
local config = lab_config.config

-- 杀死单个假人
-- @param dummy_id 假人实体ID
local function kill_dummy(dummy_id)
    if(not EntityGetIsAlive(dummy_id)) then
        return
    end
    
    -- 移除 ItemComponent
    local item_comp = EntityGetFirstComponent(dummy_id, "ItemComponent")
    if(item_comp ~= nil) then
        EntityRemoveComponent(dummy_id, item_comp)
    end
    
    -- 清除所有子实体
    local children = EntityGetAllChildren(dummy_id) or {}
    for _, child_id in ipairs(children) do
        if(EntityGetIsAlive(child_id)) then
            EntityKill(child_id)
        end
    end
    
    -- 杀死实体
    EntityKill(dummy_id)
end

-- 初始化假人生成器
-- @param damage_stats_ref 伤害统计模块引用
function dummy_spawner.initialize(damage_stats_ref)
    spawner_state.damage_stats_ref = damage_stats_ref
    -- GamePrint("Dummy spawner initialized")
end

-- 在玩家周围生成假人靶标
-- @param player 玩家实体ID
-- @param radius 生成半径（默认120像素）
-- @param num_dummies 生成数量（默认8个）
function dummy_spawner.spawn_dummies_around_player(player, radius, num_dummies, reset_damage)
    if(player == nil) then
        GamePrint("ERROR: Player not found!")
        return
    end
    
    radius = radius or config.spawn_radius
    num_dummies = num_dummies or config.num_dummies
    reset_damage = reset_damage or true
    
    -- GamePrint("Spawning " .. num_dummies .. " dummies around player at radius " .. radius)
    
    -- -- 先清除所有旧的假人（确保场上只有新假人）
    -- dummy_spawner.clear_dummies()
    
    local player_x, player_y = EntityGetTransform(player)
    -- GamePrint("Player position: (" .. player_x .. ", " .. player_y .. ")")
    for i = 0, num_dummies - 1 do
        local angle = (2 * math.pi * i) / num_dummies
        local dummy_x = player_x + radius * math.cos(angle)
        local dummy_y = player_y + radius * math.sin(angle)
        
        local dummy_id
        
        -- 全部使用普通假人
        dummy_id = EntityLoad("mods/auto_wand_edit/files/entities/dummy_target/dummy_target.xml", dummy_x, dummy_y)
        
        if(dummy_id ~= nil) then
            -- 为每个假人添加唯一标识符
            spawner_state.dummy_counter = spawner_state.dummy_counter + 1
            local unique_id = spawner_state.dummy_counter
            
            -- 添加 VariableStorageComponent 存储唯一 ID
            EntityAddComponent2(dummy_id, "VariableStorageComponent", {
                name = "auto_wand_edit_dummy_unique_id",
                value_int = unique_id
            })
            
            -- 添加 VariableStorageComponent 存储绝对位置
            EntityAddComponent2(dummy_id, "VariableStorageComponent", {
                name = "auto_wand_edit_dummy_original_x",
                value_float = dummy_x
            })
            EntityAddComponent2(dummy_id, "VariableStorageComponent", {
                name = "auto_wand_edit_dummy_original_y",
                value_float = dummy_y
            })
            
            -- 添加标签标识
            EntityAddTag(dummy_id, "auto_wand_edit_dummy_" .. tostring(unique_id))
            
            table.insert(spawner_state.dummies, dummy_id)
            -- GamePrint("Spawned dummy " .. i .. " (ID: " .. unique_id .. ") at (" .. dummy_x .. ", " .. dummy_y .. ")")
        else
            GamePrint("ERROR: Failed to spawn dummy " .. i)
        end
    end
    -- GamePrint("Total dummies spawned: " .. #spawner_state.dummies)
    -- GamePrint("state.dummies after spawn: " .. #spawner_state.dummies)
    
    -- 更新伤害统计的假人列表
    if(spawner_state.damage_stats_ref ~= nil) then
        spawner_state.damage_stats_ref.update_dummies(spawner_state.dummies, reset_damage)
    end
end

-- 清除所有已生成的假人
function dummy_spawner.clear_dummies()
    -- 清除所有带有我们标签的假人
    local all_dummies = EntityGetWithTag("auto_wand_edit_target_dummy") or {}
    -- GamePrint("Found " .. #all_dummies .. " dummies with auto_wand_edit_target_dummy tag")
    
    for _, dummy_id in ipairs(all_dummies) do
        kill_dummy(dummy_id)
    end
    spawner_state.dummies = {}
    -- GamePrint("state.dummies after clear: " .. #spawner_state.dummies)
end

-- 将假人放回原来的位置并重置状态
function dummy_spawner.reset_dummies_to_original_positions()
    if(#spawner_state.dummies == 0) then
        GamePrint("WARNING: No dummies to reset")
        return
    end
    
    -- GamePrint("Resetting " .. #spawner_state.dummies .. " dummies to original positions")
    
    local new_dummies = {}
    
    for i, dummy_id in ipairs(spawner_state.dummies) do
        local target_x, target_y
        
        -- 从假人的组件中读取位置
        local x_comp = EntityGetFirstComponent(dummy_id, "VariableStorageComponent", "auto_wand_edit_dummy_original_x")
        local y_comp = EntityGetFirstComponent(dummy_id, "VariableStorageComponent", "auto_wand_edit_dummy_original_y")
        if(x_comp ~= nil and y_comp ~= nil) then
            target_x = ComponentGetValue2(x_comp, "value_float")
            target_y = ComponentGetValue2(y_comp, "value_float")
        else
            GamePrint("WARNING: No position data for dummy " .. dummy_id .. ", skipping")
            goto continue
        end
        
        ::continue::
        
        if(EntityGetIsAlive(dummy_id)) then
            EntityApplyTransform(dummy_id, target_x, target_y)
            
            local velocity_comp = EntityGetFirstComponent(dummy_id, "VelocityComponent")
            if(velocity_comp ~= nil) then
                ComponentSetValue2(velocity_comp, "mVelocity", "0", "0")
            end
            
            local damage_model = EntityGetFirstComponent(dummy_id, "DamageModelComponent")
            if(damage_model ~= nil) then
                ComponentSetValue2(damage_model, "hp", config.dummy_hp)
                ComponentSetValue2(damage_model, "max_hp", config.dummy_hp)
                ComponentSetValue2(damage_model, "ragdoll_filenames_file", "")
            end
            
            local physics_comp = EntityGetFirstComponent(dummy_id, "SimplePhysicsComponent")
            if(physics_comp ~= nil) then
                EntitySetComponentIsEnabled(dummy_id, physics_comp, false)
                EntitySetComponentIsEnabled(dummy_id, physics_comp, true)
            end
            
            table.insert(new_dummies, dummy_id)
        else
            GamePrint("WARNING: Dummy " .. dummy_id .. " is not alive, respawning...")
            
            local new_dummy_id = EntityLoad("mods/auto_wand_edit/files/entities/dummy_target/dummy_target.xml", target_x, target_y)
            
            if(new_dummy_id ~= nil) then
                spawner_state.dummy_counter = spawner_state.dummy_counter + 1
                local unique_id = spawner_state.dummy_counter
                
                EntityAddComponent2(new_dummy_id, "VariableStorageComponent", {
                    name = "auto_wand_edit_dummy_unique_id",
                    value_int = unique_id
                })
                
                EntityAddComponent2(new_dummy_id, "VariableStorageComponent", {
                    name = "auto_wand_edit_dummy_original_x",
                    value_float = target_x
                })
                EntityAddComponent2(new_dummy_id, "VariableStorageComponent", {
                    name = "auto_wand_edit_dummy_original_y",
                    value_float = target_y
                })
                
                EntityAddTag(new_dummy_id, "auto_wand_edit_dummy_" .. tostring(unique_id))
                
                table.insert(new_dummies, new_dummy_id)
                
                -- GamePrint("Respawned dummy at (" .. target_x .. ", " .. target_y .. ")")
            else
                GamePrint("ERROR: Failed to respawn dummy")
            end
        end
    end
    
    spawner_state.dummies = new_dummies
    -- GamePrint("state.dummies after reset: " .. #spawner_state.dummies)
    
    -- 更新伤害统计的假人列表
    if(spawner_state.damage_stats_ref ~= nil) then
        spawner_state.damage_stats_ref.update_dummies(spawner_state.dummies, true)
    end
end

-- 获取假人列表
-- @return dummies 假人实体列表
function dummy_spawner.get_dummies()
    return spawner_state.dummies
end

return dummy_spawner