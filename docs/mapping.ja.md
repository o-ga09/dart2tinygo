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
