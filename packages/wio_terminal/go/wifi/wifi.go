// Package wifi is the TinyGo runtime half of the dart2tinygo `wio_terminal`
// Wi-Fi binding (Dart side: `lib/wifi.dart`, imported as `wiowifi`). Kept as
// its own Go sub-package (still inside the wio_terminal/go module) so an
// example that doesn't use Wi-Fi doesn't pull `net/http` and the RTL8720DN
// driver into its build; see `docs/writing_bindings.md`.
package wifi

import (
	"github.com/o-ga09/dart2tinygo/packages/wio_terminal/go/wifi/httpx"
	"tinygo.org/x/drivers/netdev"
	"tinygo.org/x/drivers/netlink"
	"tinygo.org/x/drivers/netlink/probe"
)

// WiFi is the Wio Terminal's Wi-Fi module (RTL8720DN), for station-mode
// connections and simple HTTP requests. Requires RTL8720DN firmware 2.1.2
// or later; see https://wiki.seeedstudio.com/Wio-Terminal-Network-Overview/.
type WiFi struct {
	link      netlink.Netlinker
	dev       netdev.Netdever
	connected bool
}

// NewWiFi probes and initializes the RTL8720DN. Does not connect to an
// access point yet; call Connect.
func NewWiFi() *WiFi {
	link, dev := probe.Probe()
	return &WiFi{link: link, dev: dev}
}

// Connect joins the given access point. Returns whether it succeeded
// (the annotation machinery has no way to surface the underlying Go error).
func (w *WiFi) Connect(ssid, password string) bool {
	err := w.link.NetConnect(&netlink.ConnectParams{
		Ssid:       ssid,
		Passphrase: password,
	})
	w.connected = err == nil
	return w.connected
}

// IsConnected reports whether the last Connect call succeeded and
// Disconnect hasn't been called since.
func (w *WiFi) IsConnected() bool {
	return w.connected
}

// IPAddress returns the assigned IPv4 address, or "" if not connected.
func (w *WiFi) IPAddress() string {
	addr, err := w.dev.Addr()
	if err != nil {
		return ""
	}
	return addr.String()
}

// Disconnect leaves the access point.
func (w *WiFi) Disconnect() {
	w.link.NetDisconnect()
	w.connected = false
}

// HttpGet fetches url and returns the response body as text, or "" on
// failure (network error, non-readable body, ...). The whole request
// (connect, write, read) is bounded by httpx.DefaultTimeout (15s); on
// timeout it returns "" instead of blocking forever.
func (w *WiFi) HttpGet(url string) string {
	return httpx.Get(url, httpx.DefaultTimeout)
}

// HttpPost posts body to url with the given content type and returns the
// response body as text, or "" on failure or after the same 15s timeout
// as HttpGet.
func (w *WiFi) HttpPost(url, contentType, body string) string {
	return httpx.Post(url, contentType, body, httpx.DefaultTimeout)
}
