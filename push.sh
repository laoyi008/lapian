#!/bin/bash

# GitHub 推送脚本
# 使用方法：./push.sh [your-github-token]

echo "=========================================="
echo "  GitHub 推送脚本"
echo "=========================================="
echo ""

# 检查是否提供了 token
if [ -z "$1" ]; then
    echo "❌ 错误：未提供 GitHub Token"
    echo ""
    echo "使用方法："
    echo "  ./push.sh YOUR_GITHUB_TOKEN"
    echo ""
    echo "如何获取 GitHub Token："
    echo "  1. 访问 https://github.com/settings/tokens"
    echo "  2. 点击 'Generate new token (classic)'"
    echo "  3. 选择 'repo' 权限"
    echo "  4. 生成并复制 token"
    echo ""
    exit 1
fi

TOKEN="$1"
REPO_URL="https://github.com/laoyi008/laoyi-prompt.git"

echo "📋 仓库信息："
echo "  URL: $REPO_URL"
echo "  分支: master"
echo ""

# 检查 git 状态
echo "🔍 检查 Git 状态..."
git status --short
echo ""

# 检查远程仓库
echo "🔗 检查远程仓库..."
if git remote | grep -q "^origin$"; then
    echo "  ✅ 远程仓库已配置"
    CURRENT_URL=$(git remote get-url origin)
    echo "  当前 URL: $CURRENT_URL"
    
    # 更新远程仓库 URL（包含 token）
    echo "  🔄 更新远程仓库 URL..."
    git remote set-url origin "https://${TOKEN}@github.com/laoyi008/laoyi-prompt.git"
else
    echo "  ➕ 添加远程仓库..."
    git remote add origin "https://${TOKEN}@github.com/laoyi008/laoyi-prompt.git"
fi
echo ""

# 推送代码
echo "🚀 开始推送代码..."
echo ""

if git push -u origin master; then
    echo ""
    echo "=========================================="
    echo "  ✅ 推送成功！"
    echo "=========================================="
    echo ""
    echo "📦 查看仓库："
    echo "  https://github.com/laoyi008/laoyi-prompt"
    echo ""
    
    # 清理 URL 中的 token（安全考虑）
    echo "🔒 清理敏感信息..."
    git remote set-url origin "$REPO_URL"
    echo "  ✅ 已移除 URL 中的 token"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "  ❌ 推送失败"
    echo "=========================================="
    echo ""
    echo "可能的原因："
    echo "  1. Token 无效或已过期"
    echo "  2. Token 权限不足（需要 repo 权限）"
    echo "  3. 网络连接问题"
    echo "  4. 仓库不存在或无访问权限"
    echo ""
    echo "解决方案："
    echo "  1. 检查 Token 是否正确"
    echo "  2. 确认 Token 有 'repo' 权限"
    echo "  3. 检查网络连接"
    echo "  4. 确认仓库已创建"
    echo ""
    
    # 清理 URL 中的 token
    git remote set-url origin "$REPO_URL"
    
    exit 1
fi

echo "🎉 完成！"
