**Languages:** [English](./README.md) | 日本語

ゴールデンテスト用ディレクトリ。`<case>.dart` 入力と `<case>.go` 期待出力のペアを置く。`../golden_test.dart` から実行される。`UPDATE_GOLDENS=1 dart test test/golden_test.dart` で再生成できる（[`CONTRIBUTING.ja.md`](../../../../CONTRIBUTING.ja.md) 参照）。

- `minimal_blink.dart` / `.go`：v0.1 最小構成（`void main()` + `int` ローカル変数 + `while (true)` + `print` + `sleep`）。
