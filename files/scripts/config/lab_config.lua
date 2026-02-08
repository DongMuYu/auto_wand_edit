-- 实验室配置模块
-- 集中管理实验室相关的配置

local lab_config = {}

-- 默认配置常量
lab_config.config = {
    lab_x = 14600,              -- 实验室X坐标
    lab_y = -6000,              -- 实验室Y坐标
    offset_y = 250,             -- Y轴偏移
    spawn_radius = 120,         -- 假人生成半径
    num_dummies = 8,            -- 假人数量
    player_hp = 40000,          -- 玩家生命值
    dummy_hp = 1000000,          -- 假人生命值
    shoot_radius = 180,         -- 射击目标半径
    max_shoot_distance = 320,   -- 最大射击距离
    auto_loop_delay = 10,       -- 自动循环延迟帧数（阶段切换延迟）
    shoot_delay = 80,           -- 自动循环射击延迟帧数（每次射击间隔）
    stats_update_interval = 60, -- 伤害统计更新间隔帧数
    terrain_regenerate_delay = 10, -- 地形生成延迟帧数
    wand_config_delay = 10,     -- 法杖配置延迟帧数
    position_threshold = 1      -- 位置偏移阈值（像素）
}

return lab_config
