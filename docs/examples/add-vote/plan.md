# 実装計画書: add-vote

## 仕様

### 概要
Todo アプリの各タスクに「投票（いいね）」機能を追加する。
ユーザーは各タスクに対して 1 回だけ投票でき、投票数がタスク一覧に表示される。

### 背景
チーム内でタスクの優先度を可視化するため、メンバーが「このタスクは重要」と思うものに投票できる仕組みが求められている。

### 機能要件
- ユーザーは各タスクに対して投票（いいね）できる
- 1 ユーザーにつき 1 タスクあたり 1 回まで
- 投票済みのタスクに再度クリックすると投票を取り消せる（トグル動作）
- タスク一覧に各タスクの投票数を表示する
- 自分が投票済みのタスクは視覚的に区別する

### 非機能要件
- 投票操作のレスポンスは 200ms 以内
- 楽観的 UI 更新（API レスポンスを待たずに UI を即時反映）

### データモデル

#### votes テーブル（新規）
| カラム | 型 | 制約 |
|--------|------|------|
| id | UUID | PK |
| task_id | UUID | FK → tasks.id, NOT NULL |
| user_id | UUID | FK → users.id, NOT NULL |
| created_at | TIMESTAMP | NOT NULL, DEFAULT now() |

- `(task_id, user_id)` に UNIQUE 制約

#### tasks テーブル（変更なし）
- votes テーブルから集計するため、tasks テーブルへのカラム追加は行わない

### 制約
- 既存のタスク CRUD 機能に影響を与えない
- 認証済みユーザーのみ投票可能（未認証ユーザーには投票ボタンを表示しない）
- DB マイグレーションは API 側の責務とする

### 用語
- **投票 / vote**: タスクに対する「いいね」操作
- **投票数 / vote count**: あるタスクに対する総投票数

---

## タスク分解

### 役割構成
- **API**: バックエンド実装（DB マイグレーション、エンドポイント）
- **UI**: フロントエンド実装（投票ボタン、表示）

### Task 1: API - 投票機能のバックエンド実装

**担当 worktree**: `feature/add-vote/api`

#### スコープ
- votes テーブルの DB マイグレーション作成
- 投票トグル API エンドポイントの実装
- タスク一覧 API に投票数・投票済みフラグを追加

#### 許可ファイル
- `db/migrations/`
- `src/api/votes/` (新規)
- `src/api/tasks/` (既存の一覧 API にフィールド追加)
- `src/models/vote.ts` (新規)
- `tests/api/votes/` (新規)
- `tests/api/tasks/` (既存テストの更新)

#### 完了条件
- [ ] votes テーブルのマイグレーションが実行可能
- [ ] `POST /api/tasks/:taskId/vote` が正しく動作する（投票 / 取消のトグル）
- [ ] `GET /api/tasks` のレスポンスに `voteCount` と `hasVoted` が含まれる
- [ ] 同一ユーザーの重複投票が DB レベルで防止される
- [ ] 未認証リクエストに 401 を返す
- [ ] 全テストが通る

#### やってはいけないこと
- フロントエンドのコードに触れない
- tasks テーブルのスキーマを変更しない
- 既存の tasks CRUD エンドポイントのレスポンス構造を破壊しない

### Task 2: UI - 投票機能のフロントエンド実装

**担当 worktree**: `feature/add-vote/ui`

#### スコープ
- 投票ボタンコンポーネントの作成
- タスク一覧に投票数・投票ボタンを表示
- 楽観的 UI 更新の実装
- API 完了前はモックデータで開発

#### 許可ファイル
- `src/components/VoteButton/` (新規)
- `src/components/TaskList/` (既存、投票ボタン追加)
- `src/hooks/useVote.ts` (新規)
- `src/api/vote.ts` (新規、API クライアント)
- `src/mocks/vote.ts` (新規、開発用モック)
- `tests/components/VoteButton/` (新規)
- `tests/components/TaskList/` (既存テストの更新)

#### 完了条件
- [ ] 投票ボタンが各タスクに表示される
- [ ] クリックで投票 / 取消がトグルされる
- [ ] 投票数が表示される
- [ ] 投票済みタスクが視覚的に区別される（例: ボタンの色が変わる）
- [ ] 未認証ユーザーには投票ボタンが表示されない
- [ ] 楽観的 UI 更新が実装されている（クリック即時反映）
- [ ] API 未接続でもモックで動作確認できる
- [ ] 全テストが通る

#### やってはいけないこと
- バックエンドのコードに触れない
- 既存のタスク CRUD 機能の動作を変更しない
- API 契約に定義されていない API を呼び出さない

---

## API 契約

UI と API の実装者は、このセクションに定義されたインターフェースに従うこと。
UI 側は API 完了前にモックを用いて開発し、API 完了後に接続する。

### エンドポイント一覧

| メソッド | パス | 概要 |
|---------|------|------|
| POST | `/api/tasks/:taskId/vote` | 投票のトグル（投票 / 取消） |
| GET | `/api/tasks` | タスク一覧（投票情報を含む）※既存 |

### POST `/api/tasks/:taskId/vote`

投票のトグル操作。投票済みなら取消、未投票なら投票する。

**リクエスト:**
- 認証: 必須（Authorization ヘッダー）
- Body: なし

**レスポンス:**

200 OK - 投票した場合:
```typescript
{ voted: true; voteCount: number; }
```

200 OK - 投票を取り消した場合:
```typescript
{ voted: false; voteCount: number; }
```

401 Unauthorized:
```typescript
{ error: "Unauthorized"; }
```

404 Not Found:
```typescript
{ error: "Task not found"; }
```

### GET `/api/tasks`（既存エンドポイントの拡張）

既存のタスク一覧レスポンスに投票情報を追加する。

200 OK:
```typescript
{
  tasks: Array<{
    id: string;
    title: string;
    description: string;
    status: "todo" | "in_progress" | "done";
    createdAt: string;
    voteCount: number;   // このタスクの総投票数
    hasVoted: boolean;   // リクエストユーザーが投票済みか
  }>;
}
```

- 未認証リクエストの場合: `hasVoted` は常に `false`
- `voteCount` は全ユーザーに対して表示する

### 型定義（TypeScript）

```typescript
interface VoteToggleResponse {
  voted: boolean;
  voteCount: number;
}

interface Task {
  id: string;
  title: string;
  description: string;
  status: "todo" | "in_progress" | "done";
  createdAt: string;
  voteCount: number;
  hasVoted: boolean;
}

interface TaskListResponse {
  tasks: Task[];
}

interface ErrorResponse {
  error: string;
}
```

---

## 実行順序

### ステップ 1: API（最初に開始）
- **worktree**: `feature/add-vote/api`
- **依存**: なし
- **内容**: DB マイグレーション、投票 API エンドポイント、タスク一覧 API 拡張

### ステップ 2: UI（API と並列開始可能）
- **worktree**: `feature/add-vote/ui`
- **依存**: API 契約セクションが確定していること
- **内容**: 投票ボタンコンポーネント、タスク一覧への統合、楽観的 UI 更新
- **備考**: API 完了前はモックで開発。API 完了後にモックを実 API に切り替え

### ステップ 3: レビュー（各 worktree の実装完了後）
- 各 worktree で `/ai-review` を実行
- API → UI の順にレビューすることを推奨（API の問題が UI に影響するため）

```text
時間 →

API:  [========== 実装 ==========][レビュー]
UI:   [==== モックで実装 ====][API接続][レビュー]
```

---

## 実装指示

### API 実装

**担当 worktree**: `feature/add-vote/api`

#### 1. DB マイグレーション

```sql
CREATE TABLE votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE(task_id, user_id)
);

CREATE INDEX idx_votes_task_id ON votes(task_id);
```

#### 2. 投票トグル API

`POST /api/tasks/:taskId/vote` の処理フロー:
1. 認証チェック（未認証なら 401）
2. taskId の存在チェック（存在しなければ 404）
3. 既存投票の有無を確認
4. 投票済み → 削除（取消）、未投票 → 作成（投票）
5. 投票後の総投票数を集計して返す

#### 3. タスク一覧 API の拡張

`GET /api/tasks` のレスポンスに `voteCount` と `hasVoted` を追加。
- N+1 を避けるため、サブクエリまたは JOIN で投票数を一括取得
- `hasVoted` はリクエストユーザーの user_id で判定

#### ファイル構成

| 操作 | パス |
|------|------|
| 新規 | `db/migrations/YYYYMMDD_create_votes.sql` |
| 新規 | `src/models/vote.ts` |
| 新規 | `src/api/votes/route.ts` |
| 新規 | `src/api/votes/handler.ts` |
| 変更 | `src/api/tasks/handler.ts`（一覧 API にフィールド追加）|
| 新規 | `tests/api/votes/vote.test.ts` |
| 変更 | `tests/api/tasks/list.test.ts`（レスポンスフィールド追加の検証）|

#### 注意点
- `ON DELETE CASCADE` により、タスク削除時に関連する投票も自動削除される
- 投票トグルの処理はトランザクション内で行う
- N+1 問題に注意。タスク一覧の投票数取得は 1 クエリで完結させる
- tasks テーブルに `vote_count` カラムを追加しない

### UI 実装

**担当 worktree**: `feature/add-vote/ui`

#### 1. VoteButton コンポーネント

- 未投票状態: アウトラインのアイコン + 投票数
- 投票済み状態: 塗りつぶしのアイコン + 投票数（色が変わる）
- クリックで投票 / 取消をトグル
- 未認証ユーザーには表示しない

```typescript
interface VoteButtonProps {
  taskId: string;
  voteCount: number;
  hasVoted: boolean;
  onToggle: (taskId: string) => void;
  disabled?: boolean;
}
```

#### 2. useVote フック

- API 呼び出し（`POST /api/tasks/:taskId/vote`）
- 楽観的更新（API レスポンス前に UI を即時反映）
- エラー時のロールバック（API 失敗時に元の状態に戻す）

#### 3. TaskList への統合

- 各タスクカードに VoteButton を配置
- タスク一覧取得時に `voteCount` / `hasVoted` を受け取る

#### ファイル構成

| 操作 | パス |
|------|------|
| 新規 | `src/components/VoteButton/VoteButton.tsx` |
| 新規 | `src/components/VoteButton/VoteButton.test.tsx` |
| 新規 | `src/components/VoteButton/index.ts` |
| 新規 | `src/hooks/useVote.ts` |
| 新規 | `src/api/vote.ts` |
| 新規 | `src/mocks/vote.ts` |
| 変更 | `src/components/TaskList/TaskList.tsx` |
| 変更 | `src/components/TaskList/TaskList.test.tsx` |

#### 注意点
- 楽観的 UI 更新は `useVote` フック内で完結させる
- モックは `src/mocks/vote.ts` に集約し、環境変数で切り替える
- 既存の TaskList のレイアウトを大きく変えない
- アイコンは既存プロジェクトのアイコンライブラリに合わせる

---

## レビュー・テスト

### レビューチェックリスト

#### API
- [ ] votes テーブルのマイグレーションがデータモデルと一致
- [ ] `UNIQUE(task_id, user_id)` 制約が存在する
- [ ] `POST /api/tasks/:taskId/vote` が API 契約通りのレスポンスを返す
- [ ] `GET /api/tasks` に `voteCount` / `hasVoted` が追加されている
- [ ] 未認証リクエストに 401 を返す
- [ ] 存在しないタスクへの投票に 404 を返す
- [ ] トランザクションが適切に使われている
- [ ] N+1 問題が発生していない
- [ ] 既存の tasks CRUD エンドポイントに影響がない

#### UI
- [ ] VoteButton コンポーネントが作成されている
- [ ] 投票 / 取消のトグル動作が正しい
- [ ] 投票済み / 未投票の視覚的な区別がある
- [ ] 未認証ユーザーに投票ボタンが表示されない
- [ ] 楽観的 UI 更新が実装されている
- [ ] API エラー時のロールバック処理がある
- [ ] 既存の TaskList のレイアウトが大きく変わっていない

### テスト方針

#### API テスト
- 単体: Vote モデルの CRUD、投票トグルのロジック、重複投票の防止
- 結合: エンドポイントの正常系・異常系（200, 401, 404）

#### UI テスト
- コンポーネント: VoteButton の表示状態、クリックイベント
- フック: useVote の楽観的更新、API 失敗時のロールバック

### 受け入れ条件
1. 認証済みユーザーがタスクに投票・取消できる
2. 投票数がタスク一覧に正しく表示される
3. 投票済みタスクが視覚的に区別される
4. 未認証ユーザーには投票ボタンが表示されない
5. 既存のタスク CRUD 機能が壊れていない
6. 全テスト（API + UI）が通る
