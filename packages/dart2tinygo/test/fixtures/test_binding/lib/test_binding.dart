/// Fake binding for tests. There is no Go runtime behind it (no `go/`
/// directory), so the generated `go.mod` must not get a `replace` for it.
@GoImport('example.com/fake/runtime', alias: 'rt')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

@GoName('rt.NewWidget')
external Widget newWidget();

@GoName('rt.Beep')
external void beep(int times);

/// Non-void results: each of these must be storable in a local and usable
/// wherever an expression of that type is accepted.
@GoName('rt.ReadLevel')
external int readLevel();

@GoName('rt.IsReady')
external bool isReady();

@GoName('rt.Voltage')
external double voltage();

@GoName('rt.Label')
external String label();

/// A value-type `@GoType` (no `*`): constructed by a binding function and
/// passed by value.
@GoName('rt.RGB')
external Color rgb(int r, int g, int b);

/// A Go package-level constant/variable, referenced as a bare identifier.
@GoName('rt.Red')
external Color get red;

/// Missing `@GoName` on a constant getter: reported like a function.
external Color get unnamedColor;

@GoType('rt.Color')
class Color {
  Color._();
}

@GoType('rt.Button')
class Button {
  Button._();

  /// A Go constant exposed as a static getter (`Button.a` → `rt.ButtonA`).
  @GoName('rt.ButtonA')
  external static Button get a;

  @GoName('rt.ButtonB')
  external static Button get b;
}

@GoType('*rt.Widget')
class Widget {
  Widget._();

  @GoName('Show')
  external void show(int x, int y, String text);

  @GoName('Hide')
  external void hide();

  @GoName('Fill')
  external void fill(Color color);

  @GoName('Configure')
  external void configure(bool enabled, double gain, String name);

  @GoName('Press')
  external bool press(Button button);

  @GoName('Level')
  external int level();

  /// `List<int>` in and out — the SD-card/byte-I/O shape (see the
  /// `List<int>` section of `docs/mapping.md`): the Go side is `[]byte` on
  /// both ends.
  @GoName('ReadBytes')
  external List<int> readBytes(String path);

  @GoName('WriteBytes')
  external void writeBytes(String path, List<int> data);
}

/// Missing `@GoName`: the checker must point at the annotation, not at the
/// call site's syntax.
external void unnamed();

/// A binding enum (#31): each value maps onto an existing Go identifier via
/// `@GoName`, exactly like the `Button.a`/`Button.b` static getters above,
/// but declared with `enum` syntax instead of a `@GoType` class with
/// `external static` getters.
@GoType('rt.Pin')
enum Pin {
  @GoName('rt.LED')
  led,
  @GoName('rt.D0')
  d0,
}

/// A binding enum constant missing `@GoName`: reported like a missing
/// `@GoName` on a constant getter.
@GoType('rt.BadPin')
enum BadPin {
  unnamed,
}

@GoName('rt.High')
external void high(Pin pin);

/// A `@GoType` class with its own constructor (#21): the construction
/// counterpart of [newWidget] above, since a `@GoType` value is otherwise
/// only ever produced by a top-level binding function — see
/// `docs/writing_bindings.md`.
@GoType('rt.Gpio')
class Gpio {
  @GoName('rt.NewGpio')
  external Gpio(int n);

  @GoName('Value')
  external int value();
}

/// A `@GoType` class whose constructor is missing `@GoName`: reported like a
/// missing `@GoName` on a function.
@GoType('rt.BadGpio')
class BadGpio {
  external BadGpio(int n);
}
