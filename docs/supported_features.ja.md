# 対応言語機能

**Languages:** [English](./supported_features.md) | 日本語

言語機能を追加した PR では、必ずこの表を更新すること。

## v0.1

| 機能 | 状態 |
| --- | --- |
| 型: `int` / `double` / `bool` / `String` | 未実装 |
| `var` / `final` / `const`、型推論 | 未実装 |
| トップレベル関数、`main` | 未実装 |
| `if` / `for` / `while` / `switch` | 未実装 |
| 文字列補間、`print` | 未実装 |
| カスケード `..` | 未実装 |
| `Duration` と `sleep` | 未実装 |
| 注釈によるバインディング | 未実装 |
| `tinygo_machine`: LED、GPIO入出力、スリープ | 未実装 |

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
