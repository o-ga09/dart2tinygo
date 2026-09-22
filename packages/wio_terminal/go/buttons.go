package wio

import (
	"machine"
	"time"
)

// Button identifies one of the Wio Terminal's digital inputs: the three top
// buttons (A/B/C) and the 5-way switch's five directions. All are
// active-low pull-up inputs.
type Button uint8

const (
	ButtonA Button = iota
	ButtonB
	ButtonC
	SwitchUp
	SwitchDown
	SwitchLeft
	SwitchRight
	SwitchPress
)

func (b Button) pin() machine.Pin {
	switch b {
	case ButtonA:
		return machine.BUTTON_1
	case ButtonB:
		return machine.BUTTON_2
	case ButtonC:
		return machine.BUTTON_3
	case SwitchUp:
		return machine.WIO_5S_UP
	case SwitchDown:
		return machine.WIO_5S_DOWN
	case SwitchLeft:
		return machine.WIO_5S_LEFT
	case SwitchRight:
		return machine.WIO_5S_RIGHT
	default: // SwitchPress
		return machine.WIO_5S_PRESS
	}
}

var allButtons = [...]Button{
	ButtonA, ButtonB, ButtonC,
	SwitchUp, SwitchDown, SwitchLeft, SwitchRight, SwitchPress,
}

// Buttons is a handle to the three top buttons and the 5-way switch.
type Buttons struct{}

// NewButtons configures every button/switch pin as a pull-up input.
func NewButtons() *Buttons {
	for _, b := range allButtons {
		b.pin().Configure(machine.PinConfig{Mode: machine.PinInputPullup})
	}
	return &Buttons{}
}

// IsPressed reports whether btn is currently held down.
func (b *Buttons) IsPressed(btn Button) bool {
	return !btn.pin().Get()
}

// WaitPressed polls until btn is pressed, then waits out a debounce window.
func (b *Buttons) WaitPressed(btn Button) {
	for !b.IsPressed(btn) {
		time.Sleep(10 * time.Millisecond)
	}
	time.Sleep(20 * time.Millisecond)
}
