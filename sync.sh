#!/bin/bash
find . -name ".DS_Store" -depth -exec rm {} \;

# --- 配置区域 ---
# 如果你之前没有配置过全局账号，可以取消下面两行的注释
# git config user.name "steve372a"
# git config user.email "你的邮箱"

echo "🚀 开始同步 Pier 仓库..."

# 1. 拉取远程更新（防止冲突，特别是别人提了 PR 的时候）
echo "📥 正在从 GitHub 拉取最新内容..."
git pull origin main --rebase

# 2. 添加所有更改
echo "📝 正在记录变更..."
git add .

# 3. 自动生成提交信息（带时间戳） [cite: 2026-01-29]
# 按照你要求的北京时间格式
current_time=$(date +"%Y-%m-%d %H:%M:%S")
commit_msg="Update packages at $current_time (UTC+8)"

# 4. 执行提交
git commit -m "$commit_msg"

# 5. 推送到 GitHub
echo "📤 正在上传到 GitHub..."
git push origin main --force

echo "✅ 同步完成！机器人正在云端生成索引..."
