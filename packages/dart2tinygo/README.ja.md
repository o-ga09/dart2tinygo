# dart2tinygo (package)

**Languages:** [English](./README.md) | 日本語

CLI と Dart → Go 変換エンジン本体。

- `bin/`: CLI エントリポイント（`build` 実装済み、`check` 実装済み、`flash` はスタブ — 実機が必要）
- `lib/src/frontend/`: 解析・resolved AST 取得（実装済み。`package:analyzer` の `AnalysisContextCollection` を使用）
- `lib/src/checker/`: 未対応構文の検出とエラー報告（v0.1 最小構成の範囲で実装済み）
- `lib/src/ir/`: 中間表現（任意、未使用 — backend は resolved AST を直接走査する）
- `lib/src/backend/`: Go コード生成（v0.1 最小構成の範囲で実装済み）
- `test/golden/`: `*.dart` 入力 → `*.go` 期待出力のゴールデンテスト

**状態：** v0.1 最小構成を実装済み。対応するのはトップレベルの `void main()`
単体、`int` 型ローカル変数、`while (true)`、`print(...)`、
`sleep(Duration(...))`。範囲の詳細は
[`docs/supported_features.ja.md`](../../docs/supported_features.ja.md)、
変換ルールは [`docs/mapping.ja.md`](../../docs/mapping.ja.md) を参照。
それ以外（クラス、`if`/`for`、バインディング、`flash` など）は未実装。

```
dart run bin/dart2tinygo.dart check <entry.dart>
dart run bin/dart2tinygo.dart build <entry.dart> [-o out_dir]
```

設計方針・開発の流れは [`CONTRIBUTING.ja.md`](../../CONTRIBUTING.ja.md) を参照。
