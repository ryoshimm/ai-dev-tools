#!/usr/bin/env bash

# README:
#
# 1. `bin/ai-wt` を用意する
#    - `bin/ai-wt` が存在しない場合、最小のスタブを作成する
#    - `bin/ai-wt` に実行権限を付与する（`chmod +x`）
# 2. `ai-wt` をグローバルに実行可能にする
#    - `~/bin/ai-wt` にシンボリックリンクを作成する
#    - 既存のリンクがあっても上書きする（`ln -sf`）
# 3. `~/bin` を PATH に追加する
#    - 使用中のシェル（zsh / bash）を判別する
#    - `~/.zshrc` または `~/.bashrc` に
#      `export PATH="$HOME/bin:$PATH"` を追記する
#    - すでに記述がある場合は何もしない
# 4. 既存の環境を破壊する操作は行わない
#    - ファイルの削除は行わない
#    - clone / checkout は行わない
#    - システム設定の変更は行わない

set -euo pipefail

echo "== ai-dev-tools installer =="

# detect repo root (install.sh の場所)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Using repo at: $REPO_DIR"

# Ensure directories
mkdir -p "$REPO_DIR/bin"
mkdir -p "$HOME/bin"

# Bootstrap ai-wt if missing (最小スタブ)
if [[ ! -f "$REPO_DIR/bin/ai-wt" ]]; then
  cat > "$REPO_DIR/bin/ai-wt" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "ai-wt is installed (bootstrap stub)."
echo "Implement bin/ai-wt to add: create/remove/list"
echo "Example: ai-wt --help"
EOF
  echo "Bootstrapped: $REPO_DIR/bin/ai-wt"
fi

# Ensure executable
chmod +x "$REPO_DIR/bin/ai-wt"

# Symlink CLI tools to ~/bin
ln -sf "$REPO_DIR/bin/ai-wt" "$HOME/bin/ai-wt"

# Detect shell rc (zsh/bash)
RC=""
if [[ "${SHELL:-}" == *zsh ]]; then
  RC="$HOME/.zshrc"
elif [[ "${SHELL:-}" == *bash ]]; then
  RC="$HOME/.bashrc"
fi

# Add PATH if missing (idempotent)
PATH_LINE='export PATH="$HOME/bin:$PATH"'
if [[ -n "$RC" ]]; then
  # Create rc file if it doesn't exist
  [[ -f "$RC" ]] || touch "$RC"

  if ! grep -Fq "$PATH_LINE" "$RC"; then
    printf '\n%s\n' "$PATH_LINE" >> "$RC"
    echo "Added PATH to $RC"
  fi
else
  echo "Note: Could not detect zsh/bash rc file from SHELL='${SHELL:-}'."
  echo "If needed, add this to your shell rc manually:"
  echo "  $PATH_LINE"
fi

echo "Done."
echo "Next:"
echo "  1) Restart your terminal (or: source \"$RC\" if applicable)"
echo "  2) Run: ai-wt --help"
