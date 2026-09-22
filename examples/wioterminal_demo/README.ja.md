**Languages:** [English](./README.md) | 日本語

# wioterminal_demo

このリポジトリの Wio Terminal バインディングを一つのプログラムで一通り動かす
メニュー方式のデモです。FlutterKaigi ブースのデモを兼ねつつ、バインディング
APIの不足を洗い出す結合テストの役割も持ちます。5-way switch の上下でメニューを
移動し、ボタン A で決定します。各機能画面ではボタン C を押すとメニューに戻ります。

| メニュー項目 | 機能 |
| --- | --- |
| Blink LED | ユーザー LED (#13) |
| Play melody | ブザー / PWM トーン (#15) |
| Light/mic levels | 照度センサー・マイクの ADC 値をバーグラフ表示 (#16) |
| Spirit level | 加速度センサーの傾きを LCD 上のドットで表示 (#17) |
| Send IR code | 赤外線送信、NEC フレーム (#18) |
| SD card log | microSD (FAT) への追記 (#19) |
| Wi-Fi HTTP GET | RTL8720DN Wi-Fi + HTTP GET (#20) — 実行前に `main.dart` 内の SSID/パスワードのプレースホルダーを書き換えてください。プレースホルダーのままだと接続失敗のメッセージを表示するだけです |

```dart
import 'dart:io';

import 'package:wio_terminal/wio_terminal.dart';
import 'package:wio_terminal/sd.dart';
import 'package:wio_terminal/wifi.dart';

void main() {
  final display = newDisplay();
  final led = newLed();
  final buttons = newButtons();
  // ... バインディングごとにハンドルを取得 ...

  var selected = 0;
  drawMenu(display, selected);

  while (true) {
    if (buttons.isPressed(Button.down)) {
      selected += 1;
      selected %= 7;
      drawMenu(display, selected);
      sleep(const Duration(milliseconds: 200));
    } else if (buttons.isPressed(Button.a)) {
      switch (selected) {
        case 0:
          runBlink(display, led, buttons);
        // ... メニュー項目ごとに case ...
      }
      drawMenu(display, selected);
    }
  }
}
```

全体は [`main.dart`](./main.dart) を参照してください。

## 必要なもの

- Dart SDK 3.x
- Go と [TinyGo](https://tinygo.org/getting-started/install/)（TinyGo 0.42.0 で確認）
- USB で接続した Wio Terminal
- 任意: microSD カード（SD card log 項目用）と Wi-Fi アクセスポイント（Wi-Fi 項目用）

## 実行手順

`dart2tinygo flash` は今のところ追加の `tinygo` フラグを渡せず、最後のメニュー
項目が使う Wi-Fi/HTTP バインディングは TinyGo のデフォルトより大きい goroutine
スタックを必要とします（`packages/wio_terminal/lib/wifi.dart` 参照）。そのため
変換と書き込みを2段階に分け、2段階目で `-stack-size=4KB` を指定します。

```sh
# 1. 依存解決（初回のみ。リポジトリルートで実行 — pub workspace）
dart pub get

# 2. Go に変換（main.go と go.mod を書き出し、`go mod tidy` を実行）
cd packages/dart2tinygo
dart run bin/dart2tinygo.dart build ../../examples/wioterminal_demo/main.dart \
  -o ../../examples/wioterminal_demo/build

# 3. TinyGo で直接ビルド・書き込み
cd ../../examples/wioterminal_demo/build
tinygo flash -target=wioterminal -stack-size=4KB .
```

## 既知の制約

`mountSdCard()`（"SD card log" 項目で使用）はカードが挿入されていないと panic
します — コンストラクタから Go のエラーを表現する手段がまだないためです
（#19）。このデモではマウント前にボタン C で中断できるようにしていますが、
カード未挿入のままボタン A を押すとプログラム全体が停止し、リセットが必要です。

使用しているバインディングの全体は
[`packages/wio_terminal`](../../packages/wio_terminal) を参照してください。
