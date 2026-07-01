# 直播间才艺热度规则与协作说明

## 当前方向

- 当前最新玩法基线来自 `jch` 分支，并已同步到 `chutianyi`。
- 项目入口是 `scenes/start_screen.tscn`。
- 主体验从早期“单手牌拖拽”升级为：公共牌池抢牌、篮子、棋盘放置、计时阶段、热度条、道具、万能牌、PVP 联机测试。
- 玩法包装仍是直播平台 PK：热度、主播身份、弹幕反馈、赛后复盘、榜单方向。

## 当前核心玩法

- 公共牌池固定 10 张牌，使用 2 列 x 5 行槽位。
- 回合开始时公共牌池补牌，并经历锁定/下落/解锁阶段。
- 抢牌阶段：玩家在限定时间内从公共牌池选择卡牌放入自己的篮子。
- 篮子容量当前为 4 张。
- 放置阶段：玩家把篮子里的牌拖到自己的棋盘。
- 棋盘行列数由 `UiLayoutConfig.BOARD_ROWS` 和 `UiLayoutConfig.BOARD_COLUMNS` 控制。
- 普通卡放到最上排或最左列时，数值 +1。
- 上下左右相邻、同类型且同数值的卡牌会作为连通组结算。
- 每次结算会让相关卡牌掉 1 层；数值到 0 的卡牌移除。
- 分数逻辑当前在 `PlayerBoardState._resolve_chains_from`：受影响卡牌、移除卡牌和多段连锁都会提供热度。
- 万能牌与相同数值的任意类型卡牌匹配；万能牌结算一次后消失。

## 数值与调参

核心调参文件：

- `scripts/config/game_balance_config.gd`
- `scripts/config/ui_layout_config.gd`

当前卡牌类型：

- 游戏
- 聊天
- 才艺
- 万能

当前数值概率由 `GameBalanceConfig.VALUE_PROBABILITY_BY_ROUND` 控制，按回合区间逐步提高高数值牌比例。

当前万能牌概率：

- `GameBalanceConfig.WILD_CARD_WEIGHT`

## 道具

当前单机/测试流里已有 3 个基础道具：

- `消`：移除一张目标卡牌。
- `+1`：目标卡牌数值 +1，并尝试触发结算。
- `-1`：目标卡牌数值 -1，并尝试触发结算；到 0 则移除。

道具规则在：

- `scripts/core/player_board_state.gd`

道具 UI 在：

- `scripts/ui/local_prop_view.gd`

## 场景分工

- `scenes/start_screen.tscn`：项目入口。
- `scenes/local_match.tscn`：本地双人主界面静态/布局原型。
- `scenes/card_flow_test.tscn`：抢牌、篮子、放置、结算的单机可玩测试。
- `scenes/pvp_network_test.tscn`：LAN 创建/加入房间与同步消息测试入口。
- `scenes/pvp_match_test.tscn`：Host/Client PVP 对战测试。
- `scenes/pvp_lan_network.tscn`：PC/Android 双端联机测试入口。

## 代码分工

- `scripts/core/player_board_state.gd`：棋盘状态、放置、结算、道具。
- `scripts/core/pvp_card_data.gd`：PVP 卡牌数据结构。
- `scripts/config/game_balance_config.gd`：卡牌刷新与数值概率。
- `scripts/config/ui_layout_config.gd`：布局、颜色和尺寸常量。
- `scripts/ui/card_flow_test_ui.gd`：单机抢牌/放置测试主逻辑。
- `scripts/ui/pvp_match_test_ui.gd`：PVP 对战测试主逻辑。
- `scripts/ui/pvp_network_test_ui.gd`：LAN 连接测试 UI。
- `scripts/ui/start_screen.gd`：入口导航。

## 后续建议

- 新功能优先接到 `jch` 的新结构，不要复活旧的 `scripts/puzzle/game_state.gd` / `scripts/ui/main.gd`。
- 网络 PVP 中最终操作必须由 Host 校验；拖拽过程可以走轻量视觉同步。
- 道具接入网络前，先保证本地测试场景规则稳定。
- 视觉资产放入 `assets/` 对应目录，避免硬编码绝对路径。
