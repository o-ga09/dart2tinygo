// Package hid is the TinyGo runtime half of the dart2tinygo `wio_terminal`
// USB HID binding (Dart side: `lib/hid.dart`, imported as `wiohid`). Kept
// as its own Go sub-package (still inside the wio_terminal/go module),
// since merely importing machine/usb/hid/keyboard or .../mouse enables
// that USB HID descriptor via their own package init() — which can affect
// USB CDC (serial) behaviour, including the auto-reset `tinygo flash`
// relies on — so a program that doesn't need HID shouldn't pay for it.
package hid

import (
	"machine/usb/hid/keyboard"
	"machine/usb/hid/mouse"
)

// Keyboard is the board's USB HID keyboard interface. Obtain one with
// NewKeyboard. USB host is not supported by TinyGo; this is device-mode
// only (the board acts as a keyboard plugged into a host).
type Keyboard struct{}

// NewKeyboard returns a handle to the board's USB HID keyboard interface.
func NewKeyboard() *Keyboard {
	return &Keyboard{}
}

// Write sends s as a sequence of keypresses (UTF-8, translated per the
// active layout). Errors (an unsupported codepoint, too many keys held at
// once, ...) are dropped — the annotation machinery has no way to surface
// them.
func (k *Keyboard) Write(s string) {
	keyboard.Port().Write([]byte(s))
}

// Press sends a press-and-release for the given HID keycode; see
// machine/usb/hid/keyboard's Keycode docs for the accepted ranges (ASCII,
// Unicode, modifier, system, media, and raw HID usage codes).
func (k *Keyboard) Press(keycode int) {
	keyboard.Port().Press(keyboard.Keycode(keycode))
}

// Mouse is the board's USB HID mouse interface. Obtain one with NewMouse.
type Mouse struct{}

// NewMouse returns a handle to the board's USB HID mouse interface.
func NewMouse() *Mouse {
	return &Mouse{}
}

// Move moves the mouse cursor by (dx, dy), clamped to -128..127 per the USB
// HID mouse report's field width.
func (m *Mouse) Move(dx, dy int) {
	mouse.Port().Move(dx, dy)
}

// Click presses and releases the left mouse button.
func (m *Mouse) Click() {
	mouse.Port().Click(mouse.Left)
}
