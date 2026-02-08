-- 加载实验室配置模块
local lab_config = dofile("mods/auto_wand_edit/files/scripts/lab_config.lua")

-- 定义法杖实验室的中心坐标
local x, y = lab_config.config.lab_x, lab_config.config.lab_y

-- -- 获取并清理多余的法术可视化工作台实体
-- -- 在指定坐标范围内查找带有"workshop_spell_visualizer"标签的实体，保留一个，删除其余的
-- local wsv = EntityGetInRadiusWithTag( x - 78, y - 50, 6, "workshop_spell_visualizer" )
-- for i = 1, #wsv - 1 do
-- 	EntityKill( wsv[ i ] )
-- end

-- -- 获取并清理多余的工作台AABB碰撞体实体
-- -- 在指定坐标范围内查找带有"workshop_aabb"标签的实体，保留一个，删除其余的
-- local wsaabb = EntityGetInRadiusWithTag( x - 78, y - 50, 6, "workshop_aabb" )
-- for i = 1, #wsaabb - 1 do
-- 	EntityKill( wsaabb[ i ] )
-- end

-- -- 获取并清理多余的实验室重载器实体
-- -- 在指定坐标范围内查找带有"auto_wand_edit_lab_reloader"标签的实体，保留一个，删除其余的
-- local reloader = EntityGetInRadiusWithTag( x, y, 6, "auto_wand_edit_lab_reloader" )
-- for i = 1, #reloader - 1 do
-- 	EntityKill( reloader[ i ] )
-- end

-- -- 获取并清理多余的左侧目标假人实体
-- -- 在指定坐标范围内查找带有"auto_wand_edit_target_dummy"标签的实体，保留一个，删除其余的
-- local dummy_left = EntityGetInRadiusWithTag( x - 100, y, 6, "auto_wand_edit_target_dummy" )
-- for i = 1, #dummy_left - 1 do
-- 	EntityKill( dummy_left[ i ] )
-- end

-- -- 获取并清理多余的右侧目标假人实体
-- -- 在指定坐标范围内查找带有"auto_wand_edit_target_dummy"标签的实体，保留一个，删除其余的
-- local dummy_right = EntityGetInRadiusWithTag( x + 100, y, 6, "auto_wand_edit_target_dummy" )
-- for i = 1, #dummy_right - 1 do
-- 	EntityKill( dummy_right[ i ] )
-- end