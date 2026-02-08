-- 法术选择模块
-- 负责从法术库中选择法术并配置到法杖

local spell_selector = {}

-- 模块状态表
local state = {
    spell_library = {},       -- 法术库
    selected_spells = {},     -- 当前选择的法术序列
    wand_generator_ref = nil   -- 法杖生成器模块引用
}

-- 初始化法术选择模块
-- @param spell_library 法术库数组
-- @param wand_generator_ref 法杖生成器模块引用
function spell_selector.initialize(spell_library, wand_generator_ref)
    state.spell_library = spell_library or {}
    state.wand_generator_ref = wand_generator_ref
end

-- 从法术库中随机选择法术
-- @param count 要选择的法术数量
-- @return selected_spells 选择的法术ID数组
function spell_selector.select_random_spells(count)
    local selected = {}
    local spell_library = state.spell_library or {}
    
    if(#spell_library == 0) then
        GamePrint("Spell library is empty!")
        return selected
    end
    
    for i = 1, count do
        local random_index = math.random(1, #spell_library)
        local spell_id = spell_library[random_index]
        table.insert(selected, spell_id)
    end
    
    return selected
end

-- 从法术库中配置法术序列（不立即应用到法杖）
-- @param capacity 法术数量
function spell_selector.config_from_library(capacity)
    -- 从法杖生成器获取最新的法术库
    local spell_library = {}
    if(state.wand_generator_ref ~= nil) then
        local wand_generator_state = state.wand_generator_ref.get_state()
        spell_library = wand_generator_state.spell_library or {}
    end
    
    if(#spell_library == 0) then
        GamePrint("Spell library is empty!")
        return
    end
    
    -- 更新本地法术库
    state.spell_library = spell_library
    
    -- 随机选择法术
    local selected = spell_selector.select_random_spells(capacity)
    state.selected_spells = selected
end

-- 将当前序列配置到手中的法杖
-- 将之前配置的法术序列应用到玩家手中的法杖
function spell_selector.apply_to_wand()
    local wand_manager = dofile("mods/auto_wand_edit/files/scripts/wand/wand_manager.lua")
    
    local wand_id = wand_manager.get_player_wand()
    if(wand_id == nil) then
        GamePrint("No wand in player's hand!")
        return
    end
    
    local selected_spells = state.selected_spells or {}
    if(#selected_spells == 0) then
        GamePrint("No spells configured!")
        return
    end
    
    -- 填充到法杖
    wand_manager.fill_wand_with_spells(wand_id, selected_spells)
end

-- 获取状态
-- @return state 状态表
function spell_selector.get_state()
    return state
end

return spell_selector
