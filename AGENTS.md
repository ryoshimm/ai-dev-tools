# ai-dev-tools

Claude を用いた AI エージェンティック並列開発のためのスキル集。

## Skills

### Action スキル（明示呼び出し）

| スキル | 呼び出し | 説明 |
|--------|---------|------|
| `plan-master` | `/plan-master` | `.claude/plans/<feature>/plan.md` に実装計画書を作成する。プロジェクトを調査し、変更規模に応じたセクション構成で計画を生成する。コード実装は行わない。 |
| `plan-fix` | `/plan-fix` | 承認済みの plan.md を修正する。影響分析を行い、変更理由と変更履歴を追記する。コード実装は行わない。 |
| `ai-review` | `/ai-review` | 実装を plan と照合してレビューし、PR コメント形式で報告する。Critical / Warning / Info の 3 段階で問題を分類する。コード修正は行わない。 |

### Rule スキル（自動適用）

| スキル | 説明 |
|--------|------|
| `base-rules` | AI エージェンティック開発の基本ルール。プロジェクト調査（Serena MCP 活用）・コード品質・安全性・スコープ管理の共通規約を全セッションに自動適用する。 |

## Install

```bash
npx skills add ryoshimm/ai-dev-tools
```
