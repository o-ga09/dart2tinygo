# 対応言語機能

**Languages:** [English](./supported_features.md) | 日本語

言語機能を追加した PR では、必ずこの表を更新すること。

## v0.1

| 機能 | 状態 |
| --- | --- |
| 型: `int` | 実装済み（ローカル変数、リテラル、バインディングの戻り値。算術は未実装） |
| 型: `double` / `bool` / `String` | 一部対応：ローカル変数、リテラル、バインディングの戻り値・引数、（`bool` の）比較・論理演算子。算術や `String` 操作は未実装 |
| `var`、型推論 | 実装済み（最小構成：`var x = <リテラルかバインディング呼び出し>;`） |
| `final` / `const` ローカル変数 | 一部対応：キーワードは無視され、`var` と同じ初期化子なら `final`/`const` も受け付けて `x := ...` を出力する |
| トップレベル関数、`main` | 実装済み（最小構成：引数なしの `void main()` 単体のみ、他のトップレベル関数は不可） |
| `while` | 実装済み（最小構成：`while (true)` のみ、ネスト不可） |
| `if` / `else if` / `else` | 実装済み（各分岐はブロック。`while` の中や他の `if` の中へのネストは可、逆（`if` の中への `while` のネスト）は不可） |
| 比較（`==`/`!=`/`<`/`<=`/`>`/`>=`）・論理（`&&`/`\|\|`/`!`）演算子 | 実装済み（`==`/`!=` は同じ型の `int`/`double`/`bool`/`String` 同士、`<`/`<=`/`>`/`>=` は同じ型の `int`/`int` か `double`/`double`、`&&`/`\|\|`/`!` は `bool`） |
| `for` / `switch` | 未実装 |
| `print` | 実装済み（任意の `String` 式、または文字列補間） |
| 文字列補間 | `int` / `bool` / `String` の式は実装済み。`double` は未実装 |
| カスケード `..` | 未実装 |
| `Duration` と `sleep` | 実装済み（`dart:io` の `sleep()`、`Duration(days:/hours:/minutes:/seconds:/milliseconds:/microseconds:)`） |
| 注釈によるバインディング | 実装済み（`@GoImport` / `@GoName` / `@GoType`。external なトップレベル関数と `@GoType` ローカル変数へのメソッド呼び出しで、戻り値は `int`/`double`/`bool`/`String`/`@GoType`、引数もそれらの型、Go 定数は `external` getter で参照。[`writing_bindings.ja.md`](./writing_bindings.ja.md) 参照）。呼び出し結果へのチェーンは未実装 |
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
