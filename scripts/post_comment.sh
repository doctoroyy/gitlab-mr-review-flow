#!/bin/bash
set -e

FILE_PATH=$1
LINE_NUMBER=$2
COMMENT=$3

if [ -z "$COMMENT" ]; then
    echo "Usage: $0 <file_path> <line_number> \"<comment>\""
    exit 1
fi

if [ -z "$GITLAB_PERSONAL_ACCESS_TOKEN" ]; then
    echo "Error: GITLAB_PERSONAL_ACCESS_TOKEN not set."
    exit 1
fi

REPO_PATH=$(git remote get-url origin | sed -E 's/.*[:\/](.*)\/(.*)\.git/\1\/\2/')
ENCODED_PATH=${REPO_PATH/\//%2F}

# Get open MR for current branch
SOURCE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
MR_INFO=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN" \
    "https://gitlab.com/api/v4/projects/$ENCODED_PATH/merge_requests?source_branch=$SOURCE_BRANCH&state=opened")

MR_IID=$(echo "$MR_INFO" | grep -o '"iid":[0-9]*' | head -1 | cut -d':' -f2)
BASE_SHA=$(echo "$MR_INFO" | grep -o '"base_sha":"[^"]*"' | head -1 | cut -d'"' -f4)
HEAD_SHA=$(echo "$MR_INFO" | grep -o '"head_sha":"[^"]*"' | head -1 | cut -d'"' -f4)
START_SHA=$(echo "$MR_INFO" | grep -o '"start_sha":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$MR_IID" ]; then
    echo "❌ No open MR found for branch $SOURCE_BRANCH"
    exit 1
fi

echo "📝 Posting comment on MR #$MR_IID ($FILE_PATH:$LINE_NUMBER)..."

# Construct JSON payload
# Note: This is fragile bash string building. In real production, use `jq` or python.
# We assume standard inputs.
PAYLOAD=$(cat <<EOF
{
  "body": "$COMMENT",
  "position": {
    "base_sha": "$BASE_SHA",
    "start_sha": "$START_SHA",
    "head_sha": "$HEAD_SHA",
    "position_type": "text",
    "new_path": "$FILE_PATH",
    "new_line": $LINE_NUMBER
  }
}
EOF
)

curl --silent --request POST --header "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN" \
     --header "Content-Type: application/json" \
     --data "$PAYLOAD" \
     "https://gitlab.com/api/v4/projects/$ENCODED_PATH/merge_requests/$MR_IID/discussions"

echo "✅ Comment posted."
