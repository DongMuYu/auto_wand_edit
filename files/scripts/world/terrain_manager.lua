-- 地形管理模块
-- 负责重新生成测试场地地形

local terrain_manager = {}

-- 加载实验室配置模块
local lab_config = dofile("mods/auto_wand_edit/files/scripts/config/lab_config.lua")

-- 重新生成地形
-- 加载wand_lab实体来重新生成测试场地地形
function terrain_manager.regenerate_terrain()
    -- 加载wand_lab实体来重新生成地形
    local lab_entity = EntityLoad("mods/auto_wand_edit/files/biome_impl/wand_lab/wand_lab.xml", lab_config.config.lab_x, lab_config.config.lab_y)
    if(lab_entity ~= nil) then
        -- GamePrint("Terrain regenerated")
    else
        GamePrint("Failed to regenerate terrain")
    end
end

return terrain_manager
