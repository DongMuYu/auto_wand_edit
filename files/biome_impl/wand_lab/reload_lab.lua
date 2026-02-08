-- 加载实验室配置模块
local lab_config = dofile("mods/auto_wand_edit/files/scripts/config/lab_config.lua")

-- 当物品被拾取时调用的函数
-- 参数: entity_item 表示被拾取的实体
function item_pickup( entity_item )
	-- 立即销毁被拾取的实体（重载器物品）
	EntityKill( entity_item )
	
	-- 注释掉的代码：重新加载像素场景（背景和前景）
	-- LoadPixelScene( "mods/auto_wand_edit/files/biome_impl/wand_lab/wang.png", "", lab_config.config.lab_x-640, lab_config.config.lab_y-360, "mods/auto_wand_edit/files/biome_impl/wand_lab/background.png", true, false, nil, 50, true )
	
	-- 重新加载法杖实验室的主XML文件，实现刷新实验室的功能
	-- 将wand_lab.xml实体加载到指定坐标
	EntityLoad( "mods/auto_wand_edit/files/biome_impl/wand_lab/wand_lab.xml", lab_config.config.lab_x, lab_config.config.lab_y )
end