#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_LINE="source \"${SCRIPT_DIR}/bin/wt.sh\""
ZSHRC="${HOME}/.zshrc"

# 既に追加済みか確認
if grep -qF "bin/wt.sh" "$ZSHRC" 2>/dev/null; then
  echo "Already installed in ${ZSHRC}"
  exit 0
fi

echo "" >> "$ZSHRC"
echo "# wt: git worktree helper" >> "$ZSHRC"
echo "$SOURCE_LINE" >> "$ZSHRC"

echo "Added to ${ZSHRC}:"
echo "  ${SOURCE_LINE}"
echo ""
echo "Run 'source ~/.zshrc' or restart your terminal to activate."
