# tinygo_annotations (package)

**Languages:** [English](./README.md) | 日本語

[![pub package](https://img.shields.io/pub/v/tinygo_annotations.svg)](https://pub.dev/packages/tinygo_annotations)

バインディング作者が Dart 側から Go 側の対応先を宣言するための注釈（`@GoImport` / `@GoName` / `@GoType`）を提供するパッケージ。

```dart
@GoImport('github.com/you/runtime', alias: 'rt')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

@GoName('rt.NewWidget')
external Widget newWidget();

@GoType('*rt.Widget')
class Widget {
  @GoName('Show')
  external void show(int x, int y, String text);
}
```

詳細は [docs/writing_bindings.ja.md](../../docs/writing_bindings.ja.md) を参照。
