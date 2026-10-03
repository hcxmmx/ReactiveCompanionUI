# Reactive Companion UI

为《杀戮尖塔 2》制作的智乃界面伴随角色 Mod，由 [hcxmmx](https://github.com/hcxmmx) 开发。
智乃会在主菜单和游戏过程中陪伴玩家，并提供少量主动查询功能。

当前版本：**0.1.0**。界面和台词目前为简体中文，已在 Windows 上进行游戏内测试。
游戏处于抢先体验阶段，更新可能改变 Mod 使用的接口。

## 功能

- 正面／侧身立绘随战斗状态切换，带有表情、眨眼和轻微呼吸动画。
- 入场、受击、胜利等节点的简短反馈，以及点击角色时的互动台词。
- 主动查看当前抽牌堆顶的一张牌、预计掉药率和下次商店删牌预计价格。
- 持有【杂耍】状态时，主动播报本回合前 3 张攻击牌；也可查询当前攻击牌计数。
- 可用时显示 SL 按钮，使用游戏已有存档快速重新载入当前单人游戏。
- 独立调整立绘、对话框和按钮组的位置；立绘与对话框可调整大小、透明度。
- 互动模式连续 10 秒没有操作智乃界面时自动收起；调整面板和拖动期间暂停计时。

## 安装

取得同一版本的 `ReactiveCompanionUI.json`、`ReactiveCompanionUI.dll` 和
`ReactiveCompanionUI.pck`，将三者放入游戏目录的 `mods/ReactiveCompanionUI/`，
重启游戏并在 Mod 管理界面启用。

启用或升级前，请检查是否同时装有手动版本和创意工坊版本，避免重复加载。
如果从源码构建，使用下方的构建步骤取得三件套。

## 操作

| 操作 | 效果 |
| --- | --- |
| 左键点击“互动” | 展开／收起功能按钮，并切换角色可交互状态 |
| 互动模式下左键点击智乃 | 一句互动台词 |
| 互动模式下右键拖动智乃 | 移动立绘及随行按钮 |
| 点击“调整” | 打开位置、大小和透明度设置 |
| 调整面板打开时右键拖动“互动” | 独立移动整组按钮 |
| 调整面板打开时右键拖动对话框 | 独立移动对话框 |

非互动模式下，立绘允许鼠标穿透，方便查看下方的游戏界面。
设置保存在游戏的 `user://ReactiveCompanionUI/settings.json`，升级会继续使用。

## 功能边界

- **顶牌**会主动揭示当前牌堆顺序中的第一张牌；请按自己的游玩习惯使用。
- **掉药率**按常规奖励规则估计，部分遗物、特殊奖励或其他 Mod 可能影响最终结果。
- **删牌**按当前进阶、删牌次数及价格修正估计；此后获得遗物等变化会影响实际价格。
- **杂耍**提供计数提示，不修改卡牌或状态效果。
- **SL**使用现有存档，不创建任意时点存档；联机游戏不会显示 SL 按钮。
- 当前测试主要覆盖单人 Windows 游戏，其他平台及联机兼容性尚未完整验证。

## 从源码构建

需要 Godot **4.5.1 .NET 版**、**.NET 9 SDK**，以及本地安装的《杀戮尖塔 2》。
Mod 引用游戏自带的 `sts2.dll` 和 `0Harmony.dll`，玩家使用 Mod 不需要安装开发工具。

1. 复制 `local.props.template` 为 `local.props`。
2. 填入自己的 `Sts2Dir` 和 `GodotExe` 路径。
3. 在项目目录执行 PowerShell 命令：

```powershell
./build.ps1
```

构建输出位于 `dist/ReactiveCompanionUI/`。脚本只生成文件，安装时将三件套复制到游戏 Mod 目录。
`local.props`、Godot 缓存和编译输出已由 `.gitignore` 排除。

在 Godot 中打开 `project.godot` 可运行开发预览；`preview/expression_picker.tscn`
用于组合、查看和保存表情选择。正式 PCK 采用显式资源清单，新增运行图片时应同步更新
`export_presets.cfg` 的 `export_files`。

```text
ReactiveCompanionUI_hcxmmx/  游戏集成、场景、脚本和角色图片
preview/                    开发预览、表情选择器和检查脚本
project.godot               Godot 项目入口
build.ps1                   本地构建与打包
ASSET_NOTICE.md             美术来源与权利说明
```

## 许可

项目作者贡献的代码、场景结构、配置和文档采用 [MIT 许可](LICENSE)。
智乃等第三方美术不适用 MIT，来源与权利归属见 [ASSET_NOTICE.md](ASSET_NOTICE.md)。
本项目以免费同人 Mod 的形式分享。

## 致谢

- 智乃与《请问您今天要来点兔子吗？》的原作者、游戏及美术制作人员。
- [Shiruba / The Spriters Resource](https://www.spriters-resource.com/playstation_vita/gochuumonwausagidesukawonderfulparty/asset/189021/)：素材提取、整理与来源记录。
- [Mega Crit](https://www.megacrit.com/)：制作《杀戮尖塔 2》并提供 Mod 加载支持。
- [GlitchedReme 的 SlayTheSpire2ModdingTutorials](https://github.com/GlitchedReme/SlayTheSpire2ModdingTutorials)：开发过程参考的 Mod 教程。
- [Godot Engine](https://godotengine.org/) 和 [Harmony](https://github.com/pardeike/Harmony)：界面与游戏集成所用工具。

游戏 DLL、反编译文件和完整原始素材集不包含在本仓库中。

## 反馈

欢迎通过 GitHub Issues 反馈。请提供游戏版本、Mod 版本、系统、复现步骤、其他启用的 Mod，
以及相关错误日志；发布日志前请检查是否包含个人路径等信息。
版本变更记录见 [CHANGELOG.md](CHANGELOG.md)。
