# wio_terminal (package)

**Languages:** English | [日本語](./README.ja.md)

[![pub package](https://img.shields.io/pub/v/wio_terminal.svg)](https://pub.dev/packages/wio_terminal)

dart2tinygo binding for the [Seeed Wio Terminal](https://wiki.seeedstudio.com/Wio-Terminal-Getting-Started/).
The Dart side (`lib/wio_terminal.dart`) is annotations only; the behaviour is
the TinyGo package in `go/` (`github.com/o-ga09/dart2tinygo/packages/wio_terminal/go`, imported as `wio`).

Currently provided:

| Dart | Go | Purpose |
| --- | --- | --- |
| `newDisplay()` | `wio.NewDisplay()` | Configure SPI3 + the ILI9341 LCD (landscape, backlight on, cleared to black) |
| `Display.clear()` | `(*Display).Clear()` | Fill the screen with black |
| `Display.drawText(x, y, text)` | `(*Display).DrawText(x, y, text)` | Draw white text (FreeMono Bold 12pt) with its baseline at (x, y) |
| `Display.width()` / `.height()` | `(*Display).Width()` / `.Height()` | Screen size in pixels at the current rotation |
| `Display.fillScreen(color)` | `(*Display).FillScreen(color)` | Fill the whole screen with a [`Color`](./lib/wio_terminal.dart) |
| `Display.setBacklight(on)` | `(*Display).SetBacklight(on)` | Turn the LCD backlight on/off |
| `Display.setRotation(degrees)` | `(*Display).SetRotation(degrees)` | Rotate the screen clockwise (0/90/180/270) |
| `Display.drawPixel/drawLine/drawRect/fillRect/drawCircle/fillCircle(..., color)` | `(*Display).DrawPixel/DrawLine/DrawRect/FillRect/DrawCircle/FillCircle(...)` | Shape drawing (via `tinygo.org/x/tinydraw`) |
| `Display.drawTextColor(x, y, text, color)` / `.drawTextSize(x, y, text, color, size)` / `.textWidth(text, size)` | `(*Display).DrawTextColor(...)` / `.DrawTextSize(...)` / `.TextWidth(...)` | Colored text, other point sizes (9/12/18/24), and measuring rendered width |
| `rgb(r, g, b)` | `wio.RGB(r, g, b)` | Build a [`Color`](./lib/wio_terminal.dart) from 8-bit components |
| `newIrSender()` | `wio.NewIrSender()` | Configure the IR LED (`machine.WIO_IR`, TCC4 PWM carrier) for NEC transmit |
| `IrSender.sendNec(address, command)` / `.sendRaw32(code)` | `(*IrSender).SendNEC(...)` / `.SendRaw32(...)` | Send a NEC infrared code |
| `newLed()` | `wio.NewLed()` | Configure the user LED (blue, `machine.LED`) as an output |
| `Led.on()` / `.off()` / `.toggle()` | `(*Led).On()` / `.Off()` / `.Toggle()` | Drive the user LED |
| `newButtons()` | `wio.NewButtons()` | Configure buttons A/B/C and the 5-way switch as pull-up inputs |
| `Buttons.isPressed(button)` / `.waitPressed(button)` | `(*Buttons).IsPressed(button)` / `.WaitPressed(button)` | Poll or block (debounced) on a [`Button`](./lib/wio_terminal.dart) |
| `newBuzzer()` | `wio.NewBuzzer()` | Configure the buzzer (`machine.WIO_BUZZER`, TCC0 PWM) for tone output |
| `Buzzer.tone(freqHz)` / `.stop()` / `.beep(freqHz, durationMs)` | `(*Buzzer).Tone(freqHz)` / `.Stop()` / `.Beep(freqHz, durationMs)` | Sound (or silence) the buzzer |
| `newLightSensor()` | `wio.NewLightSensor()` | Configure the light sensor (`machine.WIO_LIGHT`) as an analog input |
| `LightSensor.read()` / `.readPercent()` | `(*LightSensor).Read()` / `.ReadPercent()` | Raw (0-65535) or normalized (0-100) brightness |
| `newMicrophone()` | `wio.NewMicrophone()` | Configure the microphone (`machine.WIO_MIC`) as an analog input |
| `Microphone.read()` / `.readLevel(windowMs)` | `(*Microphone).Read()` / `.ReadLevel(windowMs)` | Instantaneous sample, or peak-to-peak amplitude over a sampling window |
| `newAccelerometer()` | `wio.NewAccelerometer()` | Configure I2C1 + the LIS3DHTR (address 0x18, +-2G) |
| `Accelerometer.update()` | `(*Accelerometer).Update()` | Read and cache all three axes |
| `.x()`/`.y()`/`.z()`, `.xMilliG()`/`.yMilliG()`/`.zMilliG()` | `.X()`/`.Y()`/`.Z()`, `.XMilliG()`/... | The cached reading, in G or milli-G |

`lib/sd.dart` (a separate library, `import 'package:wio_terminal/sd.dart';`) provides the microSD binding, kept out of `wio_terminal.dart` so a program that doesn't use it doesn't pull in `tinygo.org/x/tinyfs/fatfs`'s cgo FAT implementation:

| Dart | Go | Purpose |
| --- | --- | --- |
| `mountSdCard()` | `wiosd.MountSdCard()` | Configure SPI2 + the card-detect pin and mount a FAT filesystem |
| `SdCard.isInserted()` | `(*SdCard).IsInserted()` | Whether a card is physically present |
| `SdCard.exists(path)` | `(*SdCard).Exists(path)` | Whether `path` exists on the card |
| `SdCard.readText(path)` / `.writeText(path, text)` / `.appendText(path, text)` | `(*SdCard).ReadText(path)` / `.WriteText(...)` / `.AppendText(...)` | Text file I/O (`''` on a failed read) |
| `SdCard.readBytes(path)` / `.writeBytes(path, data)` | `(*SdCard).ReadBytes(path)` / `.WriteBytes(...)` | Byte file I/O (`List<int>` / `[]byte`) |

`lib/wifi.dart` (`import 'package:wio_terminal/wifi.dart';`) provides the Wi-Fi binding, likewise kept out of `wio_terminal.dart` so a program that doesn't use it doesn't pull `net/http` and the RTL8720DN driver into its build. Requires RTL8720DN firmware 2.1.2+; building a program that calls `httpGet`/`httpPost` needs `tinygo build`/`tinygo flash -stack-size=4KB` (a larger goroutine stack than the default):

| Dart | Go | Purpose |
| --- | --- | --- |
| `newWiFi()` | `wiowifi.NewWiFi()` | Probe and initialize the RTL8720DN |
| `WiFi.connect(ssid, password)` / `.isConnected()` / `.disconnect()` | `(*WiFi).Connect(...)` / `.IsConnected()` / `.Disconnect()` | Join/leave an access point |
| `WiFi.ipAddress()` | `(*WiFi).IPAddress()` | The assigned IPv4 address, or `''` if not connected |
| `WiFi.httpGet(url)` / `.httpPost(url, contentType, body)` | `(*WiFi).HttpGet(url)` / `.HttpPost(...)` | Simple HTTP requests (via `net/http`), response body as text |

See `examples/hello_wioterminal` for usage and [docs/writing_bindings.md](../../docs/writing_bindings.md) for how the annotations work.

This package lives in the main repository for now so the example builds from a
checkout; the design still treats board bindings as separable packages, and it
may move to its own repository later.
