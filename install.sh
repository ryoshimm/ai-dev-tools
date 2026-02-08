#!/usr/bin/env bash

# ai-dev-tools インストーラー
#
# 以下を行います：
# 1. bin/ 配下のコマンド（ai-wt, setup-skills, setup-claudemd）に実行権限を付与
# 2. ~/bin/ にシンボリックリンクを作成
# 3. ~/bin を PATH に追加（未設定の場合のみ）
#
# 既存の環境を破壊する操作は行いません。

set -euo pipefail

echo "== ai-dev-tools installer =="

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "リポジトリ: $REPO_DIR"
echo ""

mkdir -p "$HOME/bin"

# リンク対象のコマンド一覧
COMMANDS=(ai-wt setup-skills setup-claudemd)

for cmd in "${COMMANDS[@]}"; do
  src="$REPO_DIR/bin/$cmd"
  dest="$HOME/bin/$cmd"

  if [[ ! -f "$src" ]]; then
    echo "Warning: $src が見つかりません（スキップ）"
    continue
  fi

  chmod +x "$src"
  ln -sf "$src" "$dest"
  echo "リンク: $dest → $src"
done

# シェル設定に PATH を追加
RC=""
if [[ "${SHELL:-}" == *zsh ]]; then
  RC="$HOME/.zshrc"
elif [[ "${SHELL:-}" == *bash ]]; then
  RC="$HOME/.bashrc"
fi

PATH_LINE='export PATH="$HOME/bin:$PATH"'
if [[ -n "$RC" ]]; then
  [[ -f "$RC" ]] || touch "$RC"

  if ! grep -Fq "$PATH_LINE" "$RC"; then
    printf '\n%s\n' "$PATH_LINE" >> "$RC"
    echo "PATH 追加: $RC"
  fi
else
  echo "Note: シェル設定ファイルを検出できませんでした（SHELL='${SHELL:-}'）"
  echo "手動で追加してください:"
  echo "  $PATH_LINE"
fi

echo ""
echo "Done."
echo ""
echo "Next:"
echo "  1) ターミナルを再起動（または: source \"${RC:-~/.zshrc}\"）"
echo "  2) setup-skills        — skills を ~/.claude/skills/ に展開"
echo "  3) cd <project> && setup-claudemd  — プロジェクトに CLAUDE.md を展開"
