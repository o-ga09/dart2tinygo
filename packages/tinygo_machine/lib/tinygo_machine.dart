/// dart2tinygo binding for TinyGo's own `machine` package: GPIO and ADC,
/// board-agnostic across every target TinyGo supports.
///
/// Every declaration here is `external`: the Dart side only carries the
/// signatures plus `@GoName` / `@GoType` annotations, and the behaviour
/// lives in the TinyGo runtime package under `go/` (imported as `tgm`). See
/// `docs/writing_bindings.md`.
@GoImport('github.com/o-ga09/dart2tinygo/packages/tinygo_machine/go',
    alias: 'tgm')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

/// A single GPIO pin, identified by its raw TinyGo pin number.
@GoType('tgm.Pin')
class Pin {
  /// The pin numbered [n], e.g. `Pin(3)`.
  @GoName('tgm.Pin')
  external Pin(int n);

  /// The board's own user LED (every TinyGo target defines one).
  @GoName('tgm.LED')
  external static Pin get led;

  /// Sets this pin's direction. [PinMode.input] reads with an internal
  /// pull-up — the wiring TinyGo's own board packages assume for buttons.
  @GoName('Configure')
  external void configure(PinMode mode);

  @GoName('High')
  external void high();

  @GoName('Low')
  external void low();

  @GoName('Toggle')
  external void toggle();

  @GoName('Get')
  external bool get();
}

/// A [Pin]'s direction, passed to [Pin.configure].
@GoType('tgm.PinMode')
enum PinMode {
  @GoName('tgm.PinOutput')
  output,
  @GoName('tgm.PinInput')
  input,
}

/// Reads an analog voltage on a [Pin] configured as an analog input.
@GoType('*tgm.ADC')
class ADC {
  ADC._();

  /// The raw sample. TinyGo's own `machine.ADC.Get` scales to a 16-bit
  /// range (0-65535) regardless of the hardware's native resolution.
  @GoName('Read')
  external int read();
}

/// Configures [pin] as an analog input and returns a handle to read it.
@GoName('tgm.NewADC')
external ADC newAdc(Pin pin);

/// Drives a [Pin] with a configurable duty cycle at a fixed frequency.
///
/// Board-agnostic: probes every PWM peripheral this chip family exposes
/// (TCC0-4 on atsamd51, PWM0-7 on rp2, ...) for one that can claim the pin,
/// since — unlike GPIO/ADC — no single peripheral type covers every pin on
/// every chip family.
@GoType('*tgm.PWM')
class PWM {
  PWM._();

  /// Sets the duty cycle as a percentage (0-100); out-of-range values are
  /// clamped.
  @GoName('SetDuty')
  external void setDuty(int percent);
}

/// Configures [pin] for PWM output at [freqHz] and returns a handle to
/// control its duty cycle.
@GoName('tgm.NewPWM')
external PWM newPwm(Pin pin, int freqHz);
