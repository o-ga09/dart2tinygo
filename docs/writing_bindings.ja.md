# バインディングの作り方

**Languages:** [English](./writing_bindings.md) | 日本語

ボード固有の対応は本体（`packages/dart2tinygo`）に入れず、別パッケージのバインディングとして提供します。
バインディングは、`package:tinygo_annotations` の注釈を付けた `external` 宣言だけを公開する Dart パッケージと、それを実装する Go パッケージの組です。トランスパイラはボードのコードを一切見ず、注釈だけを読みます。

## 注釈（決定済み・実装済み）

| 注釈 | 付ける場所 | 意味 |
| --- | --- | --- |
| `@GoImport(path, alias: ...)` | `library;` ディレクティブ | このライブラリの Go import。`alias` は省略可で、省略時は Go のデフォルト（パス末尾）がパッケージ名になる。 |
| `@GoName(name)` | `external` なトップレベル関数 | Go 側の呼び出し先を完全修飾で書く（例: `'wio.NewDisplay'`。接頭辞は `@GoImport` の alias）。 |
| `@GoName(name)` | `@GoType` クラスの `external` な無名コンストラクタ | トップレベル関数と全く同じく、Go 側の呼び出し先を完全修飾で書く（#21）。例: `Pin(n)` コンストラクタに対して `'tgm.Pin'`（Go の型変換）。`@GoType` の値は本来トップレベルのバインディング関数からしか作れないので、これはその構築版。戻り値には `Pin(3).high()` のように呼び出し結果と同様にチェーンできる（#30）。 |
| `@GoName(name)` | `@GoType` クラスの `external` なインスタンスメソッド | Go のメソッド名（例: `'DrawText'`）。レシーバに対して呼び出される。 |
| `@GoName(name)` | `external` なトップレベル getter、または `@GoType` クラスの `external static` getter | Go の定数・パッケージ変数を完全修飾で書く（例: `'wio.Red'`）。呼び出し括弧なしの識別子として出力される。 |
| `@GoName(name)` | `@GoType` enum の `enum` 定数 | Go の定数・パッケージ変数を完全修飾で書く（例: `'machine.LED'`）。上の `static external` getter と全く同じく、呼び出し括弧なしの識別子として出力される。 |
| `@GoType(name)` | クラス | このクラスの値の実体となる Go 型（例: `'*wio.Display'`）。トランスパイラ自身が生成することはなく、`@GoName` 関数の戻り値としてのみ現れる。 |
| `@GoType(name)` | `enum` | この enum をバインディング enum として宣言する：各定数は自分自身の `@GoName`（上）を持たなければならず、トランスパイラはこの enum 自体に対する Go 宣言を一切出力しない — 名前が付いた Go 識別子への素の参照のみ。`@GoType` を付けない素の `enum` はユーザー定義 enum で、トランスパイラが全体を生成する（`type E int` + 定数 + 名前テーブル）。詳細は `docs/mapping.ja.md` の「enum」を参照。 |

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

/// バインディング enum：各値が、上の `Color.red` が static getter で
/// 名指すのと同じように、既存の Go 識別子を名指す。
@GoType('wio.Pin')
enum Pin {
  @GoName('wio.LED')
  led,
  @GoName('wio.D0')
  d0,
}
```

```go
package wio

type Display struct{ /* ... */ }
type Color uint16
type Pin uint8

var Red = Color(0xF800)

const (
	LED Pin = iota
	D0
)

func NewDisplay() *Display                                  { /* ... */ }
func RGB(r, g, b int) Color                                 { /* ... */ }
func (d *Display) Clear()                                   { /* ... */ }
func (d *Display) DrawText(x, y int, text string, c Color)  { /* ... */ }
func (d *Display) Width() int                               { /* ... */ }
```

## 現時点でトランスパイラが呼び出せる形

- トップレベルのバインディング関数、`@GoType` クラス自身のバインディングコンストラクタ（`Pin(3)`、#21）、および `@GoType` の値を持つレシーバ — ローカル変数、または別のバインディング呼び出し／コンストラクタの戻り値（チェーン：`newDisplay().clear()`、`Pin(3).high()`、任意の深さまで）— へのバインディングメソッド呼び出し（`display.drawText(...)`）を、文として（void 以外の戻り値は捨てられる）、ローカル変数の初期化子として、別のバインディング呼び出しの引数として、または `print(...)` の中で呼べる。
- `@GoType` のバインディング値へのカスケード（`newDisplay()..clear()..drawText(...)`）を、文として、またはローカル変数の初期化子として使える。各カスケードのセクションは必ず素の `..method(args)` バインディング呼び出しでなければならない — v0.1 には自前のクラス・フィールドがないため、カスケードした getter/setter/添字セクションには対応する意味がない。
- 戻り値・ローカル変数の型: `int`、`double`、`bool`、`String`、`@GoType` クラス。`@GoType` には値型（`'wio.Color'`）もポインタ（`'*wio.Display'`）も書ける（文字列をそのまま出力するのでどちらも動く）。
- 引数: 上記の型のリテラル、ローカル変数、別のバインディング呼び出し、Go 定数の参照（`red`、`Color.red`、`Pin.led`）。Dart の `int` / `double` / `bool` / `String` 引数は Go の `int` / `float64` / `bool` / `string` に対応するので、Go 側のシグネチャもその型で宣言する（`uint8` が欲しい Go 側はバインディング内で変換する。トランスパイラはキャストを出力しない）。
- Go の定数・パッケージ変数: `external` なトップレベル getter、`external static` getter、または `@GoType` enum の定数に `@GoName` を付ける。インスタンス getter はバインディングにならない。値を返す Go メソッドは `external` メソッドとして公開する。

生成される Go は [`mapping.ja.md`](./mapping.ja.md) を参照。

## 決定済み・未実装（2026-09-22）

- **Go の多値返り値・`error`・ポインタ／値渡し・構造体の構築のために注釈は増やさない。**
  バインディングの Go 側がアダプタになる：そうした API を単一の値を返す関数・メソッドに
  包む（エラーは `panic` か `bool` の戻り値に正規化）。`wio.NewDisplay` が ILI9341/SPI の
  初期化をまとめているのと同じ。`@GoType` には `*` を含む正確な Go 型式を書く。
- **`tinygo_machine` の PWM（#44）は実装済み。** GPIO/ADC は `machine.go` 自体に定義された
  `machine.Pin`/`machine.ADC` のメソッドという、全 TinyGo ターゲット共通の単一の形が
  あるのに対し、PWM には共通の型が無い：チップファミリごとに異なるペリフェラル型を
  公開している（atsamd51 は `machine.TCC0..4`、rp2 は `machine.PWM0..7` など）。
  `NewPWM` は、TinyGo の `machine` パッケージ自体と同じようにチップファミリ別ファイル
  （`go/pwm_*.go`、`//go:build` タグで分岐）に置いた候補ペリフェラル一覧
  （`pwmCandidates`）を順に試し、`.Channel(pin)` が成功したものを使う。判定には
  `Configure`/`Channel`/`Top`/`Set` を要求する `pwmPeripheral` インタフェースを使うが、
  これは `machine` パッケージ自体には存在しない（あるターゲットからは常にひとつの
  具象 PWM 型しか見えないため）。`*machine.TCC` と rp2 の PWM 型はどちらも構造的にこれを
  満たす。`tinygo build` で `wioterminal`（atsamd51p19）、`pico`（rp2040）、
  `itsybitsy-m4`（atsamd51g19、TCC0〜2 のみ）を確認済み。実機での検証は未実施
  （デューティ比・周波数の正しさはコンパイルだけでは確認できない）。

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
- `packages/tinygo_machine`: TinyGo の `machine` パッケージに対するボード非依存バインディング。GPIO（`Pin.led` / `Pin(n)` / `configure` / `high` / `low` / `toggle` / `get`）、ADC（`newAdc` / `read`）、PWM（`newPwm` / `setDuty`）を実装済み（#21、#44）。`examples/blinky` が利用。
