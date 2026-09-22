// Package tgm is the TinyGo runtime half of the dart2tinygo `tinygo_machine`
// binding (the Dart side lives in `lib/tinygo_machine.dart`): a thin wrapper
// around TinyGo's own `machine` package. Every identifier this file wraps is
// defined for every TinyGo target, so nothing here is specific to any one
// board — see `docs/writing_bindings.md`.
package tgm

import "machine"

// Pin identifies a single GPIO pin, by its raw TinyGo pin number. A defined
// type over machine.Pin (not an alias), so this package's own Configure/
// High/Low/Toggle/Get can be attached to it.
type Pin machine.Pin

// LED is the board's own user LED.
var LED = Pin(machine.LED)

// PinMode selects a Pin's direction, passed to Configure.
type PinMode = machine.PinMode

// PinOutput drives the pin. PinInput reads it with an internal pull-up (the
// pin reads high when open, low when pulled to ground — the wiring TinyGo's
// own board packages assume for buttons).
const (
	PinOutput = machine.PinOutput
	PinInput  = machine.PinInputPullup
)

// Configure sets p's direction, wrapping the machine.PinConfig{...} struct
// literal Dart has no syntax for.
func (p Pin) Configure(mode PinMode) {
	machine.Pin(p).Configure(machine.PinConfig{Mode: mode})
}

func (p Pin) High() { machine.Pin(p).High() }

func (p Pin) Low() { machine.Pin(p).Low() }

// Toggle flips p's output level. Implemented via Get+Set rather than
// machine.Pin's own Toggle, which not every chip family defines (verified
// against TinyGo 0.42: present on atsamd51, absent on rp2).
func (p Pin) Toggle() {
	pin := machine.Pin(p)
	pin.Set(!pin.Get())
}

func (p Pin) Get() bool { return machine.Pin(p).Get() }

// ADC reads an analog voltage on a Pin configured as an analog input.
type ADC struct {
	pin machine.ADC
}

// NewADC configures p as an analog input and returns a handle to read it.
func NewADC(p Pin) *ADC {
	machine.InitADC()
	pin := machine.ADC{Pin: machine.Pin(p)}
	pin.Configure(machine.ADCConfig{})
	return &ADC{pin: pin}
}

// Read returns the raw sample (0-65535, like TinyGo's own machine.ADC.Get).
func (a *ADC) Read() int {
	return int(a.pin.Get())
}
