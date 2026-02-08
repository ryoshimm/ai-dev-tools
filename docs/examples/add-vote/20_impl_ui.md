# UI 実装指示: add-vote

**担当 worktree**: `feature/add-vote/ui`

---

## 実装する機能

### 1. VoteButton コンポーネント
タスクごとに表示される投票ボタン。

**振る舞い:**
- 未投票状態: アウトラインのアイコン + 投票数
- 投票済み状態: 塗りつぶしのアイコン + 投票数（色が変わる）
- クリックで投票 / 取消をトグル
- 未認証ユーザーには表示しない

**Props:**
```typescript
interface VoteButtonProps {
  taskId: string;
  voteCount: number;
  hasVoted: boolean;
  onToggle: (taskId: string) => void;
  disabled?: boolean;
}
```

### 2. useVote フック
投票操作と楽観的 UI 更新を管理するカスタムフック。

**責務:**
- API 呼び出し（`POST /api/tasks/:taskId/vote`）
- 楽観的更新（API レスポンス前に UI を即時反映）
- エラー時のロールバック（API 失敗時に元の状態に戻す）

### 3. TaskList への統合
既存の TaskList コンポーネントに VoteButton を追加。

**変更内容:**
- 各タスクカードに VoteButton を配置
- タスク一覧取得時に `voteCount` / `hasVoted` を受け取る

### 4. API クライアント
`11_api_contract.md` に基づく API 呼び出し関数。

### 5. モック
API 完了前の開発用モック。API 接続時に削除する。

---

## ファイル構成

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

---

## 実装上の注意

- 楽観的 UI 更新は `useVote` フック内で完結させる。TaskList 側でステート管理しない
- モックは `src/mocks/vote.ts` に集約し、環境変数や条件分岐で切り替える
- 既存の TaskList のレイアウト・スタイルを大きく変えない。VoteButton を追加するのみ
- アイコンは既存プロジェクトで使用しているアイコンライブラリに合わせる

---

## 完了条件
- [ ] VoteButton が各タスクに表示される
- [ ] クリックで投票 / 取消がトグル動作する
- [ ] 投票済みのタスクが視覚的に区別される
- [ ] 未認証ユーザーには投票ボタンが非表示
- [ ] 楽観的 UI 更新が実装されている
- [ ] モックで動作確認できる
- [ ] VoteButton のユニットテストが通る
- [ ] TaskList の既存テストが壊れていない

---

## 検証チェックリスト
- [ ] `11_api_contract.md` と整合しているか
- [ ] 許可ファイル以外を変更していないか
- [ ] 既存コンポーネントの変更が最小限か
