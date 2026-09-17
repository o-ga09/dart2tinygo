# バインディングの作り方

**Languages:** [English](./writing_bindings.md) | 日本語

ボード固有の対応は本体（`packages/dart2tinygo`）に入れず、別パッケージのバインディングとして提供します。
注釈の最終的な API は実装しながら決め、決定したらこのドキュメントに反映してください。現時点では未実装・未確定です。

## 想定する注釈（案、未実装）

- `@GoImport(path, alias: ...)`: ライブラリ単位で Go の import を宣言
- `@GoName(name)`: 関数・メソッド・定数の Go 側の対応先
- `@GoType(name)`: Dart の型と Go の型の対応
