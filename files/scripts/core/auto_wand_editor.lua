-- 自动法杖编辑器模块
-- 负责协调各个模块，实现自动循环测试法杖功能

local auto_wand_editor = {}

-- 加载各个功能模块
local player_info_manager = dofile("mods/auto_wand_edit/files/scripts/player/player_info.lua")
local lab_config = dofile("mods/auto_wand_edit/files/scripts/config/lab_config.lua")
local dummy_spawner = dofile("mods/auto_wand_edit/files/scripts/testing/dummy_spawner.lua")
local wand_manager = dofile("mods/auto_wand_edit/files/scripts/wand/wand_manager.lua")
local player_controller = dofile("mods/auto_wand_edit/files/scripts/player/player_controller.lua")
local projectile_manager = dofile("mods/auto_wand_edit/files/scripts/combat/projectile_manager.lua")
local terrain_manager = dofile("mods/auto_wand_edit/files/scripts/world/terrain_manager.lua")
local shooter = dofile("mods/auto_wand_edit/files/scripts/combat/shooter.lua")
local spell_selector = dofile("mods/auto_wand_edit/files/scripts/wand/spell_selector.lua")

-- 伤害统计模块引用（在init.lua中设置）
local damage_stats_ref = nil

-- 模块状态表
local state = {
    initialized = false,        -- 是否已初始化
    wand_generator_ref = nil,   -- 法杖生成器模块引用
    auto_loop_enabled = false,  -- 自动循环是否启用
    auto_loop_timer = 0,        -- 自动循环计时器
    auto_loop_phase = 0,        -- 自动循环阶段（0=刷新，1=配置，2=发射，3=等待）
    auto_loop_delay = lab_config.config.auto_loop_delay,       -- 自动循环延迟帧数
    current_target_index = 0,   -- 当前射击目标索引（0-7）
}

-- 初始化自动法杖编辑器
-- @param spell_library 法术库数组
-- @param wand_generator_ref 法杖生成器模块引用
function auto_wand_editor.initialize(spell_library, wand_generator_ref)
    state.wand_generator_ref = wand_generator_ref
    spell_selector.initialize(spell_library, wand_generator_ref)
    state.initialized = true
end

-- 设置伤害统计模块引用
-- @param damage_stats 伤害统计模块引用
function auto_wand_editor.set_damage_stats_ref(damage_stats)
    damage_stats_ref = damage_stats
end

-- 获取状态
-- 返回自动法杖编辑器的当前状态，包含法术选择、循环状态等信息
-- @return state 状态表，包含以下字段：
--   - selected_spells: 当前选择的法术序列数组（来自spell_selector模块）
--   - wand_generator_ref: 法杖生成器模块的引用
--   - auto_loop_enabled: 自动循环是否启用（true/false）
--   - auto_loop_timer: 自动循环计时器（当前帧数）
--   - auto_loop_phase: 自动循环当前阶段（0=等待，1=刷新，2=地形，3=配置，4=发射）
--   - current_target_index: 当前射击目标索引（0-7，对应8个方向）
function auto_wand_editor.get_state()
    local spell_selector_state = spell_selector.get_state()
    return {
        selected_spells = spell_selector_state.selected_spells,
        wand_generator_ref = state.wand_generator_ref,
        auto_loop_enabled = state.auto_loop_enabled,
        auto_loop_timer = state.auto_loop_timer,
        auto_loop_phase = state.auto_loop_phase,
        current_target_index = state.current_target_index
    }
end

-- 从法术库中配置法术序列（不立即应用到法杖）
-- @param capacity 法术数量
function auto_wand_editor.config_from_library(capacity)
    spell_selector.config_from_library(capacity)
end

-- 将当前序列配置到手中的法杖
function auto_wand_editor.apply_to_wand()
    spell_selector.apply_to_wand()
end

-- 切换自动循环状态
-- 启用或禁用自动循环功能
-- 启用时会传送玩家到固定位置并开始自动测试法杖
-- 禁用时会恢复玩家控制
function auto_wand_editor.toggle_auto_loop()
    state.auto_loop_enabled = not state.auto_loop_enabled
    state.auto_loop_phase = 0
    state.auto_loop_timer = 0
    state.current_target_index = 0
    
    if(state.auto_loop_enabled) then
        -- 启用自动循环时，先传送玩家到指定位置
        local player = EntityGetWithTag("player_unit")[1]
        if(player ~= nil) then
            player_controller.teleport_player(player)
            projectile_manager.clear_projectiles()
        end
        -- GamePrint("Auto loop: enabled")
    else
        -- 禁用自动循环时，恢复玩家控制
        player_controller.enable_player_input()
        -- GamePrint("Auto loop: disabled (player control enabled)")
    end
end

-- 更新自动循环逻辑（每帧调用）
-- 自动循环的核心函数，负责管理整个测试流程
-- 流程包括：刷新 -> 配置法杖 -> 射击测试 -> 等待
-- 每个阶段都有独立的计时器和条件判断
function auto_wand_editor.update_auto_loop()
    -- 检查自动循环是否启用
    if(not state.auto_loop_enabled) then
        return
    end
    
    -- 每帧都禁用玩家输入
    player_controller.disable_player_input_per_frame()
    
    -- 每帧都固定摄影机位置和玩家位置
    local player_x, player_y = player_controller.ensure_player_at_fixed_position()
    if(player_x ~= nil and player_y ~= nil) then
        player_controller.fix_camera()
    end
    
    state.auto_loop_timer = state.auto_loop_timer + 1
    
    -- 释放射击按键
    shooter.release_fire_button()
    
    -- 根据阶段执行操作
    if(state.auto_loop_phase == 0) then
        -- 刷新阶段：刷新法术库、法杖、玩家血量和地形
        if(state.wand_generator_ref ~= nil) then
            state.wand_generator_ref.refresh()
        end
        -- 刷新玩家血量
        player_info_manager.set_player_hp(nil, lab_config.config.player_hp)
        -- 重置伤害统计（新一轮开始）
        if(damage_stats_ref ~= nil) then
            damage_stats_ref.reset()
        end
        -- 重新生成地形
        terrain_manager.regenerate_terrain()
        state.auto_loop_phase = 1
        state.auto_loop_timer = 0
        -- GamePrint("Phase 1: Configuring wand")
    elseif(state.auto_loop_phase == 1) then
        -- 配置阶段：自动配置法杖
        if(state.auto_loop_timer >= lab_config.config.wand_config_delay) then
            -- 确保玩家手持法杖
            local wand_id = wand_manager.ensure_player_holds_wand()
            if(wand_id ~= nil) then
                -- GamePrint("Found wand: " .. wand_id)
                local capacity, spells_per_round = wand_manager.get_wand_config(wand_id)
                -- GamePrint("Wand capacity: " .. capacity .. ", spells per round: " .. spells_per_round)
                auto_wand_editor.config_from_library(capacity)
                auto_wand_editor.apply_to_wand()
                state.auto_loop_phase = 2
                state.auto_loop_timer = 0
                -- GamePrint("Phase 2: Shooting wand")
            else
                GamePrint("ERROR: No wand found in inventory!")
                -- 重新开始循环
                state.auto_loop_phase = 0
                state.auto_loop_timer = 0
            end
        end
    elseif(state.auto_loop_phase == 2) then
        -- 发射阶段：向8个靶标方向依次射击
        if(state.auto_loop_timer >= lab_config.config.shoot_delay) then
            -- 向当前目标方向射击
            shooter.shoot_wand_towards(state.current_target_index)
            
            -- 将假人放回原来的位置并重置状态（每次射击后都重置）
            dummy_spawner.reset_dummies_to_original_positions()
            
            -- 移动到下一个目标
            state.current_target_index = state.current_target_index + 1
            
            -- 如果已经射击完8个方向，进入等待阶段
            if(state.current_target_index >= 8) then
                state.auto_loop_phase = 3
                state.auto_loop_timer = 0
                state.current_target_index = 0
                -- GamePrint("Phase 3: Waiting for next loop")
            else
                -- 继续射击下一个方向，重置计时器
                state.auto_loop_timer = 0
                -- GamePrint("Shot " .. state.current_target_index .. "/8 targets")
            end
        end
    elseif(state.auto_loop_phase == 3) then
        -- 等待阶段：等待120帧后开始新一轮循环
        if(state.auto_loop_timer >= 120) then
                state.auto_loop_phase = 0
                state.auto_loop_timer = 0
                -- GamePrint("Starting new loop")
        end
    end
end

return auto_wand_editor
