# wio_terminal (package)

**Languages:** [English](./README.md) | 日本語

[![pub package](https://img.shields.io/pub/v/wio_terminal.svg)](https://pub.dev/packages/wio_terminal)

[Seeed Wio Terminal](https://wiki.seeedstudio.com/Wio-Terminal-Getting-Started/) 向けの dart2tinygo バインディング。
Dart 側（`lib/wio_terminal.dart`）は注釈のみで、実体は `go/` 配下の TinyGo パッケージ
（`github.com/o-ga09/dart2tinygo/packages/wio_terminal/go`、import 名は `wio`）です。

現在提供しているもの:

| Dart | Go | 用途 |
| --- | --- | --- |
| `newDisplay()` | `wio.NewDisplay()` | SPI3 と ILI9341 LCD を初期化（横向き、バックライト ON、黒でクリア） |
| `Display.clear()` | `(*Display).Clear()` | 画面を黒で塗りつぶす |
| `Display.drawText(x, y, text)` | `(*Display).DrawText(x, y, text)` | 白い文字（FreeMono Bold 12pt）をベースライン (x, y) に描画 |
| `newLed()` | `wio.NewLed()` | ユーザーLED（青、`machine.LED`）を出力として設定 |
| `Led.on()` / `.off()` / `.toggle()` | `(*Led).On()` / `.Off()` / `.Toggle()` | ユーザーLEDを制御 |

使い方は `examples/hello_wioterminal`、注釈の仕組みは [docs/writing_bindings.ja.md](../../docs/writing_bindings.ja.md) を参照。

サンプルがチェックアウトからビルドできるよう、当面このパッケージは本リポジトリに置いています。
設計上はボードバインディングを分離可能なパッケージとして扱っており、将来別リポジトリに移す可能性があります。
