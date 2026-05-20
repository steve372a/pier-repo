# Pier Repo 页面改造任务

1. 扩展 `.github/workflows/update.yml`
   - 读取 `metadata.sque`
   - 读取 `profile.sque`
   - 读取 `notice.sque`
   - 解析多语言段落
   - 写入 `packages.json`

2. 设计 `packages.json` 新结构
   - 基础字段
   - `profiles`
   - `notices`
   - `aliases`
   - `defaultOpen`
   - 原始字段回退

3. 重构 `index.html`
   - 调整成白底简洁布局
   - 修正中英文标题切换
   - 包列表展示优化
   - 详情页结构改成用户要求的字段顺序

4. 详情渲染
   - 语言优先级回退
   - Alias 格式化
   - DefaultOpen 列表化
   - Notice 文本块展示

5. 验证
   - 本地生成 `packages.json`
   - 检查 7zip / czadb 的简介与 Notice 是否正确
   - 检查空 Alias 的显示
   - 检查语言切换
