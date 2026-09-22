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
| `newIrSender()` | `wio.NewIrSender()` | 赤外線LED（`machine.WIO_IR`、TCC4 PWMキャリア）をNEC送信用に設定 |
| `IrSender.sendNec(address, command)` / `.sendRaw32(code)` | `(*IrSender).SendNEC(...)` / `.SendRaw32(...)` | NEC赤外線コードを送信 |
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
| `serialAvailable()` | `wio.SerialAvailable()` | USB CDCシリアル接続で現在バッファされているバイト数 |
| `serialReadLine()` | `wio.SerialReadLine()` | USB CDCシリアルから `'\n'` 区切りの1行を読むまでブロック |

`lib/sd.dart`（別ライブラリ、`import 'package:wio_terminal/sd.dart';`）は microSD バインディングを提供する。`wio_terminal.dart` には含めず分離しているのは、使わないプログラムまで `tinygo.org/x/tinyfs/fatfs` の cgo による FAT 実装を巻き込まないようにするため：

| Dart | Go | 用途 |
| --- | --- | --- |
| `mountSdCard()` | `wiosd.MountSdCard()` | SPI2 + カード検出ピンを設定しFATファイルシステムをマウント |
| `SdCard.isInserted()` | `(*SdCard).IsInserted()` | カードが物理的に挿入されているか |
| `SdCard.exists(path)` | `(*SdCard).Exists(path)` | `path` がカード上に存在するか |
| `SdCard.readText(path)` / `.writeText(path, text)` / `.appendText(path, text)` | `(*SdCard).ReadText(path)` / `.WriteText(...)` / `.AppendText(...)` | テキストファイルの読み書き（読み取り失敗時は `''`） |
| `SdCard.readBytes(path)` / `.writeBytes(path, data)` | `(*SdCard).ReadBytes(path)` / `.WriteBytes(...)` | バイト列の読み書き（`List<int>` / `[]byte`） |

`lib/wifi.dart`（`import 'package:wio_terminal/wifi.dart';`）はWi-Fiバインディングを提供する。こちらも `wio_terminal.dart` には含めず分離しているのは、使わないプログラムまで `net/http` とRTL8720DNドライバを巻き込まないようにするため。RTL8720DNファームウェア2.1.2以降が必要。`httpGet`/`httpPost` を呼ぶプログラムをビルドするには `tinygo build`/`tinygo flash -stack-size=4KB`（デフォルトより大きいgoroutineスタック）が必要：

| Dart | Go | 用途 |
| --- | --- | --- |
| `newWiFi()` | `wiowifi.NewWiFi()` | RTL8720DNをプローブして初期化 |
| `WiFi.connect(ssid, password)` / `.isConnected()` / `.disconnect()` | `(*WiFi).Connect(...)` / `.IsConnected()` / `.Disconnect()` | アクセスポイントへの接続/切断 |
| `WiFi.ipAddress()` | `(*WiFi).IPAddress()` | 割り当てられたIPv4アドレス（未接続時は`''`） |
| `WiFi.httpGet(url)` / `.httpPost(url, contentType, body)` | `(*WiFi).HttpGet(url)` / `.HttpPost(...)` | `net/http` 経由のシンプルなHTTPリクエスト、レスポンスボディをテキストで返す |

`lib/pins.dart`（`import 'package:wio_terminal/pins.dart';`）は40ピンヘッダー／Groveポートのピン割り当てを提供する。`tinygo_machine` 自身の `Pin` 型を共有しているため、`WioPins.d0` はそのまま `tinygo_machine` の `configure`/`high`/`low`/`newAdc`/`newPwm` で使える：

| Dart | Go | 用途 |
| --- | --- | --- |
| `WioPins.d0`...`.d8` | `wio.D0`...`D8` | 40ピンヘッダーのデジタルピン（Groveデジタルポート `D0`/`D1` も含む） |
| `WioPins.a0`...`.a8` | `wio.A0`...`A8` | 40ピンヘッダーのアナログピン（Groveアナログポート `A0`/`A1` も含む） |

`lib/hid.dart`（`import 'package:wio_terminal/hid.dart';`）はUSB HIDキーボード/マウスを提供する。`wio_terminal.dart` には含めていないのは、`machine/usb/hid/keyboard`/`.../mouse` を import するだけでそのUSB HIDディスクリプタが（それぞれの `init()` により）有効化され、`tinygo flash` が使うオートリセットを含むUSB CDCの挙動に影響し得るため。デバイスモードのみ（TinyGoはUSBホストをサポートしない）：

| Dart | Go | 用途 |
| --- | --- | --- |
| `newKeyboard()` | `wiohid.NewKeyboard()` | USB HIDキーボードインタフェースへのハンドル |
| `Keyboard.write(text)` / `.press(keycode)` | `(*Keyboard).Write(text)` / `.Press(keycode)` | テキストを入力、または生のHIDキーコードをpress-and-release |
| `newMouse()` | `wiohid.NewMouse()` | USB HIDマウスインタフェースへのハンドル |
| `Mouse.move(dx, dy)` / `.click()` | `(*Mouse).Move(dx, dy)` / `.Click()` | カーソル移動、または左ボタンをクリック |

使い方は `examples/hello_wioterminal`、注釈の仕組みは [docs/writing_bindings.ja.md](../../docs/writing_bindings.ja.md) を参照。

サンプルがチェックアウトからビルドできるよう、当面このパッケージは本リポジトリに置いています。
設計上はボードバインディングを分離可能なパッケージとして扱っており、将来別リポジトリに移す可能性があります。
