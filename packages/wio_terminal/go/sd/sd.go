// Package sd is the TinyGo runtime half of the dart2tinygo `wio_terminal`
// microSD binding (Dart side: `lib/sd.dart`, imported as `wiosd`). Kept as
// its own Go sub-package (still inside the wio_terminal/go module) so an
// example that doesn't use the SD card doesn't pull tinyfs/fatfs's cgo FAT
// implementation into its build.
package sd

import (
	"io"
	"machine"
	"os"

	"tinygo.org/x/drivers/sdcard"
	"tinygo.org/x/tinyfs/fatfs"
)

// SdCard is the Wio Terminal's microSD slot (machine.SPI2,
// SDCARD_SS_PIN/SDCARD_DET_PIN), mounted as a FAT filesystem.
type SdCard struct {
	dev sdcard.Device
	fs  *fatfs.FATFS
}

// MountSdCard configures SPI2 and the card-detect pin, then mounts the FAT
// filesystem on the card. Panics if no card is present or mounting fails —
// the annotation machinery has no way to surface a Go error from a
// constructor (#19); check IsInserted first if that's a concern.
func MountSdCard() *SdCard {
	machine.SDCARD_DET_PIN.Configure(machine.PinConfig{Mode: machine.PinInputPullup})

	machine.SPI2.Configure(machine.SPIConfig{
		SCK:       machine.SDCARD_SCK_PIN,
		SDO:       machine.SDCARD_SDO_PIN,
		SDI:       machine.SDCARD_SDI_PIN,
		Frequency: 4000000,
	})
	dev := sdcard.New(machine.SPI2, machine.SDCARD_SCK_PIN, machine.SDCARD_SDO_PIN, machine.SDCARD_SDI_PIN, machine.SDCARD_SS_PIN)
	if err := dev.Configure(); err != nil {
		panic("wiosd: SD card not detected: " + err.Error())
	}

	fs := fatfs.New(&dev)
	fs.Configure(&fatfs.Config{})
	if err := fs.Mount(); err != nil {
		panic("wiosd: mount failed: " + err.Error())
	}

	return &SdCard{dev: dev, fs: fs}
}

// IsInserted reports whether a card is physically present (SDCARD_DET_PIN,
// active low).
func (s *SdCard) IsInserted() bool {
	return !machine.SDCARD_DET_PIN.Get()
}

// Exists reports whether path exists on the card.
func (s *SdCard) Exists(path string) bool {
	_, err := s.fs.Stat(path)
	return err == nil
}

// ReadText returns the whole contents of path as a string, or "" on
// failure (not found, read error, ...).
func (s *SdCard) ReadText(path string) string {
	data := s.ReadBytes(path)
	if data == nil {
		return ""
	}
	return string(data)
}

// WriteText replaces path's contents with text, creating it if needed.
// Fails silently, matching ReadText's "" on failure.
func (s *SdCard) WriteText(path, text string) {
	s.WriteBytes(path, []byte(text))
}

// AppendText appends text to path, creating it if needed.
func (s *SdCard) AppendText(path, text string) {
	f, err := s.fs.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_APPEND)
	if err != nil {
		return
	}
	defer f.Close()
	f.Write([]byte(text))
}

// ReadBytes returns the whole contents of path, or nil on failure.
func (s *SdCard) ReadBytes(path string) []byte {
	f, err := s.fs.Open(path)
	if err != nil {
		return nil
	}
	defer f.Close()
	data, err := io.ReadAll(f)
	if err != nil {
		return nil
	}
	return data
}

// WriteBytes replaces path's contents with data, creating it if needed.
func (s *SdCard) WriteBytes(path string, data []byte) {
	f, err := s.fs.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC)
	if err != nil {
		return
	}
	defer f.Close()
	f.Write(data)
}
