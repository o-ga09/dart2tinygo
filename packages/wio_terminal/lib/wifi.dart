/// dart2tinygo binding for the Wio Terminal's Wi-Fi module (RTL8720DN).
///
/// A separate library (and Go sub-package, `go/wifi`) from
/// `wio_terminal.dart` so that a program that doesn't `import` this file
/// doesn't pull `net/http` and the RTL8720DN driver into its build; see
/// `docs/writing_bindings.md`.
///
/// Requires RTL8720DN firmware 2.1.2 or later; see
/// https://wiki.seeedstudio.com/Wio-Terminal-Network-Overview/. Building a
/// program that uses `httpGet`/`httpPost` needs a larger goroutine stack
/// than TinyGo's default — pass `-stack-size=4KB` to the `tinygo build` /
/// `tinygo flash` step.
@GoImport('github.com/o-ga09/dart2tinygo/packages/wio_terminal/go/wifi',
    alias: 'wiowifi')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

/// Probes and initializes the RTL8720DN. Does not connect to an access
/// point yet; call [WiFi.connect].
@GoName('wiowifi.NewWiFi')
external WiFi newWiFi();

/// The Wio Terminal's Wi-Fi module. Obtain one with [newWiFi].
@GoType('*wiowifi.WiFi')
class WiFi {
  WiFi._();

  /// Joins the given access point. Returns whether it succeeded.
  @GoName('Connect')
  external bool connect(String ssid, String password);

  /// Whether the last [connect] call succeeded and [disconnect] hasn't
  /// been called since.
  @GoName('IsConnected')
  external bool isConnected();

  /// The assigned IPv4 address, or `''` if not connected.
  @GoName('IPAddress')
  external String ipAddress();

  /// Leaves the access point.
  @GoName('Disconnect')
  external void disconnect();

  /// Fetches [url] and returns the response body as text, or `''` on
  /// failure.
  @GoName('HttpGet')
  external String httpGet(String url);

  /// Posts [body] to [url] with [contentType] and returns the response
  /// body as text, or `''` on failure.
  @GoName('HttpPost')
  external String httpPost(String url, String contentType, String body);
}
