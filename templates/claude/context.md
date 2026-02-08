# プロジェクトコンテキスト（必読）

このファイルは、このリポジトリにおける
**実装ルール・設計方針・参照すべき正規ドキュメントの一覧**を示します。

Claude は実装を開始する前に、必ず以下を確認してください。

---

## 優先して参照すべきドキュメント

存在する場合、以下は **単一の正（source of truth）**です。

- `README.md`
  - 開発手順、起動方法、前提条件

- `CONTRIBUTING.md`
  - コーディング規約、レビュー方針

- `docs/`
  - アーキテクチャ設計
  - ADR（Architecture Decision Record）

---

## コード規約・自動チェック

以下の設定ファイルが存在する場合、必ず従ってください。

- ESLint / Prettier / Biome 設定
- TypeScript / tsconfig
- Backend / API の lint / formatter 設定

---

## API / データ仕様

API やデータ構造に関しては、
以下が存在する場合、それを正とします。

- OpenAPI / Swagger
- GraphQL schema
- Prisma schema / DB 定義

---

## 変更してはいけないもの（例）

プロジェクト固有で変更禁止のものがある場合、
ここに明示してください。

- 自動生成コード
- 共通ライブラリ
- 特定ディレクトリ配下

（※ プロジェクトごとに適宜編集）
