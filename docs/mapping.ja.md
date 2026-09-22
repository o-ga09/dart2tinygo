# Dart → Go 変換ルール

**Languages:** [English](./mapping.md) | 日本語

変換ルールを決めたらここに記録すること。

## v0.1 最小変換（決定・実装済み）

対象範囲：トップレベルの `void main()` 単体、`int` 型ローカル変数、
`while (true)`、`print(...)`、`sleep(Duration(...))`
（`HANDOFF_dart2tinygo.md` §7 タスク2）。
`packages/dart2tinygo/lib/src/backend/generator.dart` に実装済み。

| Dart | Go |
| --- | --- |
| `void main() { ... }` | `func main() { ... }` |
| `var x = <int リテラル>;` | `x := <int リテラル>` |
| `while (true) { ... }` | `for { ... }`（一般の `while (cond)` は `for cond { ... }`） |
| `for (var i = <初期値>; cond; updater) { ... }` | `for i := <初期値>; cond; updater { ... }` — そのまま対応。宣言する変数1つ、条件1つ、updater1つに限定（Go の post-clause は単一の文のため） |
| `break` / `continue` | `break` / `continue` — ラベルなしのみ |
| `x++` / `x--` | `x++` / `x--`（int のみ） |
| `x += y` / `x -= y` / `x *= y` / `x /= y` | Go でも同じ記号。`x`/`y` は同じ型（`int` か `double`）でなければならない |
| `print(<文字列>)` | `println(<文字列>)` — `fmt.Println` ではない（TinyGo で `fmt` を巻き込まないため） |
| `print('... $x ...')` | 文字列連結：`"... " + strconv.Itoa(x) + " ..."` |
| `sleep(Duration(milliseconds: n))` | `time.Sleep(n * time.Millisecond)`（`seconds`/`minutes`/`hours`/`days`/`microseconds` にも対応。複数指定時は加算） |
| `if (cond) { ... } else if (cond2) { ... } else { ... }` | `if cond { ... } else if cond2 { ... } else { ... }` — そのまま対応、同じ形。各分岐は必ず `{ ... }` ブロック |
| `a == b` / `a != b` / `a < b` / `a <= b` / `a > b` / `a >= b` | Go でも同じ記号。両辺は同じ型でなければならない（`int`/`double` の暗黙変換はしない）。`<`/`<=`/`>`/`>=` はさらに `int`/`double` に限定 |
| `a && b` / `a \|\| b` / `!a` | Go でも同じ記号。オペランドは `bool` |
| `(expr)` | `(expr)` — 括弧はそのまま出力 |

生成コードで実際に使う場合のみ Go の import（`strconv`、`time`）を出力する。

## 注釈バインディング（決定・実装済み）

`@GoName` 宣言（[`writing_bindings.ja.md`](./writing_bindings.ja.md) 参照）への呼び出しは
Go の呼び出しに 1:1 で対応し、トランスパイラがラッパーを足すことはない。

| Dart | Go |
| --- | --- |
| バインディングライブラリの `@GoImport('pkg/path', alias: 'p')` | `import p "pkg/path"`（そのライブラリのバインディングを使った場合のみ。`alias` なしなら `import "pkg/path"`） |
| `final d = newDisplay();`（`newDisplay` が `@GoName('wio.NewDisplay')`） | `d := wio.NewDisplay()`（`final`/`var` の違いはなし。`@GoType` は Go 側の型推論に任せる） |
| `beep(3);`（`beep` が `@GoName('rt.Beep')`） | `rt.Beep(3)` |
| `d.drawText(10, 20, 'hi');`（`drawText` が `@GoName('DrawText')`） | `d.DrawText(10, 20, "hi")` |
| `final n = sensor.read();` / `var ok = isReady();`（`int` / `double` / `bool` / `String` / `@GoType` の戻り値） | `n := sensor.Read()` / `ok := rt.IsReady()`（型は Go の推論に任せる。void 以外の戻り値を文として使った場合は捨てられる） |
| `red` / `Button.a`（getter が `@GoName('rt.Red')` / `@GoName('rt.ButtonA')`） | `rt.Red` / `rt.ButtonA` — 呼び出しなしの識別子 |
| 引数: `int` / `double` / `bool` / `String` のリテラル、ローカル変数、バインディング呼び出し、Go 定数の参照 | そのまま出力：型なし定数 / 識別子 / 呼び出し / 識別子。キャストは出さないので、Go 側の引数型は `int` / `float64` / `bool` / `string` か `@GoType` そのものにする |

生成する `go.mod`：Dart パッケージに `go/go.mod` を同梱しているバインディングごとに
`require <module> v0.0.0` と `replace <module> => <ローカル絶対パス>` を出力し、
続けて `go mod tidy` を実行する。それ以外は `go mod tidy` に任せる。

## 数値の意味論（2026-09-22 決定。`int` リテラル以外は未実装）

- **`int` → Go の `int`**（プラットフォーム幅。SAMD51 などの 32bit MCU では 32bit で、32bit で桁あふれする）。
  理由：Dart 自身が Web（dart2js のビット演算は 32bit）でプラットフォーム依存の整数意味論を
  許容している前例があること、バインディングが境界ごとの変換なしに Go の慣用的な `int` を
  使えること、Cortex-M では 64bit 演算がソフトウェア実装になること。dart2js 利用者が知っている
  のと同じ注意書きを README に載せる。
- **`double` → `float64`**。サイズより正しさ。Dart に 32bit double の前例はなく、単精度 FPU 上で
  ソフト実装の double が遅いことより、精度が無言で落ちることの方が悪い。
- 整数リテラルは Go の型なし定数のまま（`x := 0`）。
- `~/` → Go の `/`（どちらも 0 方向への切り捨て）。`%` は異なる（Dart `-5 % 3 == 1`、Go は `-2`）
  ので下記ランタイムヘルパを経由する。

## 型対応表（2026-09-22 決定。「実装済」は現時点で存在するもの）

| Dart | Go | 状態 |
| --- | --- | --- |
| `int` | `int` | 実装済（リテラル／ローカル変数／バインディング戻り値） |
| `double` | `float64`。`double d = 2;` → `d := 2.0`（Go が `int` と推論しないように） | 実装済（リテラル／ローカル変数／バインディング戻り値。算術・補間は未実装） |
| `bool` | `bool` | 実装済（リテラル／ローカル変数／バインディング戻り値、比較・論理演算子、`if`） |
| `String` | `string`。`.length` → `utf8.RuneCountInString`（BMP 外では UTF-16 と UTF-8 で差が出る）。v0.1 では添字アクセスなし | 実装済（リテラル／ローカル変数／バインディング戻り値。操作は未実装） |
| `Duration` | `time.Duration`。リテラルでない `Duration(milliseconds: n)` → `time.Duration(n) * time.Millisecond` | 実装済（リテラル） |
| `List<T>` | `[]T`。`add` → `append`、`length` → `len`、添字はそのまま、`List.filled` → `make` + ループ。growable/fixed は区別しない | 決定（v0.2） |
| `enum` | `type E int` + `const ( ... iota )`。`.index` は値そのもの、`.name` は文字列テーブル | 決定（v0.2） |
| クラス（継承なし） | `struct` + `NewFoo(...)` + ポインタレシーバのメソッド。インスタンスは常に `*Foo`（Dart の参照意味論。`==` は同一性比較） | 決定（v0.2） |
| トップレベル関数 | `func`。位置引数のみ。名前付き／省略可能引数は checker が拒否 | 決定 |
| `if` / `else if` / `else` | そのまま対応。各分岐は必ずブロック（上の v0.1 の表を参照） | 実装済 |
| `while`（一般条件）/ `for`（宣言変数1つ、updater1つ）/ `break` / `continue` | そのまま対応。上の v0.1 の表を参照 | 実装済 |
| `for-in` / `switch` | `for-in` → `range`。Dart の `switch` は fallthrough しないので出力もしない | 決定 |
| カスケード `a..b()..c()` | 一時変数 + 文の列 | 決定 |
| `@GoType` クラス | 注釈に書いた Go 型式をそのまま | 実装済 |
| 継承・mixin・ジェネリクス・`T?`・`throw`/例外・`async` | checker が拒否 | 決定（将来） |

## 共通 Go ランタイム（`dartrt`、2026-09-22 決定、未実装）

Go の式一つで表せない意味論は、`packages/dart2tinygo/go/` の小さなボード非依存 Go モジュール
（module `github.com/o-ga09/dart2tinygo/packages/dart2tinygo/go`、import 名 `dartrt`）を経由する。
配布と接続はバインディングの `go/` と同じ規約（[`writing_bindings.ja.md`](./writing_bindings.ja.md)
参照）。使ったときだけ import される。最初の中身：`FormatDouble`（Dart は `1.0` と出すが Go の
`strconv.FormatFloat` は `1`）、`Mod`（Dart の `%`）。これは言語意味論でありボード知識ではないので、
本体にボード固有コードを入れない原則には反しない。

## 文字列補間（`int` / `bool` / `String` は実装済み、`double` は決定済み）

- `fmt.Sprintf` は使わない。型に応じて `strconv` 等で連結する（TinyGo のバイナリ肥大化を防ぐため）。
- 実装済み：`int` → `strconv.Itoa`、`bool` → `strconv.FormatBool`、`String` → そのまま。補間式はローカル変数に限らず、対応している値の式（リテラル、ローカル変数、バインディング呼び出し、Go 定数）なら何でもよい。`print(s)` も同様に任意の `String` 式を受け付ける。
- 決定：`double` → `dartrt.FormatDouble`（`dartrt` ランタイム待ち）。

## 生成する `go.mod`

- `go 1.25`（TinyGo 0.42 の下限）。`go mod tidy` が必要に応じて上げる。
- ツリー内 Go ランタイム（バインディング、`dartrt`）ごとに `require` + `replace` の組を 1 つ。
