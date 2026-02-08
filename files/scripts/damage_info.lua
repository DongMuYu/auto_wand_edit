-- 统计玩家造成的伤害
-- 返回包含各种伤害统计信息的表

-- 从全局变量获取最高DPS
local highest_dps = GlobalsGetValue("auto_wand_edit_recent_highest_dps", "")

-- 从全局变量获取总伤害
local total_damage = GlobalsGetValue("auto_wand_edit_recent_total_damage", "")

-- 获取所有玩家投射物
local player_projectiles = EntityGetWithTag("auto_wand_edit_player_projectile") or {}

-- 统计投射物伤害
local total_projectile_damage = 0
local total_projectiles = #player_projectiles

for k, v in pairs(player_projectiles) do
    local projectile = EntityGetFirstComponent(v, "ProjectileComponent")
    if projectile then
        local damage = ComponentGetValue2(projectile, "damage")
        total_projectile_damage = total_projectile_damage + damage
    end
end

-- 返回伤害统计表
return {
    highest_dps = highest_dps,
    total_damage = total_damage,
    total_projectile_damage = math.floor(total_projectile_damage * 25 + 0.5),
    total_projectiles = math.floor(total_projectiles)
}
