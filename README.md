# ai-dev-tools

Claude を用いた AI エージェンティック並列開発のための個人用ツール群。

## セットアップ

```bash
git clone <this-repo>
cd ai-dev-tools
chmod +x install.sh
./install.sh
```

以下の 3 コマンドが `~/bin` にリンクされます：

| コマンド | 用途 |
|---------|------|
| `ai-wt` | git worktree を用いた並列開発支援 |
| `setup-skills` | skills を `~/.claude/skills/` に展開 |
| `setup-claudemd` | プロジェクトに CLAUDE.md / テンプレートを展開 |

### セットアップ後の確認

```bash
which ai-wt
ai-wt help
```

## コマンド

### ai-wt

git worktree を用いて、機能ごとに役割別の worktree を作成・管理します。

```bash
ai-wt create <feature> --roles <role1,role2,...>
ai-wt remove <feature> --roles <role1,role2,...>
ai-wt list
ai-wt help
```

例：
```bash
ai-wt create fix-main-board --roles ui
ai-wt create add-vote --roles ui,api
ai-wt create feat-todo-app --roles ui,api,batch
```

### setup-skills

`templates/skills/` 配下のスキルディレクトリを `~/.claude/skills/` にシンボリックリンクで展開します。
すでに存在するスキルはスキップされます。

```bash
setup-skills
```

### setup-claudemd

対象プロジェクトの `.claude/` 配下にテンプレートを展開します。
対象プロジェクトのディレクトリ内で実行してください。

```bash
cd /path/to/your-project
setup-claudemd
```

動作：
- `BASIC.md` → シンボリックリンク (ai-dev-tools テンプレートへ)
- `AI_DEV_RULES.md` → シンボリックリンク (ai-dev-tools テンプレートへ)
- `CONTEXT.md` が存在しない → テンプレートからコピー (プロジェクトごとに編集)
- `CONTEXT.md` が既に存在 → スキップ
- `CLAUDE.md` が存在しない → 参照指示付きで新規作成
- `CLAUDE.md` が既に存在 → 参照指示を末尾に追記

## ディレクトリ構成

```
ai-dev-tools/
├── install.sh                    # インストーラー
├── bin/
│   ├── ai-wt                     # worktree ヘルパー
│   ├── setup-skills              # skills 展開
│   └── setup-claudemd            # CLAUDE.md 展開
├── templates/
│   ├── claude/                   # CLAUDE.md 用テンプレート
│   │   ├── BASIC.md              #   基本ルール
│   │   ├── AI_DEV_RULES.md       #   並列 AI 開発ルール
│   │   └── context.md            #   CONTEXT.md テンプレート
│   └── skills/                   # Claude skills
│       ├── plan-master/
│       │   └── SKILL.md          #   計画作成
│       └── ai-review/
│           └── SKILL.md          #   レビュー・修正
└── docs/
    └── overview.md               # 設計思想
```
