-- 射击管理模块
-- 负责控制玩家向指定方向射击

local shooter = {}

-- 加载实验室配置模块
local lab_config = dofile("mods/auto_wand_edit/files/scripts/lab_config.lua")

-- 加载辅助函数模块
dofile("mods/auto_wand_edit/files/lib/helper.lua")

-- 模块状态表
local state = {
    control_component = nil,    -- 玩家控制组件（缓存）
    was_firing_wand = false,    -- 上一帧是否在发射法杖
    shot_fired = false           -- 是否已发射
}

-- 控制玩家向指定方向射击
-- 计算目标位置并设置玩家的瞄准向量，然后发射法术
-- @param target_index 目标索引（0-7），对应8个方向
-- @return success 是否成功（true/false）
function shooter.shoot_wand_towards(target_index)
    local player = EntityGetWithTag("player_unit")[1]
    if(player == nil) then
        GamePrint("ERROR: Player not found!")
        return false
    end
    
    -- 确保控制组件已缓存
    if(state.control_component == nil) then
        state.control_component = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
        if(state.control_component == nil) then
            GamePrint("ERROR: ControlsComponent not found!")
            return false
        end
    end
    
    -- 获取玩家右臂
    local arm = EntityGetAllChildren(player, "player_arm_r")[1]
    if(arm == nil) then
        GamePrint("ERROR: Player right arm not found!")
        return false
    end
    
    -- 获取手部热点位置
    local ch_x, ch_y = EntityGetHotspot(arm, "hand", true)
    if(ch_x == nil or ch_y == nil) then
        GamePrint("ERROR: Hand hotspot not found!")
        return false
    end
    
    -- 获取玩家位置
    local player_x, player_y = EntityGetTransform(player)
    
    -- 计算目标位置（8个方向，每个方向45度）
    local radius = lab_config.config.shoot_radius
    local angle = (2 * math.pi * target_index) / 8
    local target_x = player_x + radius * math.cos(angle)
    local target_y = player_y + radius * math.sin(angle)
    
    -- 计算方向向量
    local dx = target_x - ch_x
    local dy = target_y - ch_y
    
    -- 计算距离
    local dist = math.min(math.sqrt(dx * dx + dy * dy), lab_config.config.max_shoot_distance)
    
    -- 计算角度
    local t = math.atan2(dy, dx)
    
    -- 计算单位向量
    dx = dist * math.cos(t)
    dy = dist * math.sin(t)
    
    -- 设置瞄准向量
    ComponentSetValue2(state.control_component, "mAimingVector", dx, dy)
    ComponentSetValue2(state.control_component, "mAimingVectorNormalized", dx / dist, dy / dist)
    ComponentSetValue2(state.control_component, "mMousePosition", ch_x + dx, ch_y + dy)
    
    -- 清除法杖充能延迟
    local held_wand = get_held_wand()
    if(held_wand ~= nil) then
        local ab_comp = EntityGetFirstComponentIncludingDisabled(held_wand, "AbilityComponent")
        if(ab_comp ~= nil) then
            local now = GameGetFrameNum()
            ComponentSetValue2(ab_comp, "mReloadFramesLeft", 0)
            ComponentSetValue2(ab_comp, "mNextFrameUsable", now)
            ComponentSetValue2(ab_comp, "mReloadNextFrameUsable", now)
        end
    end
    
    -- 发射法术（使用state.control_component）
    -- 参考notplayer_ai.lua的fire_wand函数实现
    ComponentSetValue2(state.control_component, "mButtonDownFire", true)
    ComponentSetValue2(state.control_component, "mButtonDownFire2", true)
    if not state.was_firing_wand then
        ComponentSetValue2(state.control_component, "mButtonFrameFire", GameGetFrameNum() + 1)
    end
    ComponentSetValue2(state.control_component, "mButtonLastFrameFire", GameGetFrameNum())
    
    -- 等待一帧后释放
    state.shot_fired = true
    state.was_firing_wand = true
    
    return true
end

-- 释放射击按键
-- 在射击后调用，释放按键以便下一次射击
function shooter.release_fire_button()
    if(state.shot_fired) then
        if(state.control_component ~= nil) then
            ComponentSetValue2(state.control_component, "mButtonDownFire", false)
            ComponentSetValue2(state.control_component, "mButtonDownFire2", false)
            state.was_firing_wand = false
        end
        state.shot_fired = false
    end
end

return shooter
