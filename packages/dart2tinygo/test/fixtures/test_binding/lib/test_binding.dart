/// Fake binding for tests. There is no Go runtime behind it (no `go/`
/// directory), so the generated `go.mod` must not get a `replace` for it.
@GoImport('example.com/fake/runtime', alias: 'rt')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

@GoName('rt.NewWidget')
external Widget newWidget();

@GoName('rt.Beep')
external void beep(int times);

@GoType('*rt.Widget')
class Widget {
  Widget._();

  @GoName('Show')
  external void show(int x, int y, String text);

  @GoName('Hide')
  external void hide();
}

/// Missing `@GoName`: the checker must point at the annotation, not at the
/// call site's syntax.
external void unnamed();
