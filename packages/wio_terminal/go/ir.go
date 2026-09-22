package wio

import (
	"machine"
	"time"
)

// irTCC is the TCC peripheral used to generate the 38kHz IR carrier on
// machine.WIO_IR (PB31): per the atsamd51 pin/timer mapping table, PB31
// (PB30's odd sibling) is TCC4/WO[1], confirmed against the installed
// TinyGo 0.42 source. A separate peripheral from the buzzer's TCC0, so the
// two don't fight over a shared period.
var irTCC = machine.TCC4

const irCarrierHz = 38000

// IrSender drives the infrared emitter LED (machine.WIO_IR) with a 38kHz
// carrier, NEC protocol only. tinygo.org/x/drivers/irremote only has a NEC
// *receiver*; there's no ready-made sender, so this bit-bangs the NEC
// timings (mark/space durations) directly, using the TCC's PWM output for
// the carrier itself rather than toggling the pin at 38kHz in software.
type IrSender struct {
	channel uint8
}

// NewIrSender configures the IR LED pin for PWM output, off until SendNEC
// or SendRaw32 is called.
func NewIrSender() *IrSender {
	irTCC.Configure(machine.PWMConfig{Period: uint64(1e9) / irCarrierHz})
	channel, err := irTCC.Channel(machine.WIO_IR)
	if err != nil {
		panic("wio: IR sender PWM channel unavailable: " + err.Error())
	}
	s := &IrSender{channel: channel}
	s.carrierOff()
	return s
}

func (s *IrSender) carrierOn() {
	irTCC.Set(s.channel, irTCC.Top()/3) // ~33% duty, typical for an IR LED
}

func (s *IrSender) carrierOff() {
	irTCC.Set(s.channel, 0)
}

func (s *IrSender) mark(us int) {
	s.carrierOn()
	time.Sleep(time.Duration(us) * time.Microsecond)
}

func (s *IrSender) space(us int) {
	s.carrierOff()
	time.Sleep(time.Duration(us) * time.Microsecond)
}

// SendRaw32 sends code as a 32-bit NEC frame: a 9ms mark + 4.5ms space
// header, then all 32 bits (bit 0 first, matching irremote.Data.Code's own
// bit order — a 562.5µs mark followed by a 562.5µs space for 0 or a
// 1687.5µs space for 1), then a trailing 562.5µs mark.
func (s *IrSender) SendRaw32(code int) {
	s.mark(9000)
	s.space(4500)
	for i := 0; i < 32; i++ {
		s.mark(560)
		if (code>>uint(i))&1 == 1 {
			s.space(1690)
		} else {
			s.space(560)
		}
	}
	s.mark(560)
	s.carrierOff()
}

// SendNEC sends a standard 8-bit NEC frame built from address, ~address,
// command, ~command (matching how irremote.ReceiverDevice.decode reads
// Data.Code back apart).
func (s *IrSender) SendNEC(address, command int) {
	addr := uint32(address) & 0xFF
	cmd := uint32(command) & 0xFF
	code := addr | (^addr&0xFF)<<8 | cmd<<16 | (^cmd&0xFF)<<24
	s.SendRaw32(int(code))
}
