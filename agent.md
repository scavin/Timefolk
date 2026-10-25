# Timefolk 项目交接说明

更新日期：2026-10-23。本文记录项目现状、维护约定和已知限制；后续修改后应同步更新。

## 项目定位与来源

Timefolk 是原生 macOS 菜单栏世界时钟，用来查看朋友、同事和城市的当地时间，支持城市搜索、UTC 偏移量、头像、排序和时间滑块预览。

- 当前仓库：https://github.com/scavin/Timefolk，公开仓库，默认分支 `main`。
- 原项目：https://github.com/dena-sohrabi/There，原作者 Dena Sohrabi。
- `origin` 指向 `scavin/Timefolk`，`upstream` 指向 `dena-sohrabi/There`。
- 保留了原项目的提交历史和 MIT 许可；README 已注明项目来源并感谢原作者。后续重命名或发布时继续保留这些署名与许可。
- 首次维护提交：`c69837a`，包含维护修复、Tibo 预设和 README 致谢。

## 命名与版本现状

仓库和 README 已使用 **Timefolk**，应用内部尚未完成更名：

| 项目 | 当前值 |
| --- | --- |
| Xcode 工程 | `There.xcodeproj` |
| 主应用源码 | `There/` |
| App 入口 | `There/ThereApp.swift` 中的 `ThereApp` |
| 应用产物、可执行文件 | `Timefolk.app`、`Timefolk` |
| Bundle Identifier | `com.timefolk.Timefolk`（通过 `LegacyDataMigrator` 与 `ContainerMigration.plist` 兼容迁移 `pm.there.There` 旧数据） |
| 应用版本 / Build | `2.4` / `6` |
| 默认构建与单元测试 Scheme | `There` |
| 独立 UI 测试 Scheme | `There-UI` |
| 应用最低系统版本 | macOS 13.5 |
| 测试目标最低系统版本 | macOS 14 |

不能只做全局字符串替换来完成品牌迁移。Bundle Identifier、沙盒容器、头像绝对路径、启动项、测试模块名和构建脚本都需要一起检查，尤其要保留旧用户数据的迁移路径。

## 技术结构

- **SwiftUI + AppKit**：`MenuBarExtra` 使用窗口式面板。工程目前仍采用 Swift 5 语言模式；依赖解析需要 Swift 6.1 或更新工具链。
- **GRDB / SQLite**：保存时区条目，通过数据库观察更新列表。
- **MapKit / CoreLocation**：搜索城市，必要时解析城市时区；已知时区标识符可以直接解析。
- **SMAppService**：管理新的登录启动项。
- **PostHog**：继承的分析集成仍然存在；测试模式不会初始化分析 SDK。

主要代码入口：

| 路径 | 职责 |
| --- | --- |
| `There/ThereApp.swift` | App、菜单栏与引导窗口、数据库环境注入、分析 SDK 初始化 |
| `There/ContentView.swift`、`There/Data/Router.swift` | 主列表、添加、编辑三个页面的路由 |
| `There/Views/MainView.swift` | 时区列表、分钟级刷新、排序、删除和时间滑块 |
| `There/Views/EntryUI/` | 条目时间、时差、头像和时段图标 |
| `There/Views/Timezone/` | 添加与编辑表单、城市搜索选择、头像导入 |
| `There/Data/Entry.swift` | 条目模型、指定日期的时差与时段计算 |
| `There/Data/SearchCompleter.swift` | 城市与时区搜索、固定 UTC 偏移量解析、Tibo 预设 |
| `There/Data/Database.swift`、`Persistence.swift` | 数据库 schema、迁移、连接和存储位置 |
| `There/Data/PhotoStorage.swift` | 头像文件保存与清理、数据库保存入口 |
| `There/Data/LaunchAgent.swift` | 当前实现为 `LoginItem`，使用 SMAppService，不再创建旧式 LaunchAgent |
| `There/Views/Onboarding/` | 继承的可选邮箱注册和跳过流程 |
| `ThereTests/` | Swift Testing 单元测试与维护回归测试 |
| `ThereUITests/` | XCTest UI 测试，包含 Tibo 添加与编辑流程 |

## Tibo 时区的产品约定

Tibo 常驻西雅图（Seattle）。在 v2.3 及之后，Tibo 预设与出厂默认好友统一采用遵循标准夏令时规则的 IANA 时区 **`America/Los_Angeles`**（西雅图归属时区），由系统底层 `tzdata` 时区数据库负责冬夏令时动态切换。

- 预设使用 `TimeZoneSearchResult.tibo`，时区标识符为 `America/Los_Angeles`，城市标为 `Seattle`。
- 冬季为 PST（UTC−08:00），夏季自动平滑过渡为夏令时 PDT（UTC−07:00），杜绝夏令时偏差 1 小时的问题。
- 搜索 `Tibo`、`Seattle`、`西雅图`、`Codex`、`reset`、`PST`、`PDT` 均可快速找到它。
- 保持对历史版本 `Etc/GMT+8` 数据的向下兼容与专属头像匹配。

## 本轮已完成的维护

1. 将原作者 `Downloads` 目录中的三个本地依赖改成官方远程包，固定版本并纳入锁文件；移除未使用的 Sparkle 引用。
2. 修复新版菜单栏组件的 modifier 调用顺序；清理不相关的 iOS / visionOS 构建设置和原作者签名 Team。
3. 保存前验证时区；保存失败会保留表单并显示错误，删除失败也会显示错误。
4. 修复编辑时写入无效头像路径的问题；无头像保持 `nil`。新头像先原子写入，数据库成功后再清理旧头像，数据库失败则清理新文件。
5. 扩大随机条目 ID 的取值范围，降低覆盖旧条目的碰撞风险。
6. 保持原数据库 schema 和位置；移除 Debug 模式下因迁移定义变化而自动清空数据库的设置。
7. 已知城市时区无需再次地理编码；丢弃过期搜索回调，支持 `UTC+05:45` 等分钟偏移，并修复搜索框暗色适配。
8. 列表共享一个与整分钟对齐的刷新计划；按完整偏移量排序，记住排序方向，使用预览日期计算夏令时差异。
9. 新登录启动项只使用 SMAppService，展示失败与需系统批准的状态；不再创建硬编码路径且 KeepAlive 的 LaunchAgent。
10. 校验头像下载响应，丢弃取消后的请求；补充回归测试、共享 Scheme 和 macOS CI。

详细变更见 `CHANGELOG.md`。

## 依赖管理

| 依赖 | 固定版本 |
| --- | --- |
| GRDB.swift | 7.11.1 |
| MenuBarExtraAccess | 1.3.1 |
| PostHog | 3.92.2 |

包声明在 `There.xcodeproj/project.pbxproj`；锁文件为 `There.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`。升级依赖时一起核对声明、锁文件、最低工具链和构建结果，不要恢复机器专属的本地依赖路径。

## 数据与兼容性约束

- 数据库为当前应用 Application Support 下的 `Database/db.sqlite`；开启沙盒时，实际根目录由系统容器决定，不要硬编码为普通用户目录。
- 新头像存于同一 Application Support 下的 `Photos/`，数据库中保存文件 URL；兼容旧版直接存于 Application Support 根目录的 UUID PNG。
- 统一通过 `AppDatabase.saveEntry(_:image:photos:)` 保存表单，避免绕过头像与数据库的失败清理逻辑。
- schema 变更应新增迁移，不能改写已发布的迁移来强制重建数据库。
- 代码仍保留显式 `-reset` 启动参数，它会删除数据库目录。不要在真实用户数据实例上用它做诊断或普通测试。
- 标准单元测试和 `-ui-testing` 使用内存数据库；头像回归测试使用临时目录。
- 旧版本若创建了 `~/Library/LaunchAgents/pm.there.There.LaunchAgent.plist`，需先卸载和移除旧项再启用新登录启动；不要未经检查批量改动用户的 LaunchAgents。

## 构建、测试与产物

在仓库根目录执行：

```sh
# Debug
xcodebuild -project There.xcodeproj -scheme There \
  -destination 'platform=macOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build

# Release
xcodebuild -project There.xcodeproj -scheme There -configuration Release \
  -destination 'platform=macOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build

# 默认 Scheme 只运行单元测试
xcodebuild -project There.xcodeproj -scheme There \
  -destination 'platform=macOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO test
```

上述 Release 命令的产物为 `build/Build/Products/Release/Timefolk.app`。本次会话实际使用的临时构建产物为：

```text
/private/tmp/there-maintenance-build/Build/Products/Release/There.app
```

临时目录可能被系统清理，不应作为长期分发位置。当前没有生成可分发的签名、公证或安装包；正式安装、发布及登录启动验证需要配置自己的签名与适用的权限。不要把关闭签名的本地构建视为已完成分发验证。

UI 测试使用独立的 `There-UI` Scheme，在有相应自动化权限的桌面环境运行；与 CI 的单元测试验收分开记录。

## 已验证结果与限制

2026-10-23 本地环境：Apple Silicon、macOS 27.0.1、Xcode 27.1。

- Debug 和 Release 构建成功，已完整编译集成 2026 Apple 极简相切时区光环与信标 AppIcon（16x16 至 1024x1024 全尺寸）及菜单栏状态栏 Template 图标。
- 默认 Scheme 的 **13 项单元测试通过**，包含 Tibo 专用头像资源验证、固定 PST 冬夏行为、分钟偏移、旧数据库兼容、编辑无头像、失败写入回滚及旧头像清理。
- 证据日志：`/private/tmp/there-maintenance-unit-final.log`、`/private/tmp/there-maintenance-release.log`。这些日志也是临时文件，重新验收时应生成新的结果。
- UI 冒烟测试尚未通过：当前多显示器环境中出现了菜单控件离屏、不可命中和点击失败。不能只凭单元测试通过宣称添加与编辑已完成端到端验收，也不能断言所有 UI 失败仅由环境引起。
- 未完成 macOS 13.5 等旧系统、Intel Mac、正式签名安装和登录启动的运行时验证。
- `.github/workflows/macos.yml` 已配置 push / pull_request 时在 `macos-15` 构建并运行单元测试；GitHub 上的最新执行状态需实时核对，不能把本地成功当成远端 CI 成功。

## 接手维护时的后续重点

1. 完成 Timefolk 应用层品牌迁移，包括显示名、工程、模块、图标、帮助与支持入口；单独设计 Bundle Identifier 和旧数据的兼容方案。
2. 在适合的桌面环境完成真实菜单栏点击、添加、编辑、删除、头像与时间滑块验收，排除剩余 UI 问题。
3. 检查继承的外部服务：PostHog、可选邮箱注册、头像服务以及 There 原网站和支持链接。它们尚未迁移成 Timefolk 自己的服务；不要假设它们仍可用或已由当前维护者控制。
4. 完成签名、公证、安装与登录启动验证，再决定发布渠道。Homebrew 的 `there` cask 当前仍指向旧项目。
5. 保持 README、CHANGELOG、测试和实际实现一致；保留原作者致谢，明确区分已实现、已编译、已实测和待验证事项。
