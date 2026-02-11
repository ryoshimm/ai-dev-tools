# AI エージェンティック並列開発フロー設計

本ドキュメントは、Claude を中心とした
**AI エージェンティック・コーディングを安全かつ再現性高く行うための思想・設計・作業フロー**をまとめたものです。

本設計は、個人開発だけでなく、
**既存プロジェクト・チーム開発への段階的導入**を前提としています。

---

## 基本思想

### 1. 並列 AI は「構造」で制御する
AI は以下の理由で暴走しやすい：

- 文脈を勝手に補完する
- 仕様を膨張させる
- 複数の役割を同時にやろうとする

そのため、以下を **構造的に分離**する。

- ブランチ
- ディレクトリ
- 役割（UI / API / Review）
- 作業責務

---

### 2. plan は「契約書」である
AI に自由に考えさせるフェーズと、
**厳密に従わせるフェーズ**を明確に分ける。

- plan 作成：思考・設計フェーズ
- 実装：契約履行フェーズ

実装時は **plan を唯一の正**とし、
AI が自己判断で仕様を変更してはならない。

plan の修正が必要な場合は、`/plan-fix` を使用して
影響分析と変更履歴を伴った修正を行う。

---

### 3. Skills でワークフローを配布する
計画作成・レビューのワークフローを
**[Vercel Skills](https://github.com/vercel-labs/skills) エコシステム**で管理・配布する。

- `npx skills add` で一発導入
- SKILL.md ベースのシンプルな構造
- プロジェクト単位 or グローバルでインストール可能

---

## スキル構成

```text
skills/
├── plan-master/    # 実装計画書の作成（/plan-master で呼び出し）
├── plan-fix/       # plan の修正（/plan-fix で呼び出し）
├── ai-review/      # 実装のレビュー・報告（/ai-review で呼び出し）
└── base-rules/     # 基本ルール（自動適用）
```

### Action スキル（明示呼び出し）

| スキル | 説明 |
|--------|------|
| `plan-master` | `.claude/plans/<feature>/plan.md` に実装計画書を作成 |
| `plan-fix` | 承認済み plan.md の修正。影響分析・変更履歴の追記 |
| `ai-review` | 実装を plan と照合してレビュー報告 |

### Rule スキル（自動適用）

| スキル | 説明 |
|--------|------|
| `base-rules` | プロジェクト調査（Serena MCP 活用）・コード品質・安全性・スコープ管理の共通ルール |

---

## 作業フロー

### 全体像

```text
[1. 計画]          [2. 実装]              [3. レビュー]      [4. マージ]
/plan-master   →   worktree で並列実装  →   /ai-review   →   PR 作成・削除
                   (UI / API / ...)        (各 worktree で)

※ plan 修正が必要な場合: /plan-fix → 修正後に再実装
```

### ステップ 1: 計画作成（plan-master）

1. Claude セッションで `/plan-master` を実行
2. ブランチ名と機能概要を伝える
3. plan-master がプロジェクトを調査
4. `.claude/plans/<feature>/plan.md` に実装計画書を生成
5. 人間が計画を確認・承認する

**ポイント**:
- plan-master はコードを書かない（計画のみ）
- 計画は「契約書」— 承認後は実装者が勝手に変更してはならない
- 1 ファイル（plan.md）に全情報を集約。変更規模に応じてセクションを増減

### ステップ 2: 並列実装（wt + Claude）

1. `wt create <feature> ui api` で worktree を作成
2. 各 worktree で別の Claude セッションを起動
3. 各セッションは plan.md の実装指示セクションに従って実装
4. plan.md に実行順序セクションがある場合、その順序に従う

**ポイント**:
- 1 worktree = 1 役割（UI / API など）
- 各 worktree は物理的に分離されているためファイル競合が起きない
- 実装者は割り当てられたスコープ外のファイルに触れない
- 不明点があれば推測せず質問する

### ステップ 3: レビュー（ai-review）

1. 各 worktree で `/ai-review` を実行
2. ai-review が plan と実装を照合
3. Critical / Warning / Info の3段階で問題を報告
4. 報告は PR コメント形式（そのまま GitHub に貼れる）
5. 実装者が指摘を確認し、修正を判断・実施

**ポイント**:
- ai-review はコードを修正しない（報告のみ）
- 修正の判断と実施は実装者に委ねる
- レビュー用の worktree は不要（同じ worktree で新しい Claude セッションを使う）

### plan の修正が必要な場合

レビューで Critical が出た原因が plan にある場合、または実装中に仕様漏れが発覚した場合：

1. `/plan-fix` を実行
2. plan-fix が影響分析を実施（影響を受ける worktree・セクションを特定）
3. plan.md を最小限の差分で修正し、変更履歴を追記
4. 人間が修正を承認
5. 影響を受ける worktree で再実装

### ステップ 4: マージ

1. 各 worktree の PR を作成
2. レビュー指摘の修正が完了していることを確認
3. main ブランチにマージ
4. `wt remove <feature> ui api` で worktree を削除

---

## 役割分離

このフローでは Claude を4つの役割で使い分ける。

| 役割 | 担当 | 禁止事項 |
|------|------|---------|
| 計画 | plan-master | コードの実装・変更 |
| 計画修正 | plan-fix | コードの実装・変更、plan の全面書き直し |
| 実装 | Claude セッション | plan の自己変更、スコープ外のファイル変更 |
| レビュー | ai-review | コードの修正、plan にない要件の追加 |

**各役割は別の Claude セッションで実行する。**
1つのセッションが複数の役割を兼務してはならない。

---

## plan.md のセクション構成

| セクション | 必須 | 説明 |
|-----------|------|------|
| 仕様 | 常に | 要件・制約・データモデル |
| タスク分解 | 常に | スコープ・許可ファイル・完了条件 |
| API 契約 | 条件付き | エンドポイント・型定義（UI + API 並列の場合） |
| 実行順序 | 条件付き | worktree の依存関係（複数 worktree の場合） |
| 実装指示 | 中〜大規模 | 役割ごとの詳細 |
| レビュー・テスト | 中〜大規模 | チェックリスト・受け入れ条件 |
| 変更履歴 | plan-fix 時 | 変更理由・影響範囲（plan-fix が追記） |

**変更規模による使い分け:**

- **Small**（軽微修正）: 仕様 + タスク分解のみ
- **Medium / Large**（新機能・複数レイヤ）: 該当する全セクション

迷った場合は Medium / Large として扱う。

---

## 導入手順

### Skills のインストール

```bash
# プロジェクトにインストール
npx skills add ryoshimm/ai-dev-tools

# またはグローバルにインストール
npx skills add ryoshimm/ai-dev-tools -g
```

### プロジェクトへの CLAUDE.md 配置（推奨）

プロジェクトごとに `.claude/CLAUDE.md` を配置すると、AI がプロジェクト固有のルールに従います。

テンプレートは [templates/](templates/) を参照してください。

### wt のインストール（任意）

並列開発で git worktree を使う場合：

```bash
git clone <ai-dev-tools-repo>
ln -sf "$(pwd)/bin/wt" ~/bin/wt
```

### 機能開発の流れ

```bash
# 1. 計画
#    Claude セッションで /plan-master を実行

# 2. worktree 作成
wt create add-vote ui api

# 3. 並列実装
#    各 worktree で Claude セッションを起動し、plan に従って実装

# 4. レビュー
#    各 worktree で /ai-review を実行

# 5. マージ・片付け
#    PR 作成 → マージ → worktree 削除
wt remove add-vote ui api
```
