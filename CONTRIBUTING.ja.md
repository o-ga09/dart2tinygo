# Contributing to dart2tinygo

**Languages:** [English](./CONTRIBUTING.md) | 日本語

このプロジェクトは、Dart のサブセットを TinyGo のソースコードに変換する OSS です。

## 設計原則（必ず守ること）

- **本体（`packages/dart2tinygo`）にボード固有の知識を入れない。** ボード対応は別パッケージのバインディングとして提供し、Dart 側の注釈（`@GoImport` / `@GoName` / `@GoType`）で Go 側の対応先を宣言する。
- 迷ったときの優先順位：**変換の正しさ ＞ バイナリサイズ ＞ 生成コードの読みやすさ**。
- 生成コードで文字列補間に `fmt.Sprintf` を使わない（TinyGo でのバイナリ肥大化を避けるため、型に応じて `strconv` 等で連結する）。

## 言語機能を追加するときの流れ

1. 対応したい Dart の構文・機能を Issue で明確にする（未対応構文の要望テンプレートを使う）。
2. `packages/dart2tinygo/lib/src/checker/` で、未対応の場合の検出・エラー報告が必要か確認する。
3. `packages/dart2tinygo/lib/src/backend/` で Go コード生成を実装する。
4. 変換ルールを決めたら [`docs/mapping.ja.md`](./docs/mapping.ja.md) に記録する。
5. 同じ PR で以下を必ず更新する：
   - `packages/dart2tinygo/test/golden/` のゴールデンテスト（後述）
   - [`docs/supported_features.ja.md`](./docs/supported_features.ja.md) の対応状況表

## ゴールデンテストの追加方法

- `packages/dart2tinygo/test/golden/` に `<case>.dart`（入力）と `<case>.go`（期待される生成結果）のペアを追加する。
- ケース名はテストしたい機能がわかる名前にする（例: `string_interpolation.dart` / `string_interpolation.go`）。
- 期待値の更新は `packages/dart2tinygo/` で `UPDATE_GOLDENS=1 dart test test/golden_test.dart` を実行することで行える。現在のジェネレータの出力（gofmt 済み）で各 `<case>.go` を上書きする。
- 未対応構文のテストは、期待するエラーメッセージと行番号も併せて検証する。

## バインディングを追加・変更するときの流れ

- 新しい注釈や API が必要になったら、まず注釈や設定で表現できないか検討する（本体にボード固有コードを入れないため）。
- 注釈の API が決まったら [`docs/writing_bindings.ja.md`](./docs/writing_bindings.ja.md) に反映する。

## PR を出す前に

- `dart analyze` / `dart test` が通ることを確認する。
- 対応する `docs/` の更新漏れがないか確認する。
