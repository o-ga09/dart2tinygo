/// dart2tinygo binding for the Wio Terminal's USB HID keyboard and mouse.
///
/// A separate library (and Go sub-package, `go/hid`) from
/// `wio_terminal.dart`: merely importing `machine/usb/hid/keyboard` or
/// `.../mouse` enables that USB HID descriptor via their own package
/// `init()`, which can affect USB CDC (serial) behaviour, including the
/// auto-reset `tinygo flash` relies on — so a program that doesn't `import`
/// this file doesn't pay for it. See `docs/writing_bindings.md`.
///
/// USB host is not supported by TinyGo; this is device-mode only (the
/// board acts as a keyboard/mouse plugged into a host).
@GoImport('github.com/o-ga09/dart2tinygo/packages/wio_terminal/go/hid',
    alias: 'wiohid')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

/// Returns a handle to the board's USB HID keyboard interface.
@GoName('wiohid.NewKeyboard')
external Keyboard newKeyboard();

/// The board's USB HID keyboard interface. Obtain one with [newKeyboard].
@GoType('*wiohid.Keyboard')
class Keyboard {
  Keyboard._();

  /// Sends [text] as a sequence of keypresses (UTF-8, translated per the
  /// active layout).
  @GoName('Write')
  external void write(String text);

  /// Sends a press-and-release for the given HID [keycode]; see
  /// `machine/usb/hid/keyboard`'s `Keycode` docs for the accepted ranges.
  @GoName('Press')
  external void press(int keycode);
}

/// Returns a handle to the board's USB HID mouse interface.
@GoName('wiohid.NewMouse')
external Mouse newMouse();

/// The board's USB HID mouse interface. Obtain one with [newMouse].
@GoType('*wiohid.Mouse')
class Mouse {
  Mouse._();

  /// Moves the mouse cursor by ([dx], [dy]), clamped to -128..127.
  @GoName('Move')
  external void move(int dx, int dy);

  /// Presses and releases the left mouse button.
  @GoName('Click')
  external void click();
}
