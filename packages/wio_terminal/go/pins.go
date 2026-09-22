package wio

import (
	"machine"

	tgm "github.com/o-ga09/dart2tinygo/packages/tinygo_machine/go"
)

// The Wio Terminal's 40-pin expansion header (Raspberry Pi-compatible
// layout) and the two Grove ports on the back (Grove Digital/Analog =
// D0/A0, D1/A1). Generic pin functionality (digital I/O, ADC, PWM) lives in
// tinygo_machine (#21); these are just the Wio Terminal pin assignments,
// typed as tgm.Pin so they work directly with tinygo_machine's own
// Configure/High/Low/.../NewADC/NewPWM.
var (
	D0 = tgm.Pin(machine.D0)
	D1 = tgm.Pin(machine.D1)
	D2 = tgm.Pin(machine.D2)
	D3 = tgm.Pin(machine.D3)
	D4 = tgm.Pin(machine.D4)
	D5 = tgm.Pin(machine.D5)
	D6 = tgm.Pin(machine.D6)
	D7 = tgm.Pin(machine.D7)
	D8 = tgm.Pin(machine.D8)

	A0 = tgm.Pin(machine.A0)
	A1 = tgm.Pin(machine.A1)
	A2 = tgm.Pin(machine.A2)
	A3 = tgm.Pin(machine.A3)
	A4 = tgm.Pin(machine.A4)
	A5 = tgm.Pin(machine.A5)
	A6 = tgm.Pin(machine.A6)
	A7 = tgm.Pin(machine.A7)
	A8 = tgm.Pin(machine.A8)
)
