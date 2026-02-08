# Noita 法杖调试工具 (Wand Debug Tool)

## 概述

这是一个用于 Noita 游戏的法杖调试模组，可以可视化法杖的施法过程，帮助玩家理解法杖的工作原理、调试复杂的法术组合，以及优化法杖配置。

## 功能特性

### 1. 法杖牌堆可视化
- 实时显示法杖的牌堆、手牌和弃牌堆
- 可视化卡牌在三个牌堆之间的移动
- 支持动画效果，展示卡牌的流动过程

### 2. 施法状态树
- 显示每个法术的施法状态
- 展示投射物信息、触发器类型、计时器等
- 支持折叠/展开状态详情

### 3. 回放控制
- 播放/暂停施法过程
- 前进/后退单步
- 循环播放
- 跳转到任意位置

### 4. 配置选项
- 修改法杖属性（法力值、施法速度等）
- 修改玩家属性（生命值、伤害倍数等）
- 设置法术使用次数
- 启用/禁用无限法术

## 技术实现原理

### 1. 调试器初始化

调试器的核心在 `files/debugger.lua` 中实现。初始化时会：

```lua
init_debugger = function()
    debugging = true
    dofile( "data/scripts/gun/gun.lua" );
    
    -- 重写核心函数
    register_action = function(state) ... end
    order_deck = function() ... end
    ...
end
```

**关键点**：
- 加载游戏的枪械脚本（`gun.lua`）
- 重写 `register_action` 函数来跟踪动作注册
- 重写 `order_deck` 函数来记录牌堆排序

### 2. 函数重写机制

#### 2.1 重写 order_deck

`order_deck` 是游戏中用于排序/洗牌法杖牌堆的函数。调试器重写这个函数来记录牌堆顺序的变化：

```lua
-- 保存原始函数
local original_order_deck = order_deck

-- 重写函数
function order_deck()
    -- 为每张牌设置临时索引
    for i, a in ipairs(deck) do
        a.temp_index = i
    end
    
    -- 调用原始函数
    original_order_deck()
    
    -- 记录顺序变化
    local order = {}
    for i, a in ipairs(deck) do
        order[i] = a.temp_index
        a.temp_index = nil
    end
    
    -- 创建快照
    make_snapshot("order_deck", {order=order})
end
```

**工作原理**：
1. 在排序前为每张牌记录当前索引
2. 调用原始的排序函数
3. 比较排序前后的索引，记录变化
4. 创建快照事件，保存到历史记录

#### 2.2 重写 table.insert 和 table.remove

为了跟踪卡牌在牌堆之间的移动，调试器重写了 `table.insert` 和 `table.remove` 函数：

```lua
-- 缓存原始函数
local table_insert = table.insert
local table_remove = table.remove

-- 重写 insert
function table.insert(list, pos, value)
    -- 调用原始函数
    table_insert(list, pos, value)
    
    -- 如果是卡牌移动，记录事件
    if is_card_move(list, pos, value) then
        make_snapshot("card_move", {
            source = get_source_deck(list),
            dest = get_dest_deck(list),
            index = pos
        })
    end
end
```

**工作原理**：
1. 拦截所有的 `table.insert` 和 `table.remove` 调用
2. 检测是否是卡牌相关的操作
3. 记录卡牌的来源和目标牌堆
4. 创建快照事件

### 3. 快照机制

快照机制是调试器的核心，用于记录每个状态变化：

```lua
-- 创建快照
function make_snapshot(type, info)
    local snapshot = {
        type = type,
        info = info,
        c = current_cast_state,
        c_final = current_cast_state_final,
        node = current_node,
        timestamp = GameGetFrameNum()
    }
    
    -- 添加到历史记录
    table.insert(cast_history, snapshot)
end
```

**快照类型**：
- `action`: 法术开始施法
- `action_end`: 法术施法结束
- `card_move`: 卡牌在牌堆间移动
- `add_ac_card`: 添加永久附加卡牌
- `delete_ac_card`: 删除永久附加卡牌
- `order_deck`: 牌堆排序
- `new_cast_state`: 创建新的施法状态

### 4. 施法状态树

施法状态树用于可视化法术的执行流程：

```lua
-- 施法状态结构
local cast_states = {
    [state_id] = {
        c = cast_state,           -- 当前施法状态
        current = current_state,   -- 当前状态
        children = {}            -- 子状态列表
    }
}
```

**状态类型**：
- `root`: 根节点，代表一次完整的施法
- `timer`: 计时器触发
- `trigger`: 触发器触发
- `death_trigger`: 死亡触发器触发

### 5. GUI 渲染

GUI 渲染在 `init.lua` 中实现，主要包含以下部分：

#### 5.1 窗口系统

```lua
-- 窗口配置
config_window = {
    show = true,
    index = 1,
    x = 10,
    y = 10,
    width = 300,
    height = 400,
    title = "Config"
}
```

#### 5.2 牌堆绘制

```lua
function draw_deck(deck_name, x, y, width, mx, my)
    -- 获取牌堆
    local deck = get_deck(deck_name)
    
    -- 绘制每张卡牌
    for i, card in ipairs(deck) do
        local card_x = x + (i-1) * card_spacing
        local card_y = y
        
        -- 动画化卡牌
        animate_card(card, sprite_entity, cx, cy, gui_to_world_scale)
        
        -- 绘制卡牌
        draw_card(card, card_x, card_y)
    end
end
```

#### 5.3 施法状态树绘制

```lua
function draw_cast_states(states, x, y, parent_x, parent_y)
    for i, c in ipairs(states) do
        -- 绘制连接线
        if(parent_x ~= nil) then
            draw_spline(gui, parent_x, parent_y, x, y, ...)
        end
        
        -- 绘制当前状态
        local state_width, state_height = draw_cast_state(cast_states[c], x, y)
        
        -- 递归绘制子状态
        draw_cast_states(cast_states[c].children, child_x, child_y, x, y)
    end
end
```

### 6. 回放系统

回放系统允许用户重新播放施法过程：

```lua
function step_history(steps, no_instant_step, skip_actions)
    local start_i = current_i
    
    -- 处理每个事件
    while current_i < start_i + steps do
        local e = cast_history[current_i]
        
        -- 根据事件类型处理
        if(e.type == "action") then
            push_action(e.node)
        elseif(e.type == "action_end") then
            pop_action()
        elseif(e.type == "card_move") then
            move_card(e.info.source, e.info.dest, e.info.index)
        ...
        
        current_i = current_i + 1
    end
end
```

**回放控制**：
- `steps`: 步进的步数
- `no_instant_step`: 是否不立即步进
- `skip_actions`: 是否跳过动作

### 7. 配置系统

配置系统允许用户修改游戏参数：

```lua
-- 配置选项
local options = {
    {id="mana", name="Mana", type="number", value=0, min=0, max=100},
    {id="maximize_uses", name="Spell Uses", type="boolean", value=false},
    {id="unlimited_spells", name="Unlimited Spells", type="boolean", value=false},
    ...
}

-- 绘制配置
function draw_config(x, y, window_x, window_y)
    for i, option in ipairs(options) do
        -- 绘制按钮
        local clicked = GuiButton(gui, get_id(), x, y, button_text)
        
        -- 如果选项被覆盖，绘制额外控件
        if(option.override) then
            if(option.type == "number") then
                -- 绘制滑块
                option.value = GuiSlider(gui, get_id(), x, y, ...)
            elseif(option.type == "boolean") then
                -- 切换布尔值
                option.value = not option.value
            end
        end
    end
end
```

## 使用方法

### 启用调试器

1. 将模组放入 Noita 的 `mods` 文件夹
2. 在游戏中，点击右下角的图标打开调试界面
3. 使用法杖施法，调试器会自动记录和显示施法过程

### 界面操作

- **牌堆窗口**: 显示法杖的牌堆、手牌和弃牌堆
- **施法状态窗口**: 显示每个法术的施法状态树
- **配置窗口**: 修改法杖和玩家属性
- **回放控制**: 使用播放/暂停/前进/后退按钮控制回放

### 配置选项

- **Mana**: 设置法杖的法力值
- **Spell Uses**: 设置法术使用次数（Max 或 0）
- **Unlimited Spells**: 启用无限法术
- **Reload Time**: 设置重装时间
- **Fire Rate Wait**: 设置射击间隔
- **Spread**: 设置散射角度
- **Speed**: 设置投射物速度

## 文件结构

```
auto_wand_edit/
├── init.lua                    # 主初始化文件，GUI 渲染
├── mod.xml                     # 模组配置
├── files/
│   ├── debugger.lua            # 调试器核心逻辑
│   ├── ui.lua                # UI 工具函数
│   ├── utils.lua             # 通用工具函数
│   ├── wand.lua              # 法杖相关函数
│   ├── spell_info.lua        # 法术信息获取
│   ├── cast_state_properties.lua  # 施法状态属性
│   ├── debug_card.xml        # 调试卡牌实体定义
│   ├── move_card.lua         # 卡牌移动动画
│   └── ui_gfx/             # UI 图形资源
```

## 核心概念

### 1. 牌堆系统

法杖有三个牌堆：
- **Deck**: 法术牌堆，存储可用的法术
- **Hand**: 手牌，当前准备施法的法术
- **Discarded**: 弃牌堆，已施法的法术

### 2. 施法流程

1. 从牌堆抽取法术到手牌
2. 执行手牌中的法术
3. 将手牌移到弃牌堆
4. 如果牌堆为空，将弃牌堆移回牌堆并重新排序

### 3. 动作树

动作树表示法术的执行流程：
- 根节点：完整的施法
- 子节点：由触发器、计时器等产生的子施法
- 叶子节点：最终的投射物

### 4. 快照历史

快照历史记录每个状态变化：
- 时间戳
- 事件类型
- 相关信息（卡牌移动、状态变化等）
- 当前施法状态

## 技术细节

### 性能优化

1. **函数缓存**: 缓存常用的函数引用
   ```lua
   local table_insert = table.insert
   local table_remove = table.remove
   ```

2. **延迟加载**: 等待 `OnModPostInit` 再加载法术信息
   ```lua
   if(not debug_wand) then
       action_table, projectile_table, ... = SPELL_INFO.get_spell_info()
       debug_wand = init_debugger()
   end
   ```

3. **边界检查**: 只渲染可见区域的内容
   ```lua
   if(x+state.width < bound_x_min or x > bound_x_max or 
      y+state.height < bound_y_min or y > bound_y_max) then
       return state.width, state.height
   end
   ```

### 兼容性处理

1. **Mod 兼容**: 等待其他 mod 完成初始化
   ```lua
   -- 等待 Goki 的 Things mod 完成
   if(not debug_wand) then
       ...
   end
   ```

2. **游戏版本适配**: 检查组件是否存在
   ```lua
   local comp = EntityGetFirstComponent(player, "DamageModelComponent")
   if(comp ~= nil) then
       player_hp = ComponentGetValue2(comp, "hp")
   end
   ```

## 常见问题

### Q: 调试器会影响游戏性能吗？

A: 调试器会有一定的性能开销，但已经做了优化。如果遇到性能问题，可以：
- 关闭动画效果
- 减少显示的窗口
- 在不需要时关闭调试器

### Q: 为什么有些法术没有显示？

A: 某些特殊法术可能没有被正确识别。可以检查：
- 法术 ID 是否在 `spell_info.lua` 中定义
- 法术类型是否正确分类

### Q: 如何重置窗口布局？

A: 点击右下角的重置窗口按钮，或者删除模组的设置文件。

## 开发者指南

### 添加新的配置选项

在 `init.lua` 的 `options` 表中添加新选项：

```lua
{id="new_option", name="New Option", type="number", value=10, min=0, max=100}
```

### 添加新的施法状态属性

在 `files/cast_state_properties.lua` 中添加新属性：

```lua
{
    name = "Property Name",
    get = function(c) return c.property end,
    default = default_value,
    format = function(value) return tostring(value) end
}
```

### 自定义 UI 图标

将图标文件放入 `files/ui_gfx/` 文件夹，并在代码中引用：

```lua
local icon = base_dir.."files/ui_gfx/custom_icon.png"
GuiImage(gui, get_id(), x, y, icon, 1, 1)
```

## 许可证

本模组基于 MIT 许可证开源。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 致谢

- Noita 社区提供的法术数据
- Goki 的 Things mod 提供的兼容性支持
- 所有测试者和反馈者
