-- GUI管理模块
-- 负责GUI初始化、窗口创建、按钮管理和法术库显示

-- 加载工具函数模块
dofile_once("mods/auto_wand_edit/files/lib/helper.lua")

-- 加载法杖管理模块
local wand_manager = dofile("mods/auto_wand_edit/files/scripts/wand/wand_manager.lua")

-- 创建 GUI 实例
local gui = GuiCreate()

-- 创建窗口：当前法术库窗口
local spell_library_window = make_window("spell_library_window", 390, 150, 230, 180, false, "Spell Library")

-- 创建窗口：自动法杖编辑器窗口
local auto_wand_editor_window = make_window("auto_wand_editor_window", 10, 150, 230, 300, false, "Auto Wand Editor")

-- GUI 初始化
function initialize_gui()
    GuiStartFrame(gui)
    GuiOptionsAdd(gui, GUI_OPTION.NoPositionTween)
    global_interactive = not GameGetIsGamepadConnected()
    set_interactive(gui, true)
    start_gui(gui)
end

-- 摄像机和鼠标坐标计算
function calculate_camera_and_mouse_coords()
    local coords = {}
    
    mx, my = DEBUG_GetMouseWorld()

    local cx, cy, cw, ch = GameGetCameraBounds()
    cx, cy = GameGetCameraPos()
    cw = cw - 4
    local cx = cx-cw/2
    local cy = cy-ch/2

    gw, gh = GuiGetScreenDimensions(gui)
    bound_x_min = 0
    bound_y_min = 0
    bound_x_max = gw
    bound_y_max = gh

    coords.mx = (mx-cx)*gw/cw+1.0
    coords.my = (my-cy)*gw/cw-1.5
    coords.cx = cx
    coords.cy = cy
    coords.cw = cw
    coords.gw = gw
    coords.gh = gh

    return coords
end

-- 获取法术卡牌的背景精灵路径
-- @param type 法术类型
-- @return 背景精灵的完整路径
function get_bg_sprite(type)
    local bg_sprite = "data/ui_gfx/inventory/item_bg_"
    if(type == ACTION_TYPE_PROJECTILE) then
        bg_sprite = bg_sprite .. "projectile"
    elseif(type == ACTION_TYPE_STATIC_PROJECTILE) then
        bg_sprite = bg_sprite .. "static_projectile"
    elseif(type == ACTION_TYPE_MODIFIER) then
        bg_sprite = bg_sprite .. "modifier"
    elseif(type == ACTION_TYPE_DRAW_MANY) then
        bg_sprite = bg_sprite .. "draw_many"
    elseif(type == ACTION_TYPE_MATERIAL) then
        bg_sprite = bg_sprite .. "material"
    elseif(type == ACTION_TYPE_OTHER) then
        bg_sprite = bg_sprite .. "other"
    elseif(type == ACTION_TYPE_UTILITY) then
        bg_sprite = bg_sprite .. "utility"
    elseif(type == ACTION_TYPE_PASSIVE) then
        bg_sprite = bg_sprite .. "passive"
    end
    bg_sprite = bg_sprite .. ".png"
    return bg_sprite
end

-- 创建按钮
-- @param wand_generator_ref 法杖生成器模块的引用
-- @param auto_wand_editor_ref 自动法杖编辑器模块的引用
function create_toggle_buttons(gw, gh, wand_generator_ref)
    -- 刷新按钮
    local refresh_pressed = GuiImageButton(gui, get_id("refresh_button"), gw-16-16-16, gh-16, "", base_dir.."files/ui_gfx/loop.png")
    GuiTooltip(gui, "Refresh spell library", "")
    if(refresh_pressed) then
        wand_generator_ref.refresh()
    end
    
    -- 自动法杖编辑器按钮
    do_window_show_hide_button(gui, auto_wand_editor_window, gw-16-16, gh-16, base_dir.."files/ui_gfx/auto_wand_edit_icon.png")
    
    -- 法术库按钮
    do_window_show_hide_button(gui, spell_library_window, gw-16, gh-16, base_dir.."files/ui_gfx/spell_library_icon.png")
end

-- 设置窗口函数
-- @param wand_generator_ref 法杖生成器模块的引用
-- @param action_table_ref 法术信息表的引用
-- @param auto_wand_editor_ref 自动法杖编辑器模块的引用
-- @param damage_stats_ref 伤害统计模块的引用
-- @param dummy_spawner_ref 假人生成器模块的引用
function setup_window_functions(wand_generator_ref, action_table_ref, auto_wand_editor_ref, damage_stats_ref, dummy_spawner_ref)
    
    -- 法术库窗口函数
    spell_library_window.func = function(window)
        local x = -window.x_scroll
        local y = 0
        
        -- 获取法术生成器的状态对象
        -- 该对象包含法术库、生成的法杖序列等信息
        local state = wand_generator_ref.get_state()
        -- 从状态对象中获取法术库数组
        -- 如果法术库尚未初始化，则使用空数组作为默认值
        local spell_library = state.spell_library or {}
        
        -- 绘制法术库标题文本
        -- 显示法术库中的法术总数，格式为 "Spell Library (X spells)"
        -- x + 4: 水平偏移4像素，避免紧贴窗口左边缘
        -- y: 垂直位置从窗口顶部开始
        GuiText(gui, x + 4, y, "Spell Library (" .. #spell_library .. " spells)")
        -- 将垂直坐标向下移动6像素，为法术图标区域留出空间
        y = y + 10
        
        -- 定义法术网格布局参数
        local spells_per_row = 12
        local spell_size = 12
        local spacing = 8
        local row_height = spell_size + spacing
                
        -- 遍历法术库中的每个法术
        -- i: 当前法术的索引（从1开始）
        -- spell_id: 当前法术的ID字符串
        for i, spell_id in ipairs(spell_library) do
            -- 计算当前法术所在的行号（从0开始）
            -- 使用整数除法，(i-1) 将索引转换为从0开始
            local row = math.floor((i - 1) / spells_per_row)
            -- 计算当前法术所在的列号（从0开始）
            -- 使用取模运算，确保列号在 0 到 spells_per_row-1 之间
            local col = (i - 1) % spells_per_row
            
            -- 计算法术图标的水平绘制位置
            -- x + 4: 基础水平偏移（窗口左边缘 + 4像素）
            -- col * (spell_size + spacing): 根据列号计算偏移量
            -- spell_size: 单元格大小（12像素），用于控制法术之间的间距
            local spell_x = x + 4 + col * (spell_size + spacing)
            -- 计算法术图标的垂直绘制位置
            -- y: 法术区域的起始垂直位置
            -- row * row_height: 根据行号计算垂直偏移量
            local spell_y = y + row * row_height
            
            -- 从全局法术信息表中获取当前法术的详细信息
            -- 使用 and 运算符确保 action_table 存在才访问，避免 nil 错误
            local spell_info = action_table_ref and action_table_ref[spell_id]
            -- 检查法术信息是否存在
            if(spell_info ~= nil) then
                -- 根据法术类型获取对应的背景精灵图片路径
                -- 不同类型的法术（投射物、修饰符等）使用不同的背景图片
                local bg_sprite = get_bg_sprite(spell_info.type)
                -- 设置下一个绘制元素的Z轴层级为1                           
                -- Z轴层级控制绘制顺序，值越小越先绘制（在底层）
                z_set_next_relative(gui, 1)
                -- 绘制法术背景图片
                -- 参数: GUI对象, 唯一ID, x坐标, y坐标, 图片路径, 透明度1.0, 缩放比例1.0
                gui_image_bounded(gui, get_id("spell_bg_"..i), spell_x, spell_y, bg_sprite, 1.0, 1.0)
                
                -- 从法术信息中获取法术图标的精灵路径
                local sprite = spell_info.sprite
                -- 设置下一个绘制元素的Z轴层级为0
                -- Z轴层级控制绘制顺序，值越小越先绘制（在底层）
                z_set_next_relative(gui, 0)
                -- 绘制法术图标图片
                -- 参数: GUI对象, 唯一ID, x坐标, y坐标, 图片路径, 透明度1.0, 缩放比例1.0
                gui_image_bounded(gui, get_id("spell_"..i), spell_x, spell_y, sprite, 1.0, 1.0)
            end
        end
        
        -- 计算显示所有法术所需的行数
        -- 使用向上取整确保即使最后一行不完整也计入
        local num_rows = math.ceil(#spell_library / spells_per_row)
        -- 更新窗口的高度以适应所有法术
        -- 12: 标题区域的高度
        -- num_rows * row_height: 法术网格区域的总高度
        -- 10: 底部留白空间
        window.height = 12 + num_rows * row_height + 10
    end
    
    -- 自动法杖编辑器窗口函数
    auto_wand_editor_window.func = function(window)
        local x = -window.x_scroll
        local y = 0
        
        -- 实时读取当前法杖信息
        local wand_id = wand_manager.get_player_wand()
        local capacity = 0
        local spells_per_round = 1
        
        if(wand_id ~= nil) then
            capacity, spells_per_round = wand_manager.get_wand_config(wand_id)
        end
        
        -- 获取自动法杖编辑器的状态
        local editor_state = auto_wand_editor_ref.get_state()
        local selected_spells = editor_state.selected_spells or {}
        
        -- 绘制标题
        GuiText(gui, x + 4, y, "Auto Wand Editor")
        y = y + 10
        
        -- 显示法杖信息（实时更新）
        GuiText(gui, x + 4, y, "Capacity: " .. capacity .. " | Per Round: " .. spells_per_round)
        y = y + 12
        
        -- 添加"配置"按钮（左侧）
        local config_pressed = GuiButton(gui, get_id("config_button"), x + 4, y, "配置")
        if(config_pressed) then
            auto_wand_editor_ref.config_from_library(capacity)
        end
        
        -- 添加"应用"按钮（右侧）
        local apply_pressed = GuiButton(gui, get_id("apply_button"), x + 40, y, "应用")
        if(apply_pressed) then
            auto_wand_editor_ref.apply_to_wand()
        end
        
        -- 添加"自动循环"按钮（第三列）
        local auto_loop_pressed = GuiButton(gui, get_id("auto_loop_button"), x + 80, y, "自动循环")
        if(auto_loop_pressed) then
            auto_wand_editor_ref.toggle_auto_loop()
        end
        y = y + 12
        
        -- 显示伤害统计
        local dummies = dummy_spawner_ref.get_dummies()
        damage_stats_ref.update(dummies)
        
        GuiText(gui, x + 4, y, "Damage Stats:")

        local damage_state = damage_stats_ref.get_state()
        
        -- 玩家伤害（使用format_damage格式化）
        local player_damage_text = format_damage(damage_state.player_damage, false, "∞")
        GuiText(gui, x + 4 + 100, y, "Player: " .. player_damage_text)
        y = y + 12
    
        -- 假人伤害统计（并排显示，使用format_damage格式化）
        local dummy_x = x + 4
        for i, damage in ipairs(damage_state.dummy_damage) do
            if(i == 5) then
                -- 第5个假人，换行
                dummy_x = x + 4
                y = y + 12
            end
            local damage_text = format_damage(damage, false, "∞")
            GuiText(gui, dummy_x, y, "D" .. tostring(i - 1) .. ": " .. damage_text)
            dummy_x = dummy_x + 50
        end
        y = y + 10
        
        -- 绘制法术序列
        local spells_per_row = 8
        local spell_size = 12
        local spacing = 8
        local row_height = spell_size + spacing
        
        for i, spell_id in ipairs(selected_spells) do
            local row = math.floor((i - 1) / spells_per_row)
            local col = (i - 1) % spells_per_row
            
            local spell_x = x + 4 + col * (spell_size + spacing)
            local spell_y = y + row * row_height
            
            local spell_info = action_table_ref and action_table_ref[spell_id]
            if(spell_info ~= nil) then
                local bg_sprite = get_bg_sprite(spell_info.type)
                z_set_next_relative(gui, 1)
                gui_image_bounded(gui, get_id("editor_spell_bg_"..i), spell_x, spell_y, bg_sprite, 1.0, 1.0)
                
                local sprite = spell_info.sprite
                z_set_next_relative(gui, 0)
                gui_image_bounded(gui, get_id("editor_spell_"..i), spell_x, spell_y, sprite, 1.0, 1.0)
                
                -- 显示槽位编号
                GuiText(gui, spell_x, spell_y + spell_size, tostring(i))
            end
        end
        
        -- 计算窗口高度
        local num_rows = math.ceil(#selected_spells / spells_per_row)
        local dummies = dummy_spawner_ref.get_dummies()
        local num_dummies = #dummies
        local dummy_rows = math.ceil(num_dummies / 4)
        window.height = 50 + dummy_rows * 15 + num_rows * row_height
    end
end

-- 导出模块
return {
    gui = gui,
    spell_library_window = spell_library_window,
    auto_wand_editor_window = auto_wand_editor_window,
    initialize_gui = initialize_gui,
    calculate_camera_and_mouse_coords = calculate_camera_and_mouse_coords,
    get_bg_sprite = get_bg_sprite,
    create_toggle_buttons = create_toggle_buttons,
    setup_window_functions = setup_window_functions
}
