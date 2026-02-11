# ai-dev-tools

Claude を用いた AI エージェンティック並列開発のためのスキル集。

[Vercel Skills](https://github.com/vercel-labs/skills) エコシステムに対応しています。

## セットアップ

### 1. Skills CLI の準備

[Vercel Skills](https://github.com/vercel-labs/skills) を使用します。Node.js がインストールされていれば追加のセットアップは不要です。

### 2. Skills のインストール

```bash
# Vercel 公式スキル（React/Next.js ベストプラクティス、コード監査など）
npx skills add vercel-labs/agent-skills -g

# ai-dev-tools スキル（plan 駆動開発・レビュー）
npx skills add ryoshimm/ai-dev-tools -g
```

`-g` を省略するとプロジェクト単位（`.claude/skills/`）にインストールされます。

インストールされたスキルは Claude が自動認識するため、CLAUDE.md への追記は不要です。

### 3. プロジェクトへの CLAUDE.md 配置（推奨）

プロジェクトごとに `.claude/CLAUDE.md` を配置すると、AI がプロジェクト固有のルールに従います。
テンプレートは [docs/templates/](docs/templates/) を参照してください。

## Skills 一覧

### Action スキル（明示呼び出し）

| スキル | 用途 | 呼び出し |
|--------|------|---------|
| **plan-master** | 実装計画書の作成 | `/plan-master` |
| **plan-fix** | 承認済み plan の修正 | `/plan-fix` |
| **ai-review** | 実装のレビュー・報告 | `/ai-review` |

### Rule スキル（自動適用）

| スキル | 用途 |
|--------|------|
| **base-rules** | プロジェクト調査・コード品質・安全性の共通ルール |

### plan-master

`.claude/plans/<feature>/plan.md` に実装計画書を作成します。
コードの実装は行いません。

- 1 ファイル（plan.md）に全情報を集約
- 変更規模（Small / Medium / Large）に応じて必要なセクションを自動判断
- plan は「契約書」として扱い、実装時の唯一の正となる

### plan-fix

承認済みの plan.md を修正します。
コードの実装は行いません。

- 影響分析を実施し、影響を受ける worktree・セクションを特定
- 変更理由と変更履歴を plan.md に追記
- 既存の plan の全面書き直しではなく、最小限の差分更新

### ai-review

現在のブランチの実装を plan と照合し、PR コメント形式でレビュー結果を報告します。
コードの修正は行いません。

- Critical / Warning / Info の 3 段階で問題を報告
- 計画との整合性・API 契約・コード品質・安全性・テストをチェック

### base-rules

全 Claude セッションに自動適用される基本ルールです。

- Serena MCP を活用したプロジェクト調査（利用可能な場合）
- コード品質・安全性・スコープ管理の共通規約

## wt（git worktree ヘルパー）

並列開発で使用する git worktree の管理コマンドです。

```bash
# インストール（~/bin にリンク）
ln -sf "$(pwd)/bin/wt" ~/bin/wt
```

使い方：
```bash
# サブタスクなし（1 worktree）
wt create add-vote

# サブタスクで分割（複数 worktree）
wt create add-vote button display
wt create add-vote ui api

# 削除
wt remove add-vote
wt remove add-vote button display

# 一覧
wt list
```

## 作業フロー

```
[1. 計画]          [2. 実装]              [3. レビュー]      [4. マージ]
/plan-master   →   worktree で並列実装  →   /ai-review   →   PR 作成・削除
                   (UI / API / ...)        (各 worktree で)

※ plan 修正が必要な場合: /plan-fix → 修正後に再実装
```

詳細は [docs/overview.md](docs/overview.md) を参照してください。

## ディレクトリ構成

```
ai-dev-tools/
├── skills/                    # Claude skills（npx skills で配布）
│   ├── plan-master/
│   │   └── SKILL.md           #   実装計画書の作成
│   ├── plan-fix/
│   │   └── SKILL.md           #   plan の修正
│   ├── ai-review/
│   │   └── SKILL.md           #   レビュー
│   └── base-rules/
│       └── SKILL.md           #   基本ルール（自動適用）
├── bin/
│   └── wt                     # git worktree ヘルパー
├── docs/
│   ├── overview.md            # 設計思想
│   ├── templates/             # CLAUDE.md / CONTEXT.md テンプレート
│   └── examples/              # plan の完成例
│       └── add-vote/
└── AGENTS.md                  # skills エコシステム メタデータ
```
