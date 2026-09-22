# tinygo_machine (package)

**Languages:** [English](./README.md) | 日本語

[![pub package](https://img.shields.io/pub/v/tinygo_machine.svg)](https://pub.dev/packages/tinygo_machine)

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
- **PWM**: `newPwm(pin, freqHz)` は、このチップファミリが公開する PWM
  ペリフェラルを（atsamd51 なら TCC0〜4、rp2 なら PWM0〜7、...）順に試し、
  そのピンを取得できたものを使う。GPIO/ADC と違いチップファミリごとに形の
  異なるペリフェラル型を公開しており共通の形が無いため、固定的なマッピングでは
  なくチップファミリ別の探索になっている。`.setFrequency(freqHz)` で周波数を
  変更（同じペリフェラルの他チャンネルにも影響する）、`.setDuty(percent)` で
  デューティ比（0〜100）を設定する。

ボード非依存の完全な例は `examples/blinky` を参照（任意の TinyGo ターゲットで
`tinygo build -target=<board> .` がビルド可能）。
