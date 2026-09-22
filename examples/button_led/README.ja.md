**Languages:** [English](./README.md) | 日本語

# button_led

ボタンAを押している間、Wio Terminal のユーザーLED（青）を点灯するサンプル。

```dart
import 'package:wio_terminal/wio_terminal.dart';

void main() {
  final led = newLed();
  final buttons = newButtons();
  while (true) {
    if (buttons.isPressed(Button.a)) {
      led.on();
    } else {
      led.off();
    }
  }
}
```

## 必要なもの

- Dart SDK 3.x
- Go と [TinyGo](https://tinygo.org/getting-started/install/)（TinyGo 0.42.0 で確認）
- USB接続した Wio Terminal

## 実行

```sh
# 1. 依存関係を解決（リポジトリのルートで一度だけ。pub workspace のため）
dart pub get
dart pub global activate dart2tinygo   # 一度だけ。`dart2tinygo` CLI をインストールする

# 2. Go に変換（main.go と go.mod を書き出し）してフラッシュ
dart2tinygo flash examples/button_led/main.dart \
  -o examples/button_led/build --target=wioterminal
```

3つある上部ボタンの左端（ボタンA）を押している間 LED が点灯し、離すと消灯する。

使用しているバインディング（`newLed()` / `newButtons()`）は
[`packages/wio_terminal`](../../packages/wio_terminal) を参照。
