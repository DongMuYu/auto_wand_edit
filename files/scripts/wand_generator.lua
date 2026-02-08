-- 法杖生成器模块
-- 负责生成法杖、管理玩家库存和初始化法术库
-- 该模块提供了完整的法术库初始化流程，包括生成随机法杖、提取法术、为玩家提供空法杖等功能

local wand_generator = {}

-- 模块状态表
-- 用于存储模块运行时的所有状态信息
local state = {
    wand_decks = {},              -- 已生成的法杖牌组数组，每个元素是一个法术ID序列
    wand_levels = {},             -- 已生成法杖的等级数组
    generation_count = 0,         -- 已生成的法杖数量计数器
    spell_count = 0,              -- 已收集的法术总数（允许重复）
    generation_complete = false,   -- 是否完成指定数量个法术的收集
    player_wand_generated = false, -- 是否已为玩家生成法杖
    spell_library = {},           -- 从所有法杖中提取的法术库（允许重复）
    initialized = false,          -- 模块是否完全初始化
    player = nil                  -- 玩家实体引用
}

-- 生成单根法杖的法术资源
-- 该函数会在指定位置生成一根随机等级的法杖，提取其法术序列后删除法杖实体
-- @param x 可选的X坐标，如果不提供则随机生成（100-10000）
-- @param y 可选的Y坐标，如果不提供则随机生成（100-10000）
-- @return spell_sequence 法术序列（法术ID数组），如果失败返回nil
-- @return level 法杖等级（2-6），如果失败返回nil
function wand_generator.generate_single_wand(x, y)
    local level = math.random(2, 6)
    
    local wand_filename = string.format("data/entities/items/wand_level_%02d.xml", level)

    local rand_x = x or math.random(100, 10000)
    local rand_y = y or math.random(100, 10000)
    local wand_id = EntityLoad(wand_filename, rand_x, rand_y)
    
    if(wand_id == nil) then
        GamePrint("Failed to load wand: " .. wand_filename)
        return nil, nil
    end
    
    local spells = EntityGetAllChildren(wand_id) or {}
    local spell_sequence = {}
    
    for j, spell_id in ipairs(spells) do
        local comp = EntityGetFirstComponentIncludingDisabled(spell_id, "ItemActionComponent")
        if(comp ~= nil) then
            local action_id = ComponentGetValue2(comp, "action_id")
            table.insert(spell_sequence, action_id)
        end
    end
    
    -- GamePrint("Generated wand level " .. level .. " with " .. #spell_sequence .. " spells at (" .. rand_x .. ", " .. rand_y .. ")")
    EntityKill(wand_id)
    
    return spell_sequence, level
end

-- 分阶段生成法杖
-- 该函数每次调用生成一根法杖，直到收集到指定数量个法术为止
-- 每次调用时使用不同的随机坐标，确保每根法杖的生成位置不同
-- 允许法术重复，但每根法杖最多6个法术
function wand_generator.generate_wands()
    -- 检查是否已经完成指定数量个法术的收集
    if(state.generation_complete) then
        return
    end
    
    -- 计算当前已收集的法术总数
    local current_spell_count = 0
    for i, deck in ipairs(state.wand_decks) do
        current_spell_count = current_spell_count + #deck
    end
    
    -- 检查是否已达到35个法术
    if(current_spell_count >= 35) then
        state.generation_complete = true
        state.spell_count = current_spell_count
        -- GamePrint("Collected " .. current_spell_count .. " spells from " .. state.generation_count .. " wands")
        return
    end
    
    -- 生成随机坐标
    local rand_x = math.random(100, 10000)
    local rand_y = math.random(100, 10000)
    
    -- 使用随机坐标生成法杖
    local spell_sequence, level = wand_generator.generate_single_wand(rand_x, rand_y)
    
    if(spell_sequence ~= nil) then
        -- 限制每根法杖最多6个法术
        if(#spell_sequence > 6) then
            -- 随机选择6个法术
            local selected_spells = {}
            local indices = {}
            for i = 1, #spell_sequence do
                table.insert(indices, i)
            end
            -- 随机打乱索引
            for i = #indices, 2, -1 do
                local j = math.random(1, i)
                indices[i], indices[j] = indices[j], indices[i]
            end
            -- 取前6个
            for i = 1, 6 do
                table.insert(selected_spells, spell_sequence[indices[i]])
            end
            spell_sequence = selected_spells
            -- GamePrint("Limited wand to 6 spells")
        end
        
        table.insert(state.wand_decks, spell_sequence)
        table.insert(state.wand_levels, level)
        state.generation_count = state.generation_count + 1
        
        -- 计算新的法术总数
        local new_spell_count = current_spell_count + #spell_sequence
        -- GamePrint("Generated wand " .. state.generation_count .. " with " .. #spell_sequence .. " spells (Total: " .. new_spell_count .. "/100)")
    end
end

-- 获取玩家的快速物品栏
-- 快速物品栏是玩家可以快速访问的物品槽位（通常按1-8键切换）
-- 同时将玩家手中的所有法杖设置为不再乱序模式
-- @param player 玩家实体ID
-- @return inventory_quick 快速物品栏实体ID，如果获取失败返回nil
function wand_generator.get_player_inventory_quick(player)
    -- 获取玩家的库存组件
    -- Inventory2Component是Noita中管理玩家物品栏的组件
    local inventory = EntityGetFirstComponent(player, "Inventory2Component")
    
    -- 检查库存组件是否存在
    if(inventory == nil) then
        GamePrint("Player has no inventory component")
        return nil
    end

    -- 获取玩家的所有子实体
    -- 快速物品栏是玩家的一个子实体
    local player_children = EntityGetAllChildren(player)
    local inventory_quick = nil
    
    -- 检查玩家是否有子实体
    if(player_children == nil) then
        GamePrint("Player has no children")
        return nil
    end

    -- 遍历所有子实体，查找名为"inventory_quick"的实体
    -- 这是Noita中快速物品栏的标准命名
    for i, child_id in ipairs(player_children) do
        if(EntityGetName(child_id) == "inventory_quick") then
            inventory_quick = child_id
            break
        end
    end

    -- 检查是否找到快速物品栏
    if(inventory_quick == nil) then
        GamePrint("Player has no inventory_quick")
        return nil
    end
    
    return inventory_quick
end

-- 清空玩家的所有库存物品
-- 该函数会删除快速物品栏中的所有物品
-- @param player 玩家实体ID
-- @param inventory_quick 快速物品栏实体ID
function wand_generator.clear_player_inventory(player, inventory_quick)
    -- 获取快速物品栏中的所有物品
    local quick_items = EntityGetAllChildren(inventory_quick)
    
    -- 遍历并删除所有物品
    if(quick_items ~= nil) then
        for i, item_id in ipairs(quick_items) do
            -- GamePrint("Removing item from inventory: " .. item_id)
            -- 使用GameKillInventoryItem安全地删除物品
            -- 该函数会正确处理物品的移除逻辑
            GameKillInventoryItem(player, item_id)
        end
    end
end

-- 生成并清空法杖
-- 该函数生成一根随机等级的空法杖，供玩家使用
-- @return empty_wand_id 空法杖实体ID，如果生成失败返回nil
function wand_generator.generate_empty_wand()
    -- 随机生成法杖等级（2到6级）
    -- 使用较高的等级确保法杖有足够的容量
    local empty_wand_level = math.random(2, 6)
    local empty_wand_filename = string.format("data/entities/items/wand_level_%02d.xml", empty_wand_level)
    
    -- 在随机位置生成法杖
    local rand_x = math.random(100, 10000)
    local rand_y = math.random(100, 10000)
    local empty_wand_id = EntityLoad(empty_wand_filename, rand_x, rand_y)
    
    -- 检查法杖是否成功加载
    if(empty_wand_id == nil) then
        GamePrint("Failed to load empty wand: " .. empty_wand_filename)
        return nil
    end
    
    -- GamePrint("Generated wand level " .. empty_wand_level .. " at (" .. rand_x .. ", " .. rand_y .. "): " .. empty_wand_id)
    
    -- 使用WANDS库正确清空法杖上的所有法术
    -- WANDS.wand_clear_actions会正确删除所有带有"card_action"标签的子实体
    local WANDS = dofile("mods/auto_wand_edit/files/lib/wands.lua")
    WANDS.wand_clear_actions(empty_wand_id)
    -- GamePrint("Cleared all spells from wand using WANDS library")
    
    -- 获取法杖的能力组件
    -- AbilityComponent包含法杖的各种配置，如射速、法力消耗、乱序等
    local ability_component = EntityGetFirstComponentIncludingDisabled(empty_wand_id, "AbilityComponent")
    
    -- 设置法杖为非乱序模式
    -- shuffle_deck_when_empty为false表示法杖不会在空时重新洗牌
    -- 这样可以保证法术按固定顺序施放，便于调试
    if(ability_component ~= nil) then
        -- 使用WANDS库设置法杖属性，确保设置正确
        WANDS.ability_component_set_stat(ability_component, "shuffle_deck_when_empty", false)
        -- GamePrint("Set wand to non-shuffle mode using WANDS library")
    else
        GamePrint("Warning: AbilityComponent not found")
    end
    
    return empty_wand_id
end

-- 将法杖添加到玩家库存
-- 该函数将生成的空法杖添加到玩家的快速物品栏中
-- @param player 玩家实体ID
-- @param inventory_quick 快速物品栏实体ID
-- @param wand_id 要添加的法杖实体ID
-- @return success 是否成功添加（true/false）
function wand_generator.add_wand_to_inventory(player, inventory_quick, wand_id)
    -- 尝试将法杖添加到玩家库存
    -- GamePickUpInventoryItem是Noita的标准物品拾取函数
    -- GamePrint("Loading cleared wand to first slot: " .. wand_id)
    GamePickUpInventoryItem(player, wand_id, false)
    
    -- 使用WANDS库重新生成法杖的动作，确保法杖状态正确
    -- 这会强制游戏重新计算法杖的法术列表
    local WANDS = dofile("mods/auto_wand_edit/files/lib/wands.lua")
    GameRegenItemAction(wand_id)
    -- GamePrint("Regenerated wand actions")
    
    -- 再次设置法杖为非乱序模式
    -- 在拾取后重新设置是为了确保配置生效
    local ability_component = EntityGetFirstComponentIncludingDisabled(wand_id, "AbilityComponent")
    if(ability_component ~= nil) then
        WANDS.ability_component_set_stat(ability_component, "shuffle_deck_when_empty", false)
        -- GamePrint("Set wand to non-shuffle mode (after pickup)")
    else
        GamePrint("Warning: AbilityComponent not found after pickup")
    end
    
    -- 验证法杖是否成功添加到库存
    local new_quick_items = EntityGetAllChildren(inventory_quick)
    if(new_quick_items == nil or #new_quick_items == 0) then
        GamePrint("Failed to add wand to inventory")
        return false
    else
        -- 遍历快速物品栏，查找法杖
        local wand_found = false
        for i, item_id in ipairs(new_quick_items) do
            if(item_id == wand_id) then
                wand_found = true
                -- GamePrint("Successfully loaded cleared wand to slot " .. i)
                break
            end
        end
        
        -- 返回添加结果
        if(wand_found) then
            -- 将玩家手中的所有法杖设置为不再乱序模式
            -- 参考天赋"NO_MORE_SHUFFLE"的实现
            local WANDS = dofile("mods/auto_wand_edit/files/lib/wands.lua")
            local wands = EntityGetWithTag("wand")
            
            for i, wand in ipairs(wands) do
                -- 获取法杖的能力组件
                local ability_comp = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
                if(ability_comp ~= nil) then
                    -- 使用WANDS库设置法杖为非乱序模式
                    WANDS.ability_component_set_stat(ability_comp, "shuffle_deck_when_empty", false)
                    -- GamePrint("Set wand " .. wand .. " to non-shuffle mode")
                end
            end
            
            -- 重新生成所有法杖的动作，确保设置生效
            for i, wand in ipairs(wands) do
                GameRegenItemAction(wand)
            end
            -- GamePrint("Regenerated all wand actions")
            
            return true
        else
            GamePrint("Warning: Wand not found in inventory")
            return false
        end
    end
end

-- 生成玩家法杖
-- 该函数是生成玩家可用法杖的完整流程：
-- 1. 获取玩家快速物品栏
-- 2. 清空玩家库存
-- 3. 生成空法杖
-- 4. 将法杖添加到玩家库存
-- @param player 玩家实体ID
-- @return success 是否成功生成（true/false）
function wand_generator.generate_player_wand(player)
    -- 获取玩家快速物品栏
    local inventory_quick = wand_generator.get_player_inventory_quick(player)
    if(inventory_quick == nil) then
        return false
    end
    
    -- 清空玩家库存，为法杖腾出空间
    wand_generator.clear_player_inventory(player, inventory_quick)
    
    -- 生成空法杖
    local empty_wand_id = wand_generator.generate_empty_wand()
    if(empty_wand_id == nil) then
        return false
    end
    
    -- 将法杖添加到玩家库存
    return wand_generator.add_wand_to_inventory(player, inventory_quick, empty_wand_id)
end

-- 从牌组中提取法术
-- 该函数遍历所有法杖牌组，提取所有法术ID到一个数组中
-- 注意：此函数不会去重，只是简单地将所有法术ID收集起来
-- @param decks 法术牌组数组，每个元素是一个法术ID序列
-- @return spell_library 法术库（法术ID数组）
function wand_generator.extract_spells_from_decks(decks)
    local spell_library = {}
    
    -- 遍历每个法杖牌组
    for i, deck in ipairs(decks) do
        -- 遍历牌组中的每个法术
        for j, spell_id in ipairs(deck) do
            -- 将法术ID添加到法术库
            table.insert(spell_library, spell_id)
        end
    end
    
    return spell_library
end

-- 初始化法术库
-- 该函数是模块的主入口，负责整个初始化流程
-- 初始化分为两个阶段：
-- 1. 第一阶段：分阶段生成法杖，直到收集到指定数量个法术（允许重复）
-- 2. 第二阶段：为玩家生成空法杖，并构建法术库
-- @param player 玩家实体ID
function wand_generator.initialize_spell_library(player)
    -- 保存玩家引用
    state.player = player
    
    -- 第一阶段：分阶段生成法杖，直到收集到指定数量个法术（允许重复）
    -- 每次调用生成一根法杖，每根法杖最多6个法术
    wand_generator.generate_wands()
    
    -- 第二阶段：为玩家生成空法杖
    -- 只有在收集到35个法术后才执行
    if(state.generation_complete and not state.player_wand_generated) then
        -- 从所有法杖牌组中提取法术，构建法术库（允许重复）
        state.spell_library = wand_generator.extract_spells_from_decks(state.wand_decks)

        -- 为玩家生成空法杖
        local success = wand_generator.generate_player_wand(player)
        
        -- 如果成功，标记初始化完成
        if(success) then
            state.player_wand_generated = true
            state.initialized = true
            -- 输出法术库大小信息
            -- GamePrint("Initialization complete! Spell library has " .. #state.spell_library .. " spells")
        end
    end
end

-- 获取模块状态
-- 该函数允许外部访问模块的内部状态
-- @return state 模块状态表的副本
function wand_generator.get_state()
    return state
end

-- 设置模块状态
-- 该函数允许外部设置模块的内部状态
-- 主要用于保存/加载功能或测试
-- @param new_state 新的状态表
function wand_generator.set_state(new_state)
    state = new_state
end

-- 刷新法术库和玩家手中法杖
-- 该函数会清空所有数据并重新初始化，包括：
-- 1. 清空已生成的法杖数据
-- 2. 清空法术库
-- 3. 重置所有状态标志
-- 4. 清空玩家手中的法杖
-- 5. 重新开始生成法术库
function wand_generator.refresh()
    -- 清空法杖数据
    state.wand_decks = {}
    state.wand_levels = {}
    
    -- 清空法术库
    state.spell_library = {}
    
    -- 重置计数器
    state.generation_count = 0
    state.spell_count = 0
    
    -- 重置状态标志
    state.generation_complete = false
    state.player_wand_generated = false
    state.initialized = false
    
    -- 如果有玩家，清空玩家手中的法杖
    if(state.player ~= nil) then
        local inventory_quick = wand_generator.get_player_inventory_quick(state.player)
        if(inventory_quick ~= nil) then
            wand_generator.clear_player_inventory(state.player, inventory_quick)
        end
    end
    
    -- GamePrint("Spell library and player wand refreshed. Reinitializing...")
end

-- 返回模块
return wand_generator
