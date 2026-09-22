/// dart2tinygo binding for the Seeed Wio Terminal.
///
/// Every declaration here is `external`: the Dart side only carries the
/// signatures plus `@GoName` / `@GoType` annotations, and the behaviour lives
/// in the TinyGo runtime package under `go/` (imported as `wio`).
@GoImport('github.com/o-ga09/dart2tinygo/packages/wio_terminal/go',
    alias: 'wio')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

/// Initialises the built-in 320x240 ILI9341 LCD (SPI3, landscape, backlight
/// on) and returns a handle for drawing on it.
@GoName('wio.NewDisplay')
external Display newDisplay();

/// The Wio Terminal's built-in LCD. Obtain one with [newDisplay].
@GoType('*wio.Display')
class Display {
  Display._();

  /// Fills the whole screen with black.
  @GoName('Clear')
  external void clear();

  /// Draws [text] in white with its baseline at ([x], [y]), in pixels from
  /// the top-left corner of the landscape screen.
  @GoName('DrawText')
  external void drawText(int x, int y, String text);
}

/// Configures the Wio Terminal's own user LED (blue) as an output and
/// returns a handle to control it.
@GoName('wio.NewLed')
external Led newLed();

/// The Wio Terminal's own user LED (blue). Obtain one with [newLed].
@GoType('*wio.Led')
class Led {
  Led._();

  @GoName('On')
  external void on();

  @GoName('Off')
  external void off();

  @GoName('Toggle')
  external void toggle();
}
