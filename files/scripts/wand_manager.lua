-- 法杖管理模块
-- 负责管理玩家法杖的获取、配置和填充操作

local wand_manager = {}

-- 获取玩家手中的法杖
-- @param auto_equip 如果没有手持法杖，是否自动装备第一根法杖（默认false）
-- @return wand_id 玩家手中法杖的实体ID，如果没有则返回nil
function wand_manager.get_player_wand(auto_equip)
    auto_equip = auto_equip or false
    
    local player = EntityGetWithTag("player_unit")[1]
    if(player == nil) then
        return nil
    end
    
    local inventory = EntityGetFirstComponent(player, "Inventory2Component")
    if(inventory == nil) then
        return nil
    end
    
    -- 检查当前是否手持法杖
    local active_item = ComponentGetValue2(inventory, "mActiveItem")
    if(active_item ~= nil and EntityHasTag(active_item, "wand")) then
        return active_item
    end
    
    -- 如果需要自动装备且没有手持法杖，查找库存中的第一根法杖
    if(auto_equip) then
        local all_items = GameGetAllInventoryItems(player)
        if(all_items == nil) then
            return nil
        end
        
        -- 查找第一根法杖
        for i, item_id in ipairs(all_items) do
            if(EntityHasTag(item_id, "wand")) then
                -- 设置为激活物品
                ComponentSetValue2(inventory, "mActiveItem", item_id)
                return item_id
            end
        end
    end
    
    return nil
end

-- 确保玩家手持法杖
-- 该函数会查找玩家库存中的第一根法杖，并将其设置为激活物品（手持）
-- @return wand_id 玩家手中法杖的实体ID，如果没有则返回nil
function wand_manager.ensure_player_holds_wand()
    return wand_manager.get_player_wand(true)
end

-- 获取法杖的容量和配置信息
-- @param wand_id 法杖实体ID
-- @return capacity 法杖容量
-- @return spells_per_round 每轮施法数
function wand_manager.get_wand_config(wand_id)
    local ability = EntityGetFirstComponentIncludingDisabled(wand_id, "AbilityComponent")
    if(ability == nil) then
        return 0, 1
    end
    
    local capacity = EntityGetWandCapacity(wand_id)
    local spells_per_round = ComponentObjectGetValue2(ability, "gun_config", "actions_per_round") or 1
    
    return capacity, spells_per_round
end

-- 将法术填充到法杖中
-- @param wand_id 法杖实体ID
-- @param spell_sequence 法术序列数组
function wand_manager.fill_wand_with_spells(wand_id, spell_sequence)
    local WANDS = dofile("mods/auto_wand_edit/files/lib/wands.lua")
    
    -- 清空法杖
    WANDS.wand_clear_actions(wand_id)
    
    -- 使用AddGunAction添加法术到法杖
    -- 这是Noita官方API，比手动创建实体更可靠
    for index, action_id in pairs(spell_sequence) do
        AddGunAction(wand_id, action_id)
    end
    
    -- 重新生成法杖动作（关键步骤）
    GameRegenItemAction(wand_id)
    
    -- 强制刷新玩家手中的法杖（关键步骤）
    local player = EntityGetWithTag("player_unit")[1]
    if(player ~= nil) then
        local inv2_comp = EntityGetFirstComponent(player, "Inventory2Component")
        if(inv2_comp ~= nil) then
            ComponentSetValue2(inv2_comp, "mForceRefresh", true)
            ComponentSetValue2(inv2_comp, "mActualActiveItem", 0)
            ComponentSetValue2(inv2_comp, "mDontLogNextItemEquip", true)
        end
        
        -- 额外的刷新步骤：重新装备法杖
        local inventory = GameGetAllInventoryItems(player)
        if(inventory ~= nil) then
            for _, item_id in ipairs(inventory) do
                if(item_id == wand_id) then
                    GamePickUpInventoryItem(player, item_id, false)
                    break
                end
            end
        end
    end
end

return wand_manager
