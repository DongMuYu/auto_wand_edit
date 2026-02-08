-- 加载实验室配置模块
local lab_config = dofile("mods/auto_wand_edit/files/scripts/lab_config.lua")

-- 初始化法杖实验室的位置坐标
local x, y = lab_config.config.lab_x, lab_config.config.lab_y

-- 加载像素场景，包括前景和背景图像
-- 参数说明：前景图像路径、调色板文件(空)、x偏移、y偏移、背景图像路径、立即加载、不重复、无特效、层级50、启用
LoadPixelScene( "mods/auto_wand_edit/files/biome_impl/wand_lab/wang.png", "", lab_config.config.lab_x - lab_config.config.offset_y, lab_config.config.lab_y, "mods/auto_wand_edit/files/biome_impl/wand_lab/background.png", true, false, nil, 50, true )

-- -- 加载实验室重载器实体到指定位置
-- EntityLoad( "mods/auto_wand_edit/files/biome_impl/wand_lab/reload_lab.xml", x, y )

-- -- 加载法术可视化工作台实体
-- EntityLoad( "data/entities/buildings/workshop_spell_visualizer.xml", x - 78, y - 50 )

-- -- 加载工作台AABB碰撞体
-- EntityLoad( "data/entities/buildings/workshop_aabb.xml", x - 78, y - 50 )