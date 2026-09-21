# dart2tinygo

**Languages:** [English](./README.md) | 日本語

Dart のサブセットを TinyGo のソースコードに変換し、マイコンで動かすための OSS です。

> **Status:** 初期構築中。v0.1 最小変換は実装済みです（トップレベルの
> `void main()` 単体、`int` 型ローカル変数、`while (true)`、`print(...)`、
> `sleep(Duration(...))`）。正確な範囲は
> [対応言語機能](./docs/supported_features.ja.md) を参照してください。

## これは何か

- Flutter/Dart 開発者が、Dart の書き心地（IDE補完・型チェック・lint）のままマイコンを動かせるようにするトランスパイラです。
- TinyGo が対応する多数のボード（Wio Terminal、Raspberry Pi Pico、micro:bit など）を対象にします。
- **Dart の完全な実装は目指しません。** 組み込みで役立つサブセットに絞ります。

設計方針の詳細は [`CONTRIBUTING.ja.md`](./CONTRIBUTING.ja.md) を参照してください。

## リポジトリ構成

```
packages/
  dart2tinygo/        # CLI + 変換エンジン
  tinygo_annotations/  # バインディング用の注釈（@GoImport / @GoName / @GoType）
  tinygo_machine/      # TinyGo 共通 machine パッケージのバインディング
examples/              # サンプル（blinky など）
docs/                  # 対応機能表・変換ルール・バインディングの書き方
```

## ドキュメント

- [対応言語機能](./docs/supported_features.ja.md)
- [Dart → Go 変換ルール](./docs/mapping.ja.md)
- [バインディングの作り方](./docs/writing_bindings.ja.md)

## Contributing

Issue・PR を歓迎します。開発の流れは [`CONTRIBUTING.ja.md`](./CONTRIBUTING.ja.md)、コミュニティの行動規範は [`CODE_OF_CONDUCT.ja.md`](./CODE_OF_CONDUCT.ja.md) を参照してください。

## セキュリティ

脆弱性の報告方法は [`SECURITY.ja.md`](./SECURITY.ja.md) を参照してください。

## ライセンス

[BSD-3-Clause](./LICENSE)
