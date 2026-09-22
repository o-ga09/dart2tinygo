# 対応言語機能

**Languages:** [English](./supported_features.md) | 日本語

言語機能を追加した PR では、必ずこの表を更新すること。

## v0.1

| 機能 | 状態 |
| --- | --- |
| 型: `int` | 実装済み（ローカル変数、リテラル、バインディングの戻り値、`+`/`-`/`*`/`~/`/`%`、単項 `-`、複合代入、`.toDouble()`） |
| 型: `double` | 実装済み（ローカル変数、リテラル、バインディングの戻り値、`+`/`-`/`*`/`/`、単項 `-`、複合代入、`.toInt()`/`.round()`、文字列補間） |
| 型: `bool` | 一部対応：ローカル変数、リテラル、バインディングの戻り値・引数、比較・論理演算子 |
| 型: `String` | 実装済み（ローカル変数、リテラル、バインディングの戻り値・引数、比較、`+` 連結、`.length`、`.codeUnits`、`.substring()`、`String.fromCharCodes()`） |
| 型: `List<int>` | 実装済み（Go の `[]byte` に対応 — [`mapping.ja.md`](./mapping.ja.md) の「List<int>」参照。リテラル、添字の読み書き、`.length`、`.add()`。`int` 以外の要素型は未実装） |
| `var`、型推論 | 実装済み（最小構成：`var x = <リテラルかバインディング呼び出し>;`） |
| `final` / `const` ローカル変数 | 一部対応：キーワードは無視され、`var` と同じ初期化子なら `final`/`const` も受け付けて `x := ...` を出力する |
| トップレベル関数、`main` | 実装済み — 引数なしの `void main()` 単体に加え、位置引数・`int`/`double`/`bool`/`String`/`List<int>`/`@GoType`/`void` の型・ブロックまたは式（`=>`）本体・`return`・再帰・前方参照を伴う任意個数のトップレベル関数。名前付き／省略可能／デフォルト値付き引数は未実装（[`mapping.ja.md`](./mapping.ja.md) 参照） |
| `while` | 実装済み（任意の `bool` 条件、例：`while (count < 10)`。ネスト可） |
| `for`（C スタイル） | 実装済み（`for (var i = <初期値>; cond; updater)`。宣言する変数1つ・updater1つに限定（Go の post-clause が単一の文のため）。`for-in` は未実装） |
| `break` / `continue` | 実装済み（ラベルなしのみ） |
| `x += y` / `-=` / `*=` | 実装済み（`int`/`int` か `double`/`double` のみ） |
| `x ~/= y` / `%=` | 実装済み（`int` のみ。`~/=` は `x /= y`、`%=` は `x = dartrt.Mod(x, y)`） |
| `x /= y` | 実装済み（`double` のみ — Dart の `/` は常に `double` を返すので、そもそも `int /= ...` は有効な Dart ではない。`int` は `~/=` を使う） |
| 算術 `a + b` / `-` / `*` / `/` / `~/` / `%` | 実装済み（`+`/`-`/`*` は同じ型の `int`/`int` か `double`/`double`、`+` は `String`/`String` も可、`~/`/`%` は `int`、`/` は `double`） |
| `int` ⇄ `double` 変換：`.toDouble()` / `.toInt()` / `.round()` | 実装済み（`.toDouble()` は `int` に、`.toInt()`/`.round()` は `double` に） |
| `if` / `else if` / `else` | 実装済み（各分岐はブロック。ループと `if` は自由にネスト可） |
| 比較（`==`/`!=`/`<`/`<=`/`>`/`>=`）・論理（`&&`/`\|\|`/`!`）演算子 | 実装済み（`==`/`!=` は同じ型の `int`/`double`/`bool`/`String` 同士、`<`/`<=`/`>`/`>=` は同じ型の `int`/`int` か `double`/`double`、`&&`/`\|\|`/`!` は `bool`） |
| `switch` | 実装済み（`int`/`String`/`bool`/ユーザー定義 `enum` 式のみ。定数値の `case`、`default` に対応。連続する空の `case` は Go の `case a, b:` にまとめられる。`case ... when ...` ガードやデストラクチャリングパターンは未実装） |
| `print` | 実装済み（任意の `String` 式、または文字列補間） |
| 文字列補間 | `int` / `double` / `bool` / `String` の式が実装済み |
| カスケード `..` | 実装済み。`@GoType` のバインディング値のみ対応（`newDisplay()..clear()..drawText(...)`）。各セクションは必ず素の `..method(args)` バインディング呼び出しでなければならず、文として、またはローカル変数の初期化子として使える |
| `enum` | 実装済み — ユーザー定義の enum（`enum Mode { off, on }`：`.index`、`.name`、`==`/`!=`、`switch` に対応）と、`@GoType`/`@GoName` によるバインディング enum（各値が既存の Go 識別子にマップされる。`static external` getter 定数と同様）。型パラメータ、`with`/`implements`、追加のフィールド・メソッド、値へのコンストラクタ引数は未対応 |
| `Duration` と `sleep` | 実装済み（`dart:io` の `sleep()`、`Duration(days:/hours:/minutes:/seconds:/milliseconds:/microseconds:)`） |
| 注釈によるバインディング | 実装済み（`@GoImport` / `@GoName` / `@GoType`。external なトップレベル関数、`@GoType` クラス自身の `external`／`@GoName` 付きコンストラクタ（`Pin(3)`）、`@GoType` のレシーバ — ローカル変数、または（チェーン。任意の深さ）別のバインディング呼び出し／コンストラクタの戻り値 — へのメソッド呼び出しで、戻り値は `int`/`double`/`bool`/`String`/`@GoType`、引数もそれらの型、Go 定数は `external` getter で参照。[`writing_bindings.ja.md`](./writing_bindings.ja.md) 参照） |
| 共通 Go ランタイム（`dartrt`） | 実装済み（`packages/dart2tinygo/go/`。使ったときだけ import される）。`Mod` は `%`/`%=` に、`FormatDouble` は `double` の文字列補間に組み込み済み |
| `tinygo_machine`: LED、GPIO入出力、ADC、PWM、スリープ | 実装済み — GPIO（`Pin.led`、`Pin(n)`、`configure(PinMode.output\|input)`、`high()`/`low()`/`toggle()`/`get()`）、ADC（`newAdc(pin)`、`.read()`）、PWM（`newPwm(pin, freqHz)`、`.setFrequency(freqHz)`、`.setDuty(percent)`）。ボード非依存で `wioterminal`/`pico`（PWMのみ `itsybitsy-m4` も）の `tinygo build` で確認済み — [`writing_bindings.ja.md`](./writing_bindings.ja.md) の「決定済み・未実装」参照 |
| `wio_terminal`: LCD文字表示/図形/色、ユーザーLED、ボタン/スイッチ、ブザー、照度/マイクADC、加速度センサー、赤外線送信 | 実装済み — `newDisplay()`/`.clear()`/`.drawText()` に加え `.width()`/`.height()`/`.fillScreen()`/`.setBacklight()`/`.setRotation()`/`.drawPixel\|Line\|Rect\|Circle()`/`.fillRect\|Circle()`/`.drawTextColor\|Size()`/`.textWidth()` と `rgb(r,g,b)` → `Color`、`newLed()`/`.on()`/`.off()`/`.toggle()`（`machine.LED`、青）、`newButtons()`/`.isPressed(button)`/`.waitPressed(button)`（ボタンA/B/C + 5方向スイッチ、プルアップ入力）、`newBuzzer()`/`.tone(freqHz)`/`.stop()`/`.beep(freqHz, durationMs)`（`machine.WIO_BUZZER`、TCC0 PWM）、`newLightSensor()`/`newMicrophone()`（`machine.WIO_LIGHT`/`WIO_MIC` ADC）、`newAccelerometer()`/`.update()`/`.x()`.../`.xMilliG()`...（I2C1経由のLIS3DHTR）、`newIrSender()`/`.sendNec()`/`.sendRaw32()`（`machine.WIO_IR`、TCC4 PWMキャリアによるNEC送信）。`tinygo build -target=wioterminal`（`examples/button_led`）で確認済み。[`writing_bindings.ja.md`](./writing_bindings.ja.md) の「このリポジトリにあるバインディング」参照 |
| `wio_terminal/sd`: microSD（FAT） | 実装済み — 他のプログラムのビルドを肥大化させないよう、別ライブラリ（`import 'package:wio_terminal/sd.dart';`）と別 Go サブパッケージ（`go/sd`、cgo の `tinygo.org/x/tinyfs/fatfs`）に分離。`mountSdCard()`/`.isInserted()`/`.exists()`/`.readText()`/`.writeText()`/`.appendText()`/`.readBytes()`/`.writeBytes()`。`dart2tinygo build` を通した end-to-end で `tinygo build -target=wioterminal` を確認済み。[`writing_bindings.ja.md`](./writing_bindings.ja.md) の「重い依存を別の Go サブパッケージに分離する」参照 |
| `wio_terminal/wifi`: Wi-Fi（RTL8720DN）+ HTTP | 実装済み — 別ライブラリ（`import 'package:wio_terminal/wifi.dart';`）と別 Go サブパッケージ（`go/wifi`、`net/http` + `netlink/probe` 経由の `tinygo.org/x/drivers/rtl8720dn`）。`newWiFi()`/`.connect()`/`.isConnected()`/`.disconnect()`/`.ipAddress()`/`.httpGet()`/`.httpPost()`。RTL8720DNファームウェア2.1.2以降と `tinygo build`/`flash` への `-stack-size=4KB` が必要。`dart2tinygo build` を通した end-to-end で `tinygo build -target=wioterminal` を確認済み。実アクセスポイントに対する動作は未検証（実機なし）。[`writing_bindings.ja.md`](./writing_bindings.ja.md) の「重い依存を別の Go サブパッケージに分離する」参照 |

正確な変換ルールは [`docs/mapping.ja.md`](./mapping.ja.md) を、実例は
`packages/dart2tinygo/test/golden/`（`minimal_blink.dart` / `.go`）を参照。

## v0.2

| 機能 | 状態 |
| --- | --- |
| クラス（フィールド・コンストラクタ・メソッド、継承なし） | 実装済み — `class Foo { ... }` は Go の `struct` + `NewFoo(...)` + ポインタレシーバのメソッドにマップされる（インスタンスは常に `*Foo`）。1 つの素の generative constructor（`this.field`／通常の位置引数のみ、initializer list 不可）、対応済みの型を持つフィールド（宣言時の初期化子は不可 — コンストラクタで設定する）、インスタンスメソッド（トップレベル関数と同じ規則）、フィールドアクセスと `this`／暗黙の `this`、インスタンスメソッド呼び出し、`==`/`!=`（同一性比較。Go 自身のポインタ `==` と同じ）に対応。`extends`/`implements`/`with`、クラス修飾子（`abstract`/`base`/`final`/`interface`/`mixin`/`sealed`）、ジェネリクス、`static`、getter/setter/演算子オーバーロード、nullable（`T?`）型、名前付き／const／factory コンストラクタは checker が拒否する — 詳細は [`mapping.ja.md`](./mapping.ja.md) の「クラス（継承なし）」参照 |
| `List<T>` → Go スライス | 未実装 |
| ビット演算、`int.toSigned(n)` | 未実装 |

## 将来（要望・需要次第）

- 継承・`mixin`・インターフェース
- ジェネリクス
- 例外
- `async` / `await`、`Timer`
- `Map`、クロージャの完全対応
