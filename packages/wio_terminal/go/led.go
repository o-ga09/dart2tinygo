package wio

import "machine"

// Led is the Wio Terminal's own user LED (blue, machine.LED = PA15). Generic
// GPIO belongs in tinygo_machine (#21); this only fixes the pin assignment
// and gives it a Wio-flavoured API.
type Led struct{ pin machine.Pin }

// NewLed configures the user LED as an output and returns a handle to
// control it.
func NewLed() *Led {
	pin := machine.LED
	pin.Configure(machine.PinConfig{Mode: machine.PinOutput})
	return &Led{pin: pin}
}

func (l *Led) On() { l.pin.High() }

func (l *Led) Off() { l.pin.Low() }

func (l *Led) Toggle() { l.pin.Set(!l.pin.Get()) }
