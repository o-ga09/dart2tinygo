// Package wio is the TinyGo runtime half of the dart2tinygo `wio_terminal`
// binding. The Dart side (`lib/wio_terminal.dart`) declares these entry
// points with @GoName so the transpiler can call them; keep the two in sync.
package wio

import (
	"image/color"
	"machine"

	"tinygo.org/x/drivers/ili9341"
	"tinygo.org/x/tinyfont"
	"tinygo.org/x/tinyfont/freemono"
)

var (
	black = color.RGBA{R: 0, G: 0, B: 0, A: 255}
	white = color.RGBA{R: 255, G: 255, B: 255, A: 255}
)

// Display is the Wio Terminal's built-in 320x240 ILI9341 LCD.
type Display struct {
	dev *ili9341.Device
}

// NewDisplay configures SPI3 and the LCD control pins, clears the screen to
// black in landscape orientation, and turns the backlight on.
func NewDisplay() *Display {
	machine.SPI3.Configure(machine.SPIConfig{
		SCK:       machine.LCD_SCK_PIN,
		SDO:       machine.LCD_SDO_PIN,
		SDI:       machine.LCD_SDI_PIN,
		Frequency: 40000000,
	})

	dev := ili9341.NewSPI(
		machine.SPI3,
		machine.LCD_DC,
		machine.LCD_SS_PIN,
		machine.LCD_RESET,
	)
	dev.Configure(ili9341.Config{})
	dev.SetRotation(ili9341.Rotation270)
	dev.FillScreen(black)

	machine.LCD_BACKLIGHT.Configure(machine.PinConfig{Mode: machine.PinOutput})
	machine.LCD_BACKLIGHT.High()

	return &Display{dev: dev}
}

// Clear fills the whole screen with black.
func (d *Display) Clear() {
	d.dev.FillScreen(black)
}

// DrawText draws text in white with its baseline at (x, y) pixels from the
// top-left corner of the landscape screen.
func (d *Display) DrawText(x, y int, text string) {
	tinyfont.WriteLine(d.dev, &freemono.Bold12pt7b, int16(x), int16(y), text, white)
}

// Width returns the screen width in pixels at the current rotation.
func (d *Display) Width() int {
	w, _ := d.dev.Size()
	return int(w)
}

// Height returns the screen height in pixels at the current rotation.
func (d *Display) Height() int {
	_, h := d.dev.Size()
	return int(h)
}

// FillScreen fills the whole screen with c.
func (d *Display) FillScreen(c Color) {
	d.dev.FillScreen(c.rgba())
}

// SetBacklight turns the LCD backlight on or off.
func (d *Display) SetBacklight(on bool) {
	machine.LCD_BACKLIGHT.Set(on)
}

// SetRotation rotates the screen clockwise by r degrees (0/90/180/270; any
// other value is treated as 0). Width/Height swap between the 0/180 and
// 90/270 cases.
func (d *Display) SetRotation(r int) {
	switch r {
	case 90:
		d.dev.SetRotation(ili9341.Rotation90)
	case 180:
		d.dev.SetRotation(ili9341.Rotation180)
	case 270:
		d.dev.SetRotation(ili9341.Rotation270)
	default:
		d.dev.SetRotation(ili9341.Rotation0)
	}
}
