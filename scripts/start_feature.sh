#!/bin/bash
set -e

FEATURE_NAME=$1

if [ -z "$FEATURE_NAME" ]; then
  echo "Usage: $0 <feature_name>"
  exit 1
fi

echo "🚀 Starting feature: $FEATURE_NAME"

# 1. Update Master
echo "🔄 Updating master..."
git checkout master || git checkout main
git pull

# 2. Create Target Branch (MR Target, Empty)
TARGET_BRANCH="${FEATURE_NAME}-mr"
if git rev-parse --verify "$TARGET_BRANCH" >/dev/null 2>&1; then
    echo "⚠️  Branch $TARGET_BRANCH already exists, skipping creation."
else
    echo "🌱 Creating target branch: $TARGET_BRANCH"
    git checkout -b "$TARGET_BRANCH"
    git push -u origin "$TARGET_BRANCH"
fi

# 3. Create Source Branch (Work Branch)
SOURCE_BRANCH="fix-${FEATURE_NAME}"
# Or feat-, logic could be refined but sticking to fix/feat covention
# Let's standardize on just using the provided name prefixed or exactly as is?
# To match the SKILL.md logic: "fix-{feature}"
SOURCE_BRANCH="fix-${FEATURE_NAME}"

echo "🔨 Creating source branch: $SOURCE_BRANCH"
# Reset to target branch base just in case
git checkout "$TARGET_BRANCH"
git checkout -b "$SOURCE_BRANCH"

echo "✅ Ready to work on $SOURCE_BRANCH. Target MR branch is $TARGET_BRANCH."
