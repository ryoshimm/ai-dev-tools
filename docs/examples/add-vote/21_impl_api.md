# API 実装指示: add-vote

**担当 worktree**: `feature/add-vote/api`

---

## 実装する機能

### 1. DB マイグレーション
`votes` テーブルを作成する。

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

### 2. Vote モデル
votes テーブルに対応するモデル。

### 3. 投票トグル API
`POST /api/tasks/:taskId/vote`

**処理フロー:**
1. 認証チェック（未認証なら 401）
2. taskId の存在チェック（存在しなければ 404）
3. 既存投票の有無を確認
4. 投票済み → 削除（取消）、未投票 → 作成（投票）
5. 投票後の総投票数を集計して返す

### 4. タスク一覧 API の拡張
`GET /api/tasks` のレスポンスに `voteCount` と `hasVoted` を追加。

**実装方針:**
- N+1 を避けるため、サブクエリまたは JOIN で投票数を一括取得
- `hasVoted` はリクエストユーザーの user_id で判定

---

## ファイル構成

| 操作 | パス |
|------|------|
| 新規 | `db/migrations/YYYYMMDD_create_votes.sql` |
| 新規 | `src/models/vote.ts` |
| 新規 | `src/api/votes/route.ts` |
| 新規 | `src/api/votes/handler.ts` |
| 変更 | `src/api/tasks/handler.ts` （一覧 API にフィールド追加）|
| 新規 | `tests/api/votes/vote.test.ts` |
| 変更 | `tests/api/tasks/list.test.ts` （レスポンスフィールド追加の検証）|

---

## 実装上の注意

- `ON DELETE CASCADE` により、タスク削除時に関連する投票も自動削除される
- 投票トグルの処理はトランザクション内で行う（削除と集計の間に不整合が起きないように）
- N+1 問題に注意。タスク一覧の投票数取得は 1 クエリで完結させる
- tasks テーブルに `vote_count` カラムを追加しない（votes テーブルから常に集計する）

---

## 完了条件
- [ ] マイグレーションが正常に実行・ロールバックできる
- [ ] `POST /api/tasks/:taskId/vote` で投票 / 取消がトグル動作する
- [ ] 同一ユーザーの重複投票が DB レベルで防止される（UNIQUE 制約）
- [ ] `GET /api/tasks` のレスポンスに `voteCount` と `hasVoted` が含まれる
- [ ] 未認証リクエストに 401 を返す
- [ ] 存在しないタスクへの投票に 404 を返す
- [ ] 全テストが通る

---

## 検証チェックリスト
- [ ] `11_api_contract.md` のエンドポイント定義と一致しているか
- [ ] `00_spec.md` のデータモデルと一致しているか
- [ ] 許可ファイル以外を変更していないか
- [ ] 既存の tasks CRUD テストが壊れていないか
