# API 契約: add-vote

UI と API の実装者は、このドキュメントに定義されたインターフェースに従うこと。
UI 側は API 完了前にモックを用いて開発し、API 完了後に接続する。

---

## エンドポイント一覧

| メソッド | パス | 概要 |
|---------|------|------|
| POST | `/api/tasks/:taskId/vote` | 投票のトグル（投票 / 取消） |
| GET | `/api/tasks` | タスク一覧（投票情報を含む）※既存 |

---

## POST `/api/tasks/:taskId/vote`

投票のトグル操作。投票済みなら取消、未投票なら投票する。

### リクエスト
- **認証**: 必須（Authorization ヘッダー）
- **Body**: なし

### レスポンス

**200 OK - 投票した場合**
```typescript
{
  voted: true;
  voteCount: number; // 投票後の総投票数
}
```

**200 OK - 投票を取り消した場合**
```typescript
{
  voted: false;
  voteCount: number; // 取消後の総投票数
}
```

**401 Unauthorized**
```typescript
{
  error: "Unauthorized";
}
```

**404 Not Found**
```typescript
{
  error: "Task not found";
}
```

---

## GET `/api/tasks`（既存エンドポイントの拡張）

既存のタスク一覧レスポンスに投票情報を追加する。

### レスポンス

**200 OK**
```typescript
{
  tasks: Array<{
    id: string;
    title: string;
    description: string;
    status: "todo" | "in_progress" | "done";
    createdAt: string;
    // --- 以下を追加 ---
    voteCount: number;   // このタスクの総投票数
    hasVoted: boolean;   // リクエストユーザーが投票済みか
  }>;
}
```

- 未認証リクエストの場合: `hasVoted` は常に `false`
- `voteCount` は全ユーザーに対して表示する

---

## 型定義（TypeScript）

```typescript
// 投票トグル API のレスポンス
interface VoteToggleResponse {
  voted: boolean;
  voteCount: number;
}

// タスク一覧の各タスク（拡張後）
interface Task {
  id: string;
  title: string;
  description: string;
  status: "todo" | "in_progress" | "done";
  createdAt: string;
  voteCount: number;
  hasVoted: boolean;
}

// タスク一覧 API のレスポンス
interface TaskListResponse {
  tasks: Task[];
}

// エラーレスポンス
interface ErrorResponse {
  error: string;
}
```

---

## 検証チェックリスト
- [ ] エンドポイントのパス・メソッドが明確か
- [ ] リクエスト / レスポンスの型が完全に定義されているか
- [ ] エラーケースのレスポンスが定義されているか
- [ ] UI 側がモックを作成するのに十分な情報があるか
