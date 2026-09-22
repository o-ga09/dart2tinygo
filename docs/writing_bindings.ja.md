# バインディングの作り方

**Languages:** [English](./writing_bindings.md) | 日本語

ボード固有の対応は本体（`packages/dart2tinygo`）に入れず、別パッケージのバインディングとして提供します。
バインディングは、`package:tinygo_annotations` の注釈を付けた `external` 宣言だけを公開する Dart パッケージと、それを実装する Go パッケージの組です。トランスパイラはボードのコードを一切見ず、注釈だけを読みます。

## 注釈（決定済み・実装済み）

| 注釈 | 付ける場所 | 意味 |
| --- | --- | --- |
| `@GoImport(path, alias: ...)` | `library;` ディレクティブ | このライブラリの Go import。`alias` は省略可で、省略時は Go のデフォルト（パス末尾）がパッケージ名になる。 |
| `@GoName(name)` | `external` なトップレベル関数 | Go 側の呼び出し先を完全修飾で書く（例: `'wio.NewDisplay'`。接頭辞は `@GoImport` の alias）。 |
| `@GoName(name)` | `@GoType` クラスの `external` なインスタンスメソッド | Go のメソッド名（例: `'DrawText'`）。レシーバに対して呼び出される。 |
| `@GoName(name)` | `external` なトップレベル getter、または `@GoType` クラスの `external static` getter | Go の定数・パッケージ変数を完全修飾で書く（例: `'wio.Red'`）。呼び出し括弧なしの識別子として出力される。 |
| `@GoType(name)` | クラス | このクラスの値の実体となる Go 型（例: `'*wio.Display'`）。トランスパイラ自身が生成することはなく、`@GoName` 関数の戻り値としてのみ現れる。 |

checker が呼び出しを受け付けるのは、`external` であり、`@GoName` を持ち、`@GoImport` 付きライブラリに属する、という 3 条件がそろった宣言だけです。欠けている場合は、どの注釈が足りないかをファイル・行番号付きで報告します。

```dart
@GoImport('github.com/o-ga09/dart2tinygo/packages/wio_terminal/go', alias: 'wio')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

@GoName('wio.NewDisplay')
external Display newDisplay();

@GoType('*wio.Display')
class Display {
  Display._();

  @GoName('Clear')
  external void clear();

  @GoName('DrawText')
  external void drawText(int x, int y, String text, Color color);

  @GoName('Width')
  external int width();
}

/// 値型：`*` なし、値渡し。
@GoType('wio.Color')
class Color {
  Color._();

  @GoName('wio.Red')
  external static Color get red;
}

@GoName('wio.RGB')
external Color rgb(int r, int g, int b);
```

```go
package wio

type Display struct{ /* ... */ }
type Color uint16

var Red = Color(0xF800)

func NewDisplay() *Display                                  { /* ... */ }
func RGB(r, g, b int) Color                                 { /* ... */ }
func (d *Display) Clear()                                   { /* ... */ }
func (d *Display) DrawText(x, y int, text string, c Color)  { /* ... */ }
func (d *Display) Width() int                               { /* ... */ }
```

## 現時点でトランスパイラが呼び出せる形

- トップレベルのバインディング関数と、`@GoType` の値を持つローカル変数へのバインディングメソッド呼び出し（`display.drawText(...)`）を、文として（void 以外の戻り値は捨てられる）、ローカル変数の初期化子として、別のバインディング呼び出しの引数として、または `print(...)` の中で呼べる。呼び出し結果に直接つなげる形（`newDisplay().clear()`）は未対応。
- 戻り値・ローカル変数の型: `int`、`double`、`bool`、`String`、`@GoType` クラス。`@GoType` には値型（`'wio.Color'`）もポインタ（`'*wio.Display'`）も書ける（文字列をそのまま出力するのでどちらも動く）。
- 引数: 上記の型のリテラル、ローカル変数、別のバインディング呼び出し、Go 定数の参照（`red`、`Color.red`）。Dart の `int` / `double` / `bool` / `String` 引数は Go の `int` / `float64` / `bool` / `string` に対応するので、Go 側のシグネチャもその型で宣言する（`uint8` が欲しい Go 側はバインディング内で変換する。トランスパイラはキャストを出力しない）。
- Go の定数・パッケージ変数: `external` なトップレベル getter か `external static` getter に `@GoName` を付ける。インスタンス getter はバインディングにならない。値を返す Go メソッドは `external` メソッドとして公開する。

生成される Go は [`mapping.ja.md`](./mapping.ja.md) を参照。

## 決定済み・未実装（2026-09-22）

- **Go の多値返り値・`error`・ポインタ／値渡し・構造体の構築のために注釈は増やさない。**
  バインディングの Go 側がアダプタになる：そうした API を単一の値を返す関数・メソッドに
  包む（エラーは `panic` か `bool` の戻り値に正規化）。`wio.NewDisplay` が ILI9341/SPI の
  初期化をまとめているのと同じ。`@GoType` には `*` を含む正確な Go 型式を書く。
- **enum：** Dart の `enum` に `@GoType('machine.Pin')`、各値に `@GoName('machine.D0')` を付けられる。
- **チェーンとカスケード**をバインディングの戻り値に対して許可
  （`newDisplay().clear()`、`newDisplay()..clear()..drawText(...)`）。
- `tinygo_machine` バインディングの最初の API は `Pin.led` / `Pin(n)` /
  `configure(PinMode.output | PinMode.input)` / `high()` / `low()` / `toggle()` / `get()`。
  `machine.LED` や `machine.PinConfig{...}` は最初のルールに従い Go 側で吸収する。

## Go ランタイムをバインディングに同梱する

Go モジュールはバインディングの `pubspec.yaml` と同じ階層の `go/` ディレクトリに置きます（モジュールパスはそのディレクトリのリポジトリ上のパス。例: `github.com/o-ga09/dart2tinygo/packages/wio_terminal/go`）。パッケージに `go/go.mod` があるバインディングを使うと、トランスパイラは生成する `go.mod` に

```
require <module> v0.0.0
replace <module> => /absolute/path/to/go
```

を出力し、`go mod tidy` を実行します。これによりモジュールを公開しなくてもチェックアウトからサンプルがビルドできます。同梱の `go/` がないバインディングは、通常の依存と同じく `go mod tidy` が解決します。

Dart 側の宣言と Go 側のシグネチャは手で同期してください。トランスパイラは突き合わせを行わないため、ずれは `tinygo build` のエラーとして現れます。

## このリポジトリにあるバインディング

- `packages/wio_terminal`: Seeed Wio Terminal（LCD への文字描画）。`examples/hello_wioterminal` が利用。
- `packages/tinygo_machine`: TinyGo の `machine` パッケージに対するボード非依存バインディング（予定、未実装）。
