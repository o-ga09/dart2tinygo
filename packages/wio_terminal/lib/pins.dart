/// dart2tinygo binding for the Wio Terminal's 40-pin expansion header
/// (Raspberry Pi-compatible layout: D0-D8 / A0-A8) and the two Grove ports
/// on the back (Grove Digital/Analog = D0/A0, D1/A1).
///
/// Generic pin functionality (digital I/O, ADC, PWM) lives in
/// `package:tinygo_machine`; these are just the Wio Terminal pin
/// assignments, sharing `tinygo_machine`'s own [Pin] type so e.g.
/// `WioPins.d0.configure(PinMode.output)` or `newAdc(WioPins.a0)` work
/// directly.
@GoImport('github.com/o-ga09/dart2tinygo/packages/wio_terminal/go',
    alias: 'wio')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';
import 'package:tinygo_machine/tinygo_machine.dart';

/// The Wio Terminal's 40-pin header and Grove port pin assignments.
class WioPins {
  WioPins._();

  @GoName('wio.D0')
  external static Pin get d0;
  @GoName('wio.D1')
  external static Pin get d1;
  @GoName('wio.D2')
  external static Pin get d2;
  @GoName('wio.D3')
  external static Pin get d3;
  @GoName('wio.D4')
  external static Pin get d4;
  @GoName('wio.D5')
  external static Pin get d5;
  @GoName('wio.D6')
  external static Pin get d6;
  @GoName('wio.D7')
  external static Pin get d7;
  @GoName('wio.D8')
  external static Pin get d8;

  @GoName('wio.A0')
  external static Pin get a0;
  @GoName('wio.A1')
  external static Pin get a1;
  @GoName('wio.A2')
  external static Pin get a2;
  @GoName('wio.A3')
  external static Pin get a3;
  @GoName('wio.A4')
  external static Pin get a4;
  @GoName('wio.A5')
  external static Pin get a5;
  @GoName('wio.A6')
  external static Pin get a6;
  @GoName('wio.A7')
  external static Pin get a7;
  @GoName('wio.A8')
  external static Pin get a8;
}
