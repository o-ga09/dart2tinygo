# tinygo_annotations (package)

**Languages:** English | [日本語](./README.ja.md)

Annotations (`@GoImport` / `@GoName` / `@GoType`) that let binding authors declare the Go-side counterparts from the Dart side.

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

See [docs/writing_bindings.md](../../docs/writing_bindings.md) for the full rules.
