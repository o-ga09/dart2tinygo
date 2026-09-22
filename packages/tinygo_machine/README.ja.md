# tinygo_machine (package)

**Languages:** [English](./README.md) | 日本語

TinyGo の `machine` パッケージ（GPIO、ADC、LED）に対応する、ボード非依存のバインディング。

本体（`packages/dart2tinygo`）にボード固有コードを入れないという設計原則のもと、ここは TinyGo が共通で提供する機能のみを扱う。ボード固有のバインディングは別パッケージ（例: `package:wio_terminal`）とする。

```dart
import 'dart:io';

import 'package:tinygo_machine/tinygo_machine.dart';

void main() {
  final led = Pin.led..configure(PinMode.output);
  while (true) {
    led.toggle();
    sleep(const Duration(milliseconds: 500));
  }
}
```

- **GPIO**: `Pin.led`（ボード自身のユーザーLED）、`Pin(n)`（任意のピン番号）、
  `configure(PinMode.output | PinMode.input)`（input は内部プルアップ）、
  `high()`/`low()`/`toggle()`/`get()`。
- **ADC**: `newAdc(pin)` で `Pin` をアナログ入力として設定し、`.read()` で
  0〜65535 の生サンプル値を取得する。
- **PWM** は未実装。GPIO/ADC と違い、TinyGo が対応するチップファミリごとに
  形の異なる PWM ペリフェラル型を公開しており共通の形が無いため、ボード非依存な
  API にはチップファミリ別の実装作業が本当に必要になる。
  [`docs/writing_bindings.ja.md`](../../docs/writing_bindings.ja.md) の
  「決定済み・未実装」を参照。

ボード非依存の完全な例は `examples/blinky` を参照（任意の TinyGo ターゲットで
`tinygo build -target=<board> .` がビルド可能）。
