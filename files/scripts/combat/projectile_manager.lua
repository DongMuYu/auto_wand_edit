-- 投射物管理模块
-- 负责清理场景中的投射物

local projectile_manager = {}

-- 静默杀死投射物
-- 禁用投射物的爆炸和闪电效果，然后删除实体
-- @param proj_id 投射物实体ID
local function silent_kill(proj_id)
    for _, proj_comp in ipairs(EntityGetComponentIncludingDisabled(proj_id, "ProjectileComponent") or {}) do
        ComponentSetValue2(proj_comp, "on_death_explode", false)
        ComponentSetValue2(proj_comp, "on_lifetime_out_explode", false)
    end
    for _, expl_comp in ipairs(EntityGetComponentIncludingDisabled(proj_id, "ExplosionComponent") or {}) do
        ComponentSetValue2(expl_comp, "trigger", "ON_CREATE")
    end
    for _, litn_comp in ipairs(EntityGetComponentIncludingDisabled(proj_id, "LightningComponent") or {}) do
        EntitySetComponentIsEnabled(proj_id, litn_comp, false)
    end
    EntityKill(proj_id)
end

-- 清除所有投射物
-- 参考update.lua中的silent_kill函数实现
function projectile_manager.clear_projectiles()
    for _, proj_id in ipairs(EntityGetWithTag("projectile") or {}) do
        silent_kill(proj_id)
    end
    for _, proj_id in ipairs(EntityGetWithTag("player_projectile") or {}) do
        silent_kill(proj_id)
    end
end

return projectile_manager
