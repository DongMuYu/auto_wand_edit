-- 模块基础目录
base_dir = "mods/auto_wand_edit/"
-- 模块名称
mod_name = "auto_wand_edit"
-- 加载 Noita 的工具函数库
dofile_once("data/scripts/lib/utilities.lua");
-- 加载调试器核心模块
dofile_once(base_dir .. "files/scripts/debugger.lua");
-- 加载法术信息模块
dofile_once(base_dir .. "files/scripts/spell_info.lua");
-- 加载工具函数模块
dofile_once(base_dir .. "files/scripts/utils.lua");
-- 加载UI模块
dofile_once(base_dir .. "files/ui.lua");
-- 加载施法状态属性配置
dofile_once(base_dir .. "files/scripts/cast_state_properties.lua");
-- 加载玩家信息管理模块
local player_info_manager = dofile(base_dir .. "files/scripts/player_info.lua");
-- 加载法杖生成器模块
local wand_generator = dofile(base_dir .. "files/scripts/wand_generator.lua");
-- 加载GUI管理器模块
local gui_manager = dofile(base_dir .. "files/scripts/gui_manager.lua");
-- 加载自动法杖编辑器模块
local auto_wand_editor = dofile(base_dir .. "files/scripts/auto_wand_editor.lua");
-- 加载假人生成器模块
local dummy_spawner = dofile(base_dir .. "files/scripts/dummy_spawner.lua");
-- 加载世界管理器模块
local world_manager = dofile(base_dir .. "files/scripts/world_manager.lua");
-- 加载玩家控制模块
local player_controller = dofile(base_dir .. "files/scripts/player_controller.lua");
-- 加载投射物管理模块
local projectile_manager = dofile(base_dir .. "files/scripts/projectile_manager.lua");
-- 加载伤害统计模块
local damage_stats = dofile(base_dir .. "files/scripts/damage_stats.lua")
-- 加载实验室配置模块
local lab_config = dofile(base_dir .. "files/scripts/lab_config.lua");

-- 从GUI管理器获取导出的变量
local gui = gui_manager.gui
local initialize_gui = gui_manager.initialize_gui
local calculate_camera_and_mouse_coords = gui_manager.calculate_camera_and_mouse_coords

-- 调试器实例，用于跟踪法杖的施法行为
debug_wand = nil

-- 自动法杖编辑器是否已初始化
local auto_wand_editor_initialized = false

-- 假人生成器是否已初始化
local dummy_spawner_initialized = false

-- 延迟初始化计数器
local init_delay_counter = 0
local init_delay_required = 20

-- 法术信息表，包含所有法术的数据
action_table = nil

-- 调试器初始化
function initialize_debugger_if_needed()
    if(not debug_wand) then
        action_table, projectile_table, projectile_list, extra_entity_table = SPELL_INFO.get_spell_info()
        debug_wand = init_debugger()

        -- GamePrint("Debugger initialized")
    end
end

-- 玩家生成回调函数
-- 当玩家实体生成时执行
function OnPlayerSpawned(player_id)
    -- 如果自动配仗模组尚未初始化，则生成实验室实体
	if not GameHasFlagRun( "auto_wand_edit_init" ) then
		EntityLoad( "mods/auto_wand_edit/files/biome_impl/wand_lab/wand_lab.xml", lab_config.config.lab_x, lab_config.config.lab_y )
		GameAddFlagRun( "auto_wand_edit_init" )
	end
    
    -- 设置玩家初始状态（飞行和全视）
    player_info_manager.set_player_initial_state(player_id)
end

-- 世界初始化后的回调函数
function OnWorldInitialized()
end

-- 世界更新前的回调函数
function OnWorldPreUpdate()
end

-- 主回调函数
-- 世界更新后的回调函数（每帧调用）
-- 这是模组的主要更新循环
function OnWorldPostUpdate()
    -- 初始化调试器
    initialize_debugger_if_needed()
    -- 初始化GUI
    initialize_gui()
    
    -- 设置天气始终为晴天，时间始终为白天
    world_manager.set_clear_day()
    
    -- 获取玩家信息
    local player_info = player_info_manager.get_player_info()
    local player = player_info.entity
    
    -- 更新玩家飞行控制
    if(player ~= nil) then
        player_info_manager.update_flying_control(player)
    end
    -- 计算相机和鼠标坐标
    local coords = calculate_camera_and_mouse_coords()
    -- 创建切换按钮
    gui_manager.create_toggle_buttons(coords.gw, coords.gh, wand_generator)
    -- 初始化法术库
    if(player ~= nil) then
        wand_generator.initialize_spell_library(player)
    end
    -- 初始化自动法杖编辑器（只初始化一次）
    if(not auto_wand_editor_initialized) then
        local wand_generator_state = wand_generator.get_state()
        auto_wand_editor.initialize(wand_generator_state.spell_library, wand_generator)
        auto_wand_editor.set_damage_stats_ref(damage_stats)
        auto_wand_editor_initialized = true
    end
    -- 初始化假人生成器（只初始化一次）
    if(not dummy_spawner_initialized) then
        dummy_spawner.initialize(damage_stats)
        dummy_spawner_initialized = true
    end
    -- 延迟初始化：等待20帧后传送玩家并生成假人
    if(init_delay_counter < init_delay_required) then
        init_delay_counter = init_delay_counter + 1
        if(init_delay_counter >= init_delay_required and player ~= nil) then
            player_controller.teleport_player(player)
            projectile_manager.clear_projectiles()
            dummy_spawner.spawn_dummies_around_player(player)
        end
    end
    -- 设置窗口函数
    gui_manager.setup_window_functions(wand_generator, action_table, auto_wand_editor, damage_stats, dummy_spawner)
    -- 更新自动循环逻辑
    auto_wand_editor.update_auto_loop()
    
    -- 绘制窗口
    draw_windows(gui)
end
