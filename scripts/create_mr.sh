#!/bin/bash
set -e

SOURCE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
TARGET_BRANCH="${SOURCE_BRANCH#fix-}-mr" # Simplistic assumption based on start_feature.sh
TITLE=$1

if [ -z "$TITLE" ]; then
    echo "Usage: $0 \"<MR Title>\""
    exit 1
fi

if [ -z "$GITLAB_PERSONAL_ACCESS_TOKEN" ]; then
    echo "❌ Error: GITLAB_PERSONAL_ACCESS_TOKEN env var is not set."
    exit 1
fi

PROJECT_URL=$(git remote get-url origin | sed 's/\.git$//')
# Heuristic to get simple project ID or URL safe encoding could be tricky in bash
# So we use the GitLab API project search or assume glab/curl context.
# Since SKILL.md mandates GitLab MCP, this script is a helper for the *Agent* to call or
# for the underlying system.
# Actually, for the "Skill" to be consistent, it should probably call the MCP tool if valid?
# But the user asked for SCRIPTS to ensure determinism.
# Let's use `curl` directly to the API, assuming standard GitLab.com or env config.
# Retrieving Project ID can be tricky without `glab`.
# We'll try to find project ID from `git remote` and API.

echo "🔍 Detecting Project info..."
# Extract path from git remote (supports ssh and https)
REPO_PATH=$(git remote get-url origin | sed -E 's/.*[:\/](.*)\/(.*)\.git/\1\/\2/')
ENCODED_PATH=${REPO_PATH/\//%2F}

echo "📂 Repo Path: $REPO_PATH (Encoded: $ENCODED_PATH)"

# Check if target branch exists
echo "🔄 Pushing source branch $SOURCE_BRANCH..."
git push -u origin "$SOURCE_BRANCH"

echo "🚀 Creating MR: $TITLE ($SOURCE_BRANCH -> $TARGET_BRANCH)"

# Construct Description (Template)
DESCRIPTION="## 根因分析
- 现象：
- 根因：

## 修复方案
- 设计要点：
- **遵循规范**：(See QMD Context)

## 改动说明
- 模块：

## 测试结果
- 命令：
"

# URL Encode Title and Description?
# Use python for safer encoding if available, or simple curl data-urlencode
RESPONSE=$(curl --silent --request POST --header "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN" \
    --data-urlencode "source_branch=$SOURCE_BRANCH" \
    --data-urlencode "target_branch=$TARGET_BRANCH" \
    --data-urlencode "title=$TITLE" \
    --data-urlencode "description=$DESCRIPTION" \
    "https://gitlab.com/api/v4/projects/$ENCODED_PATH/merge_requests")

echo "✅ MR Created Response:"
echo "$RESPONSE" | head -c 200 # Truncate for log
echo "..."
