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
| `switch` | 実装済み（`int`/`String`/`bool` 式のみ。定数値の `case`、`default` に対応。連続する空の `case` は Go の `case a, b:` にまとめられる。`case ... when ...` ガードやデストラクチャリングパターンは未実装） |
| `print` | 実装済み（任意の `String` 式、または文字列補間） |
| 文字列補間 | `int` / `double` / `bool` / `String` の式が実装済み |
| カスケード `..` | 未実装 |
| `Duration` と `sleep` | 実装済み（`dart:io` の `sleep()`、`Duration(days:/hours:/minutes:/seconds:/milliseconds:/microseconds:)`） |
| 注釈によるバインディング | 実装済み（`@GoImport` / `@GoName` / `@GoType`。external なトップレベル関数と `@GoType` ローカル変数へのメソッド呼び出しで、戻り値は `int`/`double`/`bool`/`String`/`@GoType`、引数もそれらの型、Go 定数は `external` getter で参照。[`writing_bindings.ja.md`](./writing_bindings.ja.md) 参照）。呼び出し結果へのチェーンは未実装 |
| 共通 Go ランタイム（`dartrt`） | 実装済み（`packages/dart2tinygo/go/`。使ったときだけ import される）。`Mod` は `%`/`%=` に、`FormatDouble` は `double` の文字列補間に組み込み済み |
| `tinygo_machine`: LED、GPIO入出力、スリープ | 未実装 |

正確な変換ルールは [`docs/mapping.ja.md`](./mapping.ja.md) を、実例は
`packages/dart2tinygo/test/golden/`（`minimal_blink.dart` / `.go`）を参照。

## v0.2

| 機能 | 状態 |
| --- | --- |
| クラス（フィールド・コンストラクタ・メソッド、継承なし） | 未実装 |
| `List<T>` → Go スライス | 未実装 |
| `enum` | 未実装 |
| ビット演算、`int.toSigned(n)` | 未実装 |

## 将来（要望・需要次第）

- 継承・`mixin`・インターフェース
- ジェネリクス
- 例外
- `async` / `await`、`Timer`
- `Map`、クロージャの完全対応
