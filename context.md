# Context

## 仓库定位

这个仓库不是常规应用代码仓，而是 `Pier Package Installer` 的软件源仓库。

主要目录：

- `sources/`：按首字母分桶存放包元数据，核心文件是 `latest.metadata`
- `alias/`：别名映射
- `list/`：旧列表机制，`list/listpackageonline.pie` 已废弃并删除
- `old/`：旧文件

## 当前数据链路

`latest.metadata` 是 zip 压缩文件，不是纯文本。

包内可能包含：

- `metadata.sque`
- `profile.sque`
- `notice.sque`

当前约定：

- `db.sque`、`dbm.sque` 继续保留，供 Pier 客户端兼容使用
- `packages.json` 是网页前端专用数据源
- 不引入后端
- 所有解压、编码处理、结构化提取都由 GitHub Action 完成

## GitHub Action

文件：

- `.github/workflows/update.yml`

当前目标：

同一轮扫描 `sources/*/*/latest.metadata`，同时生成：

- `db.sque`
- `dbm.sque`
- `packages.json`

不要拆成多个 workflow。原因：

- 同一个输入源，拆开会重复扫描和解压
- 会增加 push/commit 并发冲突风险
- 当前更优方案是单 workflow、单次扫描、多产物输出

## packages.json 约定

`packages.json` 当前用于 `index.html`。

每个包目前包含的关键字段：

- `id`：InstallerName
- `name`：PackageName
- `version`
- `os`
- `profile`：metadata.sque 默认简介
- `author`
- `distributor`
- `packageSize`
- `defaultOpen`
- `aliases`
- `notice`
- `localizedNames`
- `profiles`
- `notices`
- `metadataFields`
- `metadataText`
- `profileText`
- `noticeText`

语言回退规则：

1. 当前页面语言对应值
2. `zh-CN`
3. `en-US`
4. `metadata.sque` 原始字段

## 页面约定

文件：

- `index.html`

当前页面目标：

- 默认显示所有包
- 支持搜索
- 点击包后显示详情
- 页面是纯静态页面
- 主数据源是 `packages.json`

当前页面结构：

- 左侧：包列表
- 右侧：包详情

详情页展示顺序：

1. 大标题：`PackageName`
2. 小标题：简介 `ProFile`
3. 基础字段：`InstallerName`、`Version`
4. `Alias`
5. `OS`
6. `Author`
7. `Distributor`
8. `PackageSize`
9. `Notice`
10. `DefaultOpen`

明确不显示：

- `InstallDir`
- `metadataPath`

## 样式与图片

当前页面风格：

- 白底
- 简洁布局
- 不做复杂深色代码风格主界面

`assets/` 中图片的当前用途：

- `assets/package.png`：用于“软件包列表 / Package List”标题左侧
- `assets/info.png`：用于“包详情 / Package Details”标题左侧

这两张图只作为 section icon，不作为大主视觉。

## 文本标记规则

包文本中可能出现类似：

- `$brightyellow$`
- `$white$`

当前约定：

- 不直接显示这些标记文本
- 页面展示层负责解析/隐藏它们
- 列表简介中直接去掉这些标记
- 详情中的简介、Notice、Alias 命令中允许做轻量格式化

## 已确认的产品决策

1. `index.html` 可以改
2. `packages.json` 可以新增
3. `.github/workflows/update.yml` 可以改
4. `db.sque` / `dbm.sque` 暂时不要废弃
5. 不要拆多个 workflow
6. `list/listpackageonline.pie` 不再可信，已删除
7. `sync.sh` 去掉了 `git push --force`，保留删除 `.DS_Store`

## 文档文件

当前已经新增：

- `spec.md`
- `checklist.md`
- `tasks.md`
- `context.md`

## 当前工作区中的重要改动

当前这一轮涉及的核心文件：

- `.github/workflows/update.yml`
- `index.html`
- `packages.json`
- `sync.sh`
- `assets/info.png`
- `assets/package.png`
- `spec.md`
- `checklist.md`
- `tasks.md`
- `context.md`

## 后续继续改时的注意点

1. Pier 客户端依赖 `db.sque` 和 `dbm.sque`，不要随意改废
2. 页面逻辑优先建立在 `packages.json` 上
3. 如果继续调 UI，优先保持简洁白底和信息可读性
4. 如果继续扩展字段，先看 `metadata.sque`、`profile.sque`、`notice.sque` 里是否已有现成信息
