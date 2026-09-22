package tgm

import "machine"

// pwmPeripheral is the method set shared by every TinyGo chip family's PWM
// peripheral type (machine.TCC on atsamd51, the unexported pwmGroup type
// behind machine.PWM0..7 on rp2, ...). There is no such exported interface
// in the machine package itself — each target only ever has one concrete
// PWM type in scope — so this is defined here purely to let NewPWM walk a
// per-chip-family candidate list (pwmCandidates, in pwm_*.go) with common
// code.
type pwmPeripheral interface {
	Configure(machine.PWMConfig) error
	Channel(machine.Pin) (uint8, error)
	Top() uint32
	Set(channel uint8, value uint32)
}

// PWM drives a Pin with a configurable duty cycle at a fixed frequency.
type PWM struct {
	periph  pwmPeripheral
	channel uint8
}

// NewPWM configures p for PWM output at freqHz and returns a handle to
// control its duty cycle. It tries every PWM peripheral this chip family
// exposes (pwmCandidates) until one successfully claims p — unlike GPIO/ADC,
// no single peripheral type covers every pin on every chip family, so this
// is real per-chip-family, per-pin probing rather than a fixed mapping; see
// docs/writing_bindings.md. Panics if no candidate can drive p.
func NewPWM(p Pin, freqHz int) *PWM {
	var period uint64
	if freqHz > 0 {
		period = uint64(1e9) / uint64(freqHz)
	}
	pin := machine.Pin(p)
	for _, periph := range pwmCandidates() {
		if err := periph.Configure(machine.PWMConfig{Period: period}); err != nil {
			continue
		}
		channel, err := periph.Channel(pin)
		if err != nil {
			continue
		}
		return &PWM{periph: periph, channel: channel}
	}
	panic("tgm: no PWM peripheral available for this pin")
}

// SetDuty sets the duty cycle as a percentage (0-100); values outside that
// range are clamped.
func (p *PWM) SetDuty(percent int) {
	if percent < 0 {
		percent = 0
	} else if percent > 100 {
		percent = 100
	}
	p.periph.Set(p.channel, p.periph.Top()*uint32(percent)/100)
}
