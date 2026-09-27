#!/usr/bin/env bash
# 一键上传 / 更新 GitHub（保留提交历史，可重复运行）
#
# 用法：
#   1. 首次运行：先在 GitHub 网页新建一个空仓库（不要勾选 README），
#      复制仓库地址，运行本脚本并粘贴地址。
#   2. 之后每次更新：直接再次运行本脚本即可，会增量提交并推送，保留历史。
set -euo pipefail
cd "$(dirname "$0")"

if [ -e .git ]; then
  # ── 已有仓库：增量更新，保留历史 ──
  echo "检测到已有 Git 仓库，执行增量更新（保留提交历史）..."
  git add -A
  if git diff --cached --quiet; then
    echo "没有新的更改，跳过提交。"
  else
    git commit -m "update: $(date '+%Y-%m-%d %H:%M')"
  fi
  git push
  echo ""
  echo "✅ 更新完成（已保留历史提交）"
else
  # ── 新仓库：初始化并首次推送 ──
  echo "首次上传。请先在 GitHub 网页新建一个空仓库（不要勾选 README）。"
  echo "然后粘贴仓库地址，例如：https://github.com/你的用户名/transcript-exporter.git"
  read -r REPO
  if [ -z "$REPO" ]; then
    echo "仓库地址不能为空。" >&2
    exit 1
  fi

  git init
  git add -A
  git commit -m "transcript-exporter：抖音数据采集 Skill 个人优化版"
  git branch -M main
  git remote add origin "$REPO"
  git push -u origin main
  echo ""
  echo "✅ 上传完成：$REPO"
fi
