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
  external void drawText(int x, int y, String text);
}
```

```go
package wio

type Display struct{ /* ... */ }

func NewDisplay() *Display                     { /* ... */ }
func (d *Display) Clear()                      { /* ... */ }
func (d *Display) DrawText(x, y int, text string) { /* ... */ }
```

## 現時点でトランスパイラが呼び出せる形

- トップレベルのバインディング関数を、文として、またはローカル変数の初期化子として呼ぶ（`final display = newDisplay();`）。ローカル変数に入れられるのは `@GoType` の値か `int` のみ。
- `@GoType` の値を持つローカル変数に対するバインディングメソッド呼び出し（`display.drawText(...)`）。呼び出し結果に直接つなげる形（`newDisplay().clear()`）は未対応。
- 引数: `int` リテラル、`String` リテラル、`int` のローカル変数。Dart の `int` 引数は Go の `int`、`String` は `string` に対応する。

生成される Go は [`mapping.ja.md`](./mapping.ja.md) を参照。

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
