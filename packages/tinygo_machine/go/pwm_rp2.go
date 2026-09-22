//go:build rp2040 || rp2350

package tgm

import "machine"

// pwmCandidates lists every PWM peripheral this rp2 chip exposes.
func pwmCandidates() []pwmPeripheral {
	return []pwmPeripheral{
		machine.PWM0, machine.PWM1, machine.PWM2, machine.PWM3,
		machine.PWM4, machine.PWM5, machine.PWM6, machine.PWM7,
	}
}
