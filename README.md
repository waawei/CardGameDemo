# CardGameDemo 卡牌游戏演示

一款用 **Godot Engine** 开发的卡牌策略游戏演示项目，展示了卡牌系统、战斗机制和卡牌进化等核心玩法。

## ✨ 项目特性

- 🎴 **卡牌系统**
  - 多个阵营的卡牌（星辉、森灵、影契）
  - 卡牌属性系统（攻击力、生命值、费用等）
  - 卡牌进化机制
  - 动态卡牌UI显示

- ⚔️ **战斗系统**
  - 玩家vs电脑的回合制战斗
  - 卡牌手牌管理
  - 怪物卡牌和魔法卡牌机制
  - 战场卡牌槽位系统

- 🎨 **视觉效果**
  - 卡牌悬停缩放动画
  - 卡牌翻转进化动画
  - 多种卡牌主题样式
  - 中文字体支持

- 📊 **游戏信息**
  - 实时行动日志记录
  - 回合阶段显示
  - 分数和生命值面板
  - 对手和玩家信息展示

## 🛠 技术栈

- **引擎**: Godot 4.x
- **脚本语言**: GDScript
- **数据格式**: JSON（卡牌数据库）
- **UI框架**: Godot节点系统
- **字体**: 思源黑体 CN、站酷小微

## 📁 项目结构

```
cardgamedemo/
├── Assets/                    # 游戏资源
│   ├── CardFaces/            # 卡牌插图
│   ├── CardTheme/            # 卡牌框架主题
│   ├── Portraits/            # 卡牌角色肖像
│   ├── Fonts/                # 字体文件
│   └── *.png                 # 游戏精灵图
├── Scenes/                   # 场景文件
│   ├── main.tscn            # 主场景
│   ├── Card.tscn            # 卡牌场景
│   ├── BattleManager.gd     # 战斗管理器
│   └── ...                   # 其他场景
├── Scripts/                  # 脚本代码
│   ├── Card.gd              # 卡牌脚本（核心）
│   ├── CardManager.gd       # 卡牌管理器
│   ├── BattleManager.gd     # 战斗管理器
│   ├── Deck.gd              # 牌组管理
│   ├── PlayerHand.gd        # 玩家手牌
│   ├── Abilities/           # 卡牌能力脚本
│   └── ...                   # 其他脚本
├── Data/
│   └── cards.json           # 卡牌数据库
├── project.godot            # 项目配置文件
├── RULES.md                 # 游戏规则
├── TODO.md                  # 开发计划
└── README.md               # 本文件
```

## 🚀 快速开始

### 前提条件

- **Godot Engine 4.x** 或更高版本
- 建议使用 Windows/Linux/macOS 系统

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/waawei/CardGameDemo.git
   cd CardGameDemo
   ```

2. **打开项目**
   - 打开 Godot Engine
   - 选择 "打开项目"
   - 选择项目文件夹中的 `project.godot`

3. **运行游戏**
   - 在Godot编辑器中按 `F5` 或点击 "运行项目"
   - 游戏应该在新窗口中启动

## 🎮 游戏玩法

### 基本概念

- **卡牌**: 包含攻击、防御、费用等属性的游戏单位
- **费用**: 使用卡牌所需的资源
- **进化**: 某些卡牌可以升级到更强的形式
- **回合**: 玩家轮流出牌和攻击

### 控制方式

- **鼠标拖拽**: 选中并拖动手中的卡牌
- **左键点击**: 选择卡牌或场景元素
- **结束回合按钮**: 完成当前回合

## 📊 卡牌系统详解

### 卡牌类型

| 类型 | 说明 |
|------|------|
| Monster | 怪物卡，有攻击力和生命值 |
| Magic | 魔法卡，通常有特殊效果 |
| Spell | 法术卡 |
| Support | 辅助卡 |
| Item | 物品卡 |

### 卡牌阵营

| 阵营 | 名称 | 卡牌框架 |
|------|------|--------|
| 星辉 | Xinghui | 月亮主题 |
| 森灵 | Senling | 森林主题 |
| 影契 | Yingqi | 阴影主题 |

### 卡牌属性

```json
{
  "CardId": "卡牌唯一ID",
  "Name": "卡牌名称",
  "Type": "卡牌类型",
  "Faction": "阵营",
  "Cost": 3,
  "Attack": 2,
  "Health": 4,
  "Description": "卡牌描述",
  "Keywords": ["关键字1", "关键字2"],
  "EvolveNext": "进化后的卡牌ID",
  "EvolveCost": 2
}
```

## 🔧 开发指南

### 核心脚本

#### [Card.gd](Scripts/Card.gd) - 卡牌脚本
负责卡牌的显示、交互和动画
- 卡牌视觉刷新
- 悬停和拖拽动画
- 卡牌进化动画

#### [BattleManager.gd](Scenes/BattleManager.gd) - 战斗管理
管理整个战斗流程
- 回合管理
- 卡牌出装逻辑
- 伤害计算

#### [CardManager.gd](Scripts/CardManager.gd) - 卡牌管理器
处理卡牌的生成和管理
- 卡牌实例化
- 卡牌信号连接
- 卡牌数据加载

### 添加新卡牌

1. 在 `Data/cards.json` 中添加卡牌定义
2. 准备卡牌肖像图片，放在 `Assets/Portraits/` 或 `Assets/CardFaces/` 中
3. 如需自定义能力，在 `Scripts/Abilities/` 中创建新脚本

### 修改卡牌视觉

编辑 [Card.gd](Scripts/Card.gd) 中的常量：

```gdscript
const STAT_COLORS := {
    "CostLabel": Color(0.92, 0.78, 0.25, 1.0),  # 费用标签颜色
    "Attack": Color(0.9, 0.28, 0.2, 1.0),     # 攻击数值颜色
    "Health": Color(0.2, 0.78, 0.35, 1.0)     # 生命值颜色
}

const FRAME_STYLES := {
    "xinghui": {...},     # 星辉框架
    "senling": {...},     # 森灵框架
    "yingqi": {...}       # 影契框架
}
```

## 🐛 已知问题与改进

详见 [TODO.md](TODO.md) 文件

## 📝 游戏规则

详细的游戏规则说明请参考 [RULES.md](RULES.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 📧 联系方式

- GitHub: [@waawei](https://github.com/waawei)
- 项目地址: https://github.com/waawei/CardGameDemo

## 🙏 致谢

感谢所有对此项目做出贡献的人！

---

**最后更新**: 2026年2月26日  
**项目状态**: 开发中 🚧
