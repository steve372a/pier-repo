# Pier Repo 包详情页规格

## 目标
1. `index.html` 默认显示全部包。
2. 点击包后进入详情视图。
3. 详情页优先展示可读信息，不直接暴露原始 `metadata.sque` 全文作为主界面。
4. 页面整体改为简洁白底风格。

## 数据来源
1. `metadata.sque`
   - `PackageName`
   - `InstallerName`
   - `Version`
   - `OS`
   - `Alias`
   - `Author`
   - `Distributor`
   - `PackageSize`
   - `Notice`
   - `DefaultOpen`
2. `profile.sque`
   - 各语言 `ProFile`
   - 有时还会有本地化 `PackageName`
3. `notice.sque`
   - 各语言 Notice

## 页面结构
1. 左侧
   - 搜索框
   - 包列表
   - 每项显示：
     - PackageName
     - InstallerName
     - Version
     - 一行简介
2. 右侧详情
   - 大标题：`PackageName`
   - 小标题：简介 `ProFile`
   - 基础行：`InstallerName`、`Version`
   - 信息区：
     - Alias 别名
     - OS
     - Author
     - Distributor
     - PackageSize
     - Notice
     - DefaultOpen

## 展示规则
1. 不显示 `InstallDir`
2. 不把 `metadataPath` 放到主详情区
3. Alias 尽量格式化展示：
   - 每个 alias 单独一行
   - 左侧是别名名
   - 右侧是命令
   - `$1`、`$2` 作为占位符保留原样，但样式上弱强调
4. `DefaultOpen` 也按多行列表展示
5. `Notice` 优先显示当前语言匹配版本；没有时回退到 `metadata.sque` 中的 `Notice`
6. 简介 `ProFile` 优先显示当前语言匹配版本；没有时回退到 `metadata.sque` 中的 `ProFile`

## 语言策略
1. 页面默认中文
2. 切英文时：
   - UI 文案切英文
   - 简介优先取 `profile.sque` 中的 `en-US`
   - Notice 优先取 `notice.sque` 中的 `en-US`
3. 中文时优先取 `zh-CN`
4. 没有对应语言时回退：
   - `zh-CN`
   - `en-US`
   - `metadata.sque` 中原始字段

## 构建策略
1. GitHub Action 继续单次扫描 `latest.metadata`
2. 除了解 `metadata.sque`，还要解 `profile.sque` 与 `notice.sque`
3. 生成 `packages.json` 时，写入前端需要的结构化字段
4. `db.sque` / `dbm.sque` 继续保持兼容
