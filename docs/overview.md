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

---

### 3. CLAUDE.md は「憲法」
`.claude/CLAUDE.md` は：

- Claude の行動規範
- 判断ルール
- 禁止事項

を定義する **最上位ドキュメント**とする。

プロジェクト固有の実装ルールは直接書かず、
**参照先（CONTEXT.md）を示す**。

---

## ドキュメント構成と役割

```text
.claude/
├─ CLAUDE.md          # 憲法（Claude の振る舞い・判断ルール）
├─ BASIC.md           # 基本法（plan 駆動開発・役割分離のルール）
├─ AI_DEV_RULES.md    # 補足法（並列 AI 開発固有のルール）
├─ CONTEXT.md         # 地図（このプロジェクトの正規ドキュメント一覧）
└─ plans/             # 契約書（feature ごとの実装計画）
    └─ <feature>/
        ├─ 00_spec.md
        ├─ 10_tasks.md
        ├─ 11_api_contract.md
        ├─ 15_execution_order.md
        ├─ 20_impl_ui.md
        ├─ 21_impl_api.md
        └─ 30_review_test.md
```

### 各ドキュメントの関係

```text
CLAUDE.md（憲法）
  ├─→ BASIC.md（基本法）        … 全プロジェクト共通の開発ルール
  ├─→ AI_DEV_RULES.md（補足法） … 並列 AI 開発時の追加ルール
  ├─→ CONTEXT.md（地図）        … プロジェクト固有の参照先・制約
  └─→ plans/<feature>/（契約書） … feature ごとの実装計画
```

- **CLAUDE.md** は参照指示のみを持ち、ルール本体は BASIC.md / AI_DEV_RULES.md に分離
- **BASIC.md / AI_DEV_RULES.md** は ai-dev-tools からのシンボリックリンク（更新が自動反映）
- **CONTEXT.md** はプロジェクトごとにコピー・編集する（テンプレートからの出発点）
- **plans/** は feature ごとに作成・消費される（plan-master スキルが生成）

---

## 作業フロー

### 全体像

```text
[1. 計画]          [2. 実装]              [3. レビュー]
plan-master    →   worktree で並列実装  →   ai-review
                   (UI / API / ...)        (各 worktree で実行)
```

### ステップ 1: 計画作成（plan-master）

1. Claude セッションで `/plan-master` を実行
2. ブランチ名と機能概要を伝える
3. plan-master がプロジェクトを調査（Serena MCP があれば活用）
4. `.claude/plans/<feature>/` に計画ファイルを生成
5. 人間が計画を確認・承認する

**ポイント**:
- plan-master はコードを書かない（計画のみ）
- 計画は「契約書」— 承認後は実装者が勝手に変更してはならない
- 変更規模に応じて作成ファイル数が変わる（Small: 2ファイル、Medium/Large: 最大7ファイル）

### ステップ 2: 並列実装（ai-wt + Claude）

1. `ai-wt create <feature> --roles ui,api` で worktree を作成
2. 各 worktree で別の Claude セッションを起動
3. 各セッションは plan の `20_impl_*.md` に従って実装
4. `15_execution_order.md` がある場合、その順序に従う

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

### ステップ 4: マージ

1. 各 worktree の PR を作成
2. レビュー指摘の修正が完了していることを確認
3. main ブランチにマージ
4. `ai-wt remove <feature> --roles ui,api` で worktree を削除

---

## 役割分離

このフローでは Claude を3つの役割で使い分ける。

| 役割 | 担当 | 禁止事項 |
|------|------|---------|
| 計画 | plan-master | コードの実装・変更 |
| 実装 | Claude セッション | plan の自己変更、スコープ外のファイル変更 |
| レビュー | ai-review | コードの修正、plan にない要件の追加 |

**各役割は別の Claude セッションで実行する。**
1つのセッションが複数の役割を兼務してはならない。

---

## plan ファイルの番号体系

| 番号帯 | 種別 | ファイル例 |
|--------|------|-----------|
| 00 | 仕様（不変） | `00_spec.md` |
| 10 | タスク・契約・順序 | `10_tasks.md`, `11_api_contract.md`, `15_execution_order.md` |
| 20 | 実装指示（役割別） | `20_impl_ui.md`, `21_impl_api.md` |
| 30 | レビュー・テスト | `30_review_test.md` |

**変更規模による使い分け:**

- **Small**（軽微修正）: `00_spec.md` + `10_tasks.md` のみ
- **Medium / Large**（新機能・複数レイヤ）: 全ファイル作成

迷った場合は Medium / Large として扱う。

---

## ツール構成

ai-dev-tools は以下の3つのコマンドと2つのスキルで構成される。

### コマンド（bin/）

| コマンド | 用途 |
|---------|------|
| `ai-wt` | git worktree の作成・削除・一覧 |
| `setup-skills` | スキルを `~/.claude/skills/` にシンボリックリンク展開 |
| `setup-claudemd` | プロジェクトに CLAUDE.md / テンプレートを展開 |

### スキル（templates/skills/）

| スキル | 用途 |
|--------|------|
| `plan-master` | 計画ファイルの作成 |
| `ai-review` | 実装のレビュー・報告 |

### テンプレート（templates/claude/）

| ファイル | 展開方式 | 用途 |
|---------|---------|------|
| `BASIC.md` | シンボリックリンク | 基本開発ルール |
| `AI_DEV_RULES.md` | シンボリックリンク | 並列 AI 開発ルール |
| `context.md` | コピー | CONTEXT.md テンプレート |

シンボリックリンクのファイルは ai-dev-tools 側を更新すれば全プロジェクトに自動反映される。
CONTEXT.md はプロジェクトごとに内容が異なるためコピー方式。

---

## 導入手順

### 初回セットアップ（1回のみ）

```bash
git clone <ai-dev-tools-repo>
cd ai-dev-tools
./install.sh        # コマンドを ~/bin にリンク、PATH 追加
setup-skills        # スキルを ~/.claude/skills/ にリンク
```

### プロジェクトへの導入（プロジェクトごと）

```bash
cd /path/to/your-project
setup-claudemd      # .claude/ にテンプレート展開
# → CONTEXT.md をプロジェクトに合わせて編集
```

### 機能開発の流れ

```bash
# 1. 計画
#    Claude セッションで /plan-master を実行

# 2. worktree 作成
ai-wt create add-vote --roles ui,api

# 3. 並列実装
#    各 worktree で Claude セッションを起動し、plan に従って実装

# 4. レビュー
#    各 worktree で /ai-review を実行

# 5. マージ・片付け
#    PR 作成 → マージ → worktree 削除
ai-wt remove add-vote --roles ui,api
```
