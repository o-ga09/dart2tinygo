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
| `while (true) { ... }` | `for { ... }` |
| `x++` / `x--` | `x++` / `x--` |
| `print(<文字列>)` | `println(<文字列>)` — `fmt.Println` ではない（TinyGo で `fmt` を巻き込まないため） |
| `print('... $x ...')` | 文字列連結：`"... " + strconv.Itoa(x) + " ..."` |
| `sleep(Duration(milliseconds: n))` | `time.Sleep(n * time.Millisecond)`（`seconds`/`minutes`/`hours`/`days`/`microseconds` にも対応。複数指定時は加算） |

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
| 引数: `int` リテラル / `String` リテラル / `int` ローカル変数 | そのまま出力：型なし定数 / Go 文字列リテラル / 識別子 |

生成する `go.mod`：Dart パッケージに `go/go.mod` を同梱しているバインディングごとに
`require <module> v0.0.0` と `replace <module> => <ローカル絶対パス>` を出力し、
続けて `go mod tidy` を実行する。それ以外は `go mod tidy` に任せる。

## 数値の意味論（要決定）

- Dart の `int` は64ビット想定。Go 側で `int64` を使うか `int` を使うかは未決定。
- 32bit MCU では Go の `int` は32ビットになる点に注意（要検討）。
- dart2js（Flutter Web）ではビット演算が32ビットになるため、Flutter と共通コードを書く利用者向けの注意喚起を README に追加する必要がある（未着手）。
- 上記 v0.1 最小変換は `int` リテラルを Go の型なし定数として出力するだけ（`x := 0`）なので、この論点はまだ顕在化していない。より広い `int` 対応を入れる前に決定が必要。

## 型対応表（上記 v0.1 最小変換の範囲を超えては未定義）

| Dart | Go |
| --- | --- |
| （未定） | （未定） |

## 文字列補間（`int` は実装済み、それ以外は方針のみ）

- `fmt.Sprintf` は使わない。型に応じて `strconv` 等で連結し、TinyGo でのバイナリ肥大化を防ぐ。
- 実装済み：`int` 型の補間式を `strconv.Itoa` で変換。
- 未実装：`double` / `bool` / `String` および任意の式の補間。
