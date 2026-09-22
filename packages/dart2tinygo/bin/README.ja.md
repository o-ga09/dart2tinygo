**Languages:** [English](./README.md) | 日本語

CLI エントリポイント（`dart2tinygo.dart`）。`build`・`check`・`flash` は v0.0.2 の範囲で実装済み（[`docs/supported_features.ja.md`](../../../docs/supported_features.ja.md) 参照）。`flash` は `build` を実行した後、出力ディレクトリで `tinygo flash -target=<target> [-port=<port>]` を標準入出力を引き継いで実行する。実際に書き込むには `tinygo` が `PATH` にあることと実機が必要。
