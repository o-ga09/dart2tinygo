package wio

import (
	"machine"

	"tinygo.org/x/drivers/lis3dh"
)

// Accelerometer is the Wio Terminal's built-in 3-axis accelerometer
// LIS3DHTR, on machine.I2C1 (SDA/SCL = machine.WIO_LIS3DH_SDA/SCL, address
// 0x18).
type Accelerometer struct {
	dev                       lis3dh.Device
	xMicroG, yMicroG, zMicroG int32
}

// NewAccelerometer configures I2C1 and the LIS3DHTR at a +-2G range.
func NewAccelerometer() *Accelerometer {
	machine.I2C1.Configure(machine.I2CConfig{
		SDA: machine.WIO_LIS3DH_SDA,
		SCL: machine.WIO_LIS3DH_SCL,
	})
	dev := lis3dh.New(machine.I2C1)
	dev.Configure()
	dev.SetRange(lis3dh.RANGE_2_G)
	return &Accelerometer{dev: dev}
}

// Update reads all three axes at once (in micro-G) and caches the result
// for X/Y/Z and XMilliG/YMilliG/ZMilliG. lis3dh.ReadAcceleration returns a
// Go error, which the annotation machinery has no way to surface (#17); a
// failed read simply leaves the previous cached values in place.
func (a *Accelerometer) Update() {
	x, y, z, err := a.dev.ReadAcceleration()
	if err != nil {
		return
	}
	a.xMicroG, a.yMicroG, a.zMicroG = x, y, z
}

// X returns the most recent Update reading, in G.
func (a *Accelerometer) X() float64 { return float64(a.xMicroG) / 1e6 }

// Y returns the most recent Update reading, in G.
func (a *Accelerometer) Y() float64 { return float64(a.yMicroG) / 1e6 }

// Z returns the most recent Update reading, in G.
func (a *Accelerometer) Z() float64 { return float64(a.zMicroG) / 1e6 }

// XMilliG returns the most recent Update reading, in milli-G.
func (a *Accelerometer) XMilliG() int { return int(a.xMicroG / 1000) }

// YMilliG returns the most recent Update reading, in milli-G.
func (a *Accelerometer) YMilliG() int { return int(a.yMicroG / 1000) }

// ZMilliG returns the most recent Update reading, in milli-G.
func (a *Accelerometer) ZMilliG() int { return int(a.zMicroG / 1000) }
