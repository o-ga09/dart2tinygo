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

  /// The screen width in pixels at the current rotation.
  @GoName('Width')
  external int width();

  /// The screen height in pixels at the current rotation.
  @GoName('Height')
  external int height();

  /// Fills the whole screen with [color].
  @GoName('FillScreen')
  external void fillScreen(Color color);

  /// Turns the LCD backlight on or off.
  @GoName('SetBacklight')
  external void setBacklight(bool on);

  /// Rotates the screen clockwise by [degrees] (0/90/180/270; any other
  /// value is treated as 0). Width/height swap between the 0/180 and
  /// 90/270 cases.
  @GoName('SetRotation')
  external void setRotation(int degrees);

  /// Sets a single pixel to [color].
  @GoName('DrawPixel')
  external void drawPixel(int x, int y, Color color);

  /// Draws a straight line from ([x0], [y0]) to ([x1], [y1]) in [color].
  @GoName('DrawLine')
  external void drawLine(int x0, int y0, int x1, int y1, Color color);

  /// Draws the outline of a [w] x [h] rectangle with its top-left corner at
  /// ([x], [y]), in [color]. Coordinates outside the screen are silently
  /// ignored.
  @GoName('DrawRect')
  external void drawRect(int x, int y, int w, int h, Color color);

  /// Fills a [w] x [h] rectangle with its top-left corner at ([x], [y]), in
  /// [color].
  @GoName('FillRect')
  external void fillRect(int x, int y, int w, int h, Color color);

  /// Draws the outline of a circle centered at ([x], [y]) with radius [r],
  /// in [color].
  @GoName('DrawCircle')
  external void drawCircle(int x, int y, int r, Color color);

  /// Draws a filled circle centered at ([x], [y]) with radius [r], in
  /// [color].
  @GoName('FillCircle')
  external void fillCircle(int x, int y, int r, Color color);

  /// Draws [text] in [color] (FreeMono Bold 12pt) with its baseline at
  /// ([x], [y]).
  @GoName('DrawTextColor')
  external void drawTextColor(int x, int y, String text, Color color);

  /// Draws [text] in [color] with its baseline at ([x], [y]), at the given
  /// point [size] (9/12/18/24; any other value falls back to 12).
  @GoName('DrawTextSize')
  external void drawTextSize(int x, int y, String text, Color color, int size);

  /// The rendered width of [text] in pixels, at the given point [size]
  /// (9/12/18/24; any other value falls back to 12).
  @GoName('TextWidth')
  external int textWidth(String text, int size);
}

/// An opaque 24-bit RGB color for the LCD. Created with [rgb].
@GoType('wio.Color')
class Color {
  Color._();
}

/// Creates a [Color] from 8-bit red/green/blue components (values outside
/// 0-255 are truncated).
@GoName('wio.RGB')
external Color rgb(int r, int g, int b);

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

/// Configures the three top buttons (A/B/C) and the 5-way switch as pull-up
/// inputs, and returns a handle to poll them.
@GoName('wio.NewButtons')
external Buttons newButtons();

/// One of the Wio Terminal's digital inputs: the three top buttons and the
/// 5-way switch's five directions.
@GoType('wio.Button')
enum Button {
  @GoName('wio.ButtonA')
  a,
  @GoName('wio.ButtonB')
  b,
  @GoName('wio.ButtonC')
  c,
  @GoName('wio.SwitchUp')
  up,
  @GoName('wio.SwitchDown')
  down,
  @GoName('wio.SwitchLeft')
  left,
  @GoName('wio.SwitchRight')
  right,
  @GoName('wio.SwitchPress')
  press,
}

/// The three top buttons and the 5-way switch. Obtain one with [newButtons].
@GoType('*wio.Buttons')
class Buttons {
  Buttons._();

  /// Whether [button] is currently held down.
  @GoName('IsPressed')
  external bool isPressed(Button button);

  /// Polls until [button] is pressed, debounced.
  @GoName('WaitPressed')
  external void waitPressed(Button button);
}

/// Configures the built-in buzzer (`machine.WIO_BUZZER`) for PWM output and
/// returns a handle to control it.
@GoName('wio.NewBuzzer')
external Buzzer newBuzzer();

/// The Wio Terminal's built-in buzzer. Obtain one with [newBuzzer].
@GoType('*wio.Buzzer')
class Buzzer {
  Buzzer._();

  /// Starts (or retunes) a continuous tone at [freqHz], until [stop].
  @GoName('Tone')
  external void tone(int freqHz);

  /// Silences the buzzer.
  @GoName('Stop')
  external void stop();

  /// Sounds [freqHz] for [durationMs] milliseconds, then stops.
  @GoName('Beep')
  external void beep(int freqHz, int durationMs);
}

/// Configures the built-in ambient light sensor (`machine.WIO_LIGHT`) as an
/// analog input and returns a handle to read it.
@GoName('wio.NewLightSensor')
external LightSensor newLightSensor();

/// The Wio Terminal's built-in ambient light sensor. Obtain one with
/// [newLightSensor].
@GoType('*wio.LightSensor')
class LightSensor {
  LightSensor._();

  /// The raw sample (0-65535).
  @GoName('Read')
  external int read();

  /// The raw sample normalized to 0-100.
  @GoName('ReadPercent')
  external int readPercent();
}

/// Configures the built-in microphone (`machine.WIO_MIC`) as an analog
/// input and returns a handle to read it.
@GoName('wio.NewMicrophone')
external Microphone newMicrophone();

/// The Wio Terminal's built-in microphone. Obtain one with [newMicrophone].
@GoType('*wio.Microphone')
class Microphone {
  Microphone._();

  /// An instantaneous raw sample (0-65535).
  @GoName('Read')
  external int read();

  /// Samples continuously for [windowMs] milliseconds and returns the
  /// peak-to-peak amplitude (0-65535), a simple loudness estimate.
  @GoName('ReadLevel')
  external int readLevel(int windowMs);
}

/// Configures I2C1 and the built-in 3-axis accelerometer LIS3DHTR (address
/// 0x18) at a +-2G range, and returns a handle to read it.
@GoName('wio.NewAccelerometer')
external Accelerometer newAccelerometer();

/// The Wio Terminal's built-in 3-axis accelerometer. Obtain one with
/// [newAccelerometer].
@GoType('*wio.Accelerometer')
class Accelerometer {
  Accelerometer._();

  /// Reads all three axes at once and caches the result for [x]/[y]/[z] and
  /// [xMilliG]/[yMilliG]/[zMilliG]. A failed read leaves the previous
  /// cached values in place (the underlying Go error has no annotation to
  /// surface it).
  @GoName('Update')
  external void update();

  /// The most recent [update] reading, in G.
  @GoName('X')
  external double x();

  /// The most recent [update] reading, in G.
  @GoName('Y')
  external double y();

  /// The most recent [update] reading, in G.
  @GoName('Z')
  external double z();

  /// The most recent [update] reading, in milli-G.
  @GoName('XMilliG')
  external int xMilliG();

  /// The most recent [update] reading, in milli-G.
  @GoName('YMilliG')
  external int yMilliG();

  /// The most recent [update] reading, in milli-G.
  @GoName('ZMilliG')
  external int zMilliG();
}
