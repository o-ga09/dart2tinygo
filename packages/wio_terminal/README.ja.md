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
| `Display.width()` / `.height()` | `(*Display).Width()` / `.Height()` | 現在の回転角での画面サイズ（ピクセル） |
| `Display.fillScreen(color)` | `(*Display).FillScreen(color)` | 画面全体を[`Color`](./lib/wio_terminal.dart)で塗りつぶす |
| `Display.setBacklight(on)` | `(*Display).SetBacklight(on)` | バックライトのON/OFF |
| `Display.setRotation(degrees)` | `(*Display).SetRotation(degrees)` | 画面を時計回りに回転（0/90/180/270） |
| `Display.drawPixel/drawLine/drawRect/fillRect/drawCircle/fillCircle(..., color)` | `(*Display).DrawPixel/DrawLine/DrawRect/FillRect/DrawCircle/FillCircle(...)` | 図形描画（`tinygo.org/x/tinydraw` 経由） |
| `Display.drawTextColor(x, y, text, color)` / `.drawTextSize(x, y, text, color, size)` / `.textWidth(text, size)` | `(*Display).DrawTextColor(...)` / `.DrawTextSize(...)` / `.TextWidth(...)` | 色付き文字、他のフォントサイズ（9/12/18/24）、描画幅の計測 |
| `rgb(r, g, b)` | `wio.RGB(r, g, b)` | 8bit成分から[`Color`](./lib/wio_terminal.dart)を作る |
| `newLed()` | `wio.NewLed()` | ユーザーLED（青、`machine.LED`）を出力として設定 |
| `Led.on()` / `.off()` / `.toggle()` | `(*Led).On()` / `.Off()` / `.Toggle()` | ユーザーLEDを制御 |
| `newButtons()` | `wio.NewButtons()` | ボタンA/B/Cと5方向スイッチをプルアップ入力として設定 |
| `Buttons.isPressed(button)` / `.waitPressed(button)` | `(*Buttons).IsPressed(button)` / `.WaitPressed(button)` | [`Button`](./lib/wio_terminal.dart) をポーリング、またはデバウンス付きでブロック待機 |
| `newBuzzer()` | `wio.NewBuzzer()` | ブザー（`machine.WIO_BUZZER`、TCC0 PWM）をトーン出力として設定 |
| `Buzzer.tone(freqHz)` / `.stop()` / `.beep(freqHz, durationMs)` | `(*Buzzer).Tone(freqHz)` / `.Stop()` / `.Beep(freqHz, durationMs)` | ブザーを鳴らす・止める |
| `newLightSensor()` | `wio.NewLightSensor()` | 照度センサー（`machine.WIO_LIGHT`）をアナログ入力として設定 |
| `LightSensor.read()` / `.readPercent()` | `(*LightSensor).Read()` / `.ReadPercent()` | 生値（0〜65535）または正規化値（0〜100）の明るさ |
| `newMicrophone()` | `wio.NewMicrophone()` | マイク（`machine.WIO_MIC`）をアナログ入力として設定 |
| `Microphone.read()` / `.readLevel(windowMs)` | `(*Microphone).Read()` / `.ReadLevel(windowMs)` | 瞬時サンプル、またはサンプリング窓での振幅（peak-to-peak） |
| `newAccelerometer()` | `wio.NewAccelerometer()` | I2C1 + LIS3DHTR（アドレス0x18、±2G）を設定 |
| `Accelerometer.update()` | `(*Accelerometer).Update()` | 3軸をまとめて読み取りキャッシュする |
| `.x()`/`.y()`/`.z()`、`.xMilliG()`/`.yMilliG()`/`.zMilliG()` | `.X()`/`.Y()`/`.Z()`、`.XMilliG()`/... | キャッシュ値（G またはミリG） |

使い方は `examples/hello_wioterminal`、注釈の仕組みは [docs/writing_bindings.ja.md](../../docs/writing_bindings.ja.md) を参照。

サンプルがチェックアウトからビルドできるよう、当面このパッケージは本リポジトリに置いています。
設計上はボードバインディングを分離可能なパッケージとして扱っており、将来別リポジトリに移す可能性があります。
