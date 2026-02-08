-- 玩家控制模块
-- 负责管理玩家输入禁用和传送操作

local player_controller = {}

-- 加载实验室配置模块
local lab_config = dofile("mods/auto_wand_edit/files/scripts/config/lab_config.lua")

-- 模块状态表
local state = {
    control_component = nil    -- 玩家控制组件（缓存）
}

-- 禁用玩家输入（在自动循环期间持续调用）
-- 通过设置ControlsComponent的enabled为false来完全禁用玩家的键盘/手柄输入
-- 参考notplayer_ai.lua的实现
function player_controller.disable_player_input_per_frame()
    local player = EntityGetWithTag("player_unit")[1]
    if(player == nil) then
        return
    end
    
    -- 缓存控制组件以提高性能
    if(state.control_component == nil) then
        state.control_component = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
        if(state.control_component == nil) then
            return
        end
    end
    
    -- 关键：禁用玩家的ControlsComponent，使得玩家的键盘/手柄输入完全失效
    -- 参考notplayer_ai.lua:1585的实现
    ComponentSetValue2(state.control_component, "enabled", false)
end

-- 启用玩家输入
-- 恢复玩家的键盘/手柄输入控制
function player_controller.enable_player_input()
    if(state.control_component ~= nil) then
        ComponentSetValue2(state.control_component, "enabled", true)
        state.control_component = nil
    end
end

-- 传送玩家到指定位置并设置相机
-- @param player 玩家实体ID
-- @param x 目标X坐标（默认lab_config.config.lab_x）
-- @param y 目标Y坐标（默认lab_config.config.lab_y + lab_config.config.offset_y）
function player_controller.teleport_player(player, x, y)
    if(player == nil) then
        return
    end
    x = x or lab_config.config.lab_x
    y = y or (lab_config.config.lab_y + lab_config.config.offset_y)
    EntityApplyTransform(player, x, y)
    GameSetCameraPos(x, y)
end

-- 确保玩家在固定位置
-- 如果玩家位置偏移超过阈值，传送回固定位置
-- @return player_x, player_y 玩家当前位置
function player_controller.ensure_player_at_fixed_position()
    local player = EntityGetWithTag("player_unit")[1]
    if(player == nil) then
        return nil, nil
    end
    
    local player_x, player_y = EntityGetTransform(player)
    local target_x = lab_config.config.lab_x
    local target_y = lab_config.config.lab_y + lab_config.config.offset_y
    
    -- 如果玩家位置偏移，传送回固定位置
    if(math.abs(player_x - target_x) > lab_config.config.position_threshold or math.abs(player_y - target_y) > lab_config.config.position_threshold) then
        EntityApplyTransform(player, target_x, target_y)
        player_x, player_y = target_x, target_y
    end
    
    return player_x, player_y
end

-- 固定摄影机位置
-- 将摄影机固定在实验室位置
function player_controller.fix_camera()
    local target_x = lab_config.config.lab_x
    local target_y = lab_config.config.lab_y + lab_config.config.offset_y
    GameSetCameraPos(target_x, target_y)
end

return player_controller
