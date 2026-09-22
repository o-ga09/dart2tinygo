package wio

import "image/color"

// Color is an opaque 24-bit RGB color for the LCD, created with RGB.
type Color struct {
	r, g, b uint8
}

// RGB creates a Color from 8-bit red/green/blue components (values outside
// 0-255 are truncated, matching a Go byte conversion).
func RGB(r, g, b int) Color {
	return Color{r: uint8(r), g: uint8(g), b: uint8(b)}
}

func (c Color) rgba() color.RGBA {
	return color.RGBA{R: c.r, G: c.g, B: c.b, A: 255}
}
