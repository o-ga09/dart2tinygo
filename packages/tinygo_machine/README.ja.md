# tinygo_machine (package)

**Languages:** [English](./README.md) | 日本語

TinyGo の `machine` パッケージ（GPIO、time、LED など）に対応する、ボード非依存のバインディング。

本体（`packages/dart2tinygo`）にボード固有コードを入れないという設計原則のもと、ここは TinyGo が共通で提供する機能のみを扱う。ボード固有のバインディングは別リポジトリ（例: `package:wio_terminal`）とする。

現時点では実装なし（スケルトンのみ）。
