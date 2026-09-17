# dart2tinygo (package)

**Languages:** [English](./README.md) | 日本語

CLI と Dart → Go 変換エンジン本体。

- `bin/`: CLI エントリポイント（`build` / `flash` / `check`）
- `lib/src/frontend/`: 解析・resolved AST 取得
- `lib/src/checker/`: 未対応構文の検出とエラー報告
- `lib/src/ir/`: 中間表現（任意）
- `lib/src/backend/`: Go コード生成
- `test/golden/`: `*.dart` 入力 → `*.go` 期待出力のゴールデンテスト

現時点では実装なし（スケルトンのみ）。設計方針・開発の流れは [`CONTRIBUTING.ja.md`](../../CONTRIBUTING.ja.md) を参照。
