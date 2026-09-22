// wioterminal_demo: a menu-driven program that exercises every Wio Terminal
// binding in one build. Navigate with the 5-way switch (up/down), confirm
// with button A, and press button C to leave a running feature.
import 'dart:io';

import 'package:wio_terminal/wio_terminal.dart';
import 'package:wio_terminal/sd.dart';
import 'package:wio_terminal/wifi.dart';

void main() {
  final display = newDisplay();
  final led = newLed();
  final buttons = newButtons();
  final buzzer = newBuzzer();
  final light = newLightSensor();
  final mic = newMicrophone();
  final accel = newAccelerometer();
  final ir = newIrSender();

  var selected = 0;
  drawMenu(display, selected);

  while (true) {
    if (buttons.isPressed(Button.down)) {
      selected += 1;
      selected %= 7;
      drawMenu(display, selected);
      sleep(const Duration(milliseconds: 200));
    } else if (buttons.isPressed(Button.up)) {
      selected += 6;
      selected %= 7;
      drawMenu(display, selected);
      sleep(const Duration(milliseconds: 200));
    } else if (buttons.isPressed(Button.a)) {
      switch (selected) {
        case 0:
          runBlink(display, led, buttons);
        case 1:
          runMelody(display, buzzer, buttons);
        case 2:
          runLevels(display, light, mic, buttons);
        case 3:
          runSpiritLevel(display, accel, buttons);
        case 4:
          runIr(display, ir, buttons);
        case 5:
          runSdLog(display, buttons);
        case 6:
          runWifi(display, buttons);
      }
      drawMenu(display, selected);
      sleep(const Duration(milliseconds: 200));
    }
  }
}

String menuLabel(int index) {
  switch (index) {
    case 0:
      return 'Blink LED';
    case 1:
      return 'Play melody';
    case 2:
      return 'Light/mic levels';
    case 3:
      return 'Spirit level';
    case 4:
      return 'Send IR code';
    case 5:
      return 'SD card log';
    case 6:
      return 'Wi-Fi HTTP GET';
    default:
      return '';
  }
}

void drawMenu(Display display, int selected) {
  display.clear();
  display.drawTextColor(10, 20, 'Wio Terminal Demo', rgb(0, 255, 255));
  for (var i = 0; i < 7; i += 1) {
    var y = 55 + i * 22;
    if (i == selected) {
      display.drawTextColor(10, y, '> ' + menuLabel(i), rgb(0, 255, 0));
    } else {
      display.drawTextColor(10, y, '  ' + menuLabel(i), rgb(200, 200, 200));
    }
  }
  display.drawTextColor(
      10, 215, 'Up/Down: move  A: select', rgb(120, 120, 120));
}

void runBlink(Display display, Led led, Buttons buttons) {
  display.clear();
  display.drawText(10, 20, 'Blinking LED. Press C to go back.');
  while (!buttons.isPressed(Button.c)) {
    led.toggle();
    sleep(const Duration(milliseconds: 300));
  }
  led.off();
}

void runMelody(Display display, Buzzer buzzer, Buttons buttons) {
  display.clear();
  display.drawText(10, 20, 'Playing melody...');
  buzzer.beep(262, 200);
  buzzer.beep(294, 200);
  buzzer.beep(330, 200);
  buzzer.beep(349, 200);
  buzzer.beep(392, 400);
  display.drawText(10, 60, 'Done. Press A to continue.');
  buttons.waitPressed(Button.a);
}

void runLevels(
    Display display, LightSensor light, Microphone mic, Buttons buttons) {
  display.clear();
  display.drawText(10, 20, 'Light/mic levels. Press C to go back.');
  display.drawText(10, 100, 'Light');
  display.drawText(10, 180, 'Mic');
  while (!buttons.isPressed(Button.c)) {
    display.fillRect(10, 60, 300, 20, rgb(0, 0, 0));
    var lightWidth = light.readPercent() * 3;
    display.fillRect(10, 60, lightWidth, 20, rgb(255, 255, 0));

    display.fillRect(10, 140, 300, 20, rgb(0, 0, 0));
    // readLevel() is bounded to 0-65535, so dividing by 220 always stays
    // within the 300px bar (no clamp needed; a plain re-assignment like
    // `micWidth = 300` isn't supported in this Dart subset — see
    // docs/supported_features.md).
    var micWidth = mic.readLevel(50) ~/ 220;
    display.fillRect(10, 140, micWidth, 20, rgb(0, 255, 255));

    sleep(const Duration(milliseconds: 100));
  }
}

void runSpiritLevel(Display display, Accelerometer accel, Buttons buttons) {
  display.clear();
  display.drawText(10, 20, 'Spirit level. Press C to go back.');
  var centerX = 160;
  var centerY = 140;

  // Re-assigning a variable to an arbitrary new value isn't supported in
  // this Dart subset (only int/double compound assignment, see
  // docs/supported_features.md), so instead of tracking and erasing the
  // previous dot, each frame clears the whole circle and redraws it.
  while (!buttons.isPressed(Button.c)) {
    accel.update();
    var dx = (accel.x() * 50.0).round();
    var dy = (accel.y() * 50.0).round();
    display.fillCircle(centerX, centerY, 62, rgb(0, 0, 0));
    display.drawCircle(centerX, centerY, 60, rgb(100, 100, 100));
    display.fillCircle(centerX + dx, centerY - dy, 6, rgb(0, 255, 0));
    sleep(const Duration(milliseconds: 100));
  }
}

void runIr(Display display, IrSender ir, Buttons buttons) {
  display.clear();
  display.drawText(10, 20, 'Sending IR code (NEC 0x00 0x01)...');
  ir.sendNec(0, 1);
  display.drawText(10, 60, 'Sent. Press A to continue.');
  buttons.waitPressed(Button.a);
}

void runSdLog(Display display, Buttons buttons) {
  display.clear();
  display.drawText(10, 20, 'Insert a microSD card.');
  display.drawText(10, 50, 'Press A to log, C to cancel.');
  while (!buttons.isPressed(Button.a) && !buttons.isPressed(Button.c)) {
    sleep(const Duration(milliseconds: 50));
  }
  if (buttons.isPressed(Button.c)) {
    return;
  }
  var sd = mountSdCard();
  sd.appendText('demo_log.txt', 'wioterminal_demo checked in\n');
  display.clear();
  display.drawText(10, 20, 'Logged to demo_log.txt.');
  display.drawText(10, 50, 'Press A to continue.');
  buttons.waitPressed(Button.a);
}

void runWifi(Display display, Buttons buttons) {
  display.clear();
  display.drawText(10, 20, 'Connecting to Wi-Fi...');
  var wifi = newWiFi();
  // Edit these before running the Wi-Fi demo; with the placeholders below
  // connect() fails and the demo falls back to an error message instead of
  // attempting the HTTP GET.
  var ssid = 'YOUR_WIFI_SSID';
  var password = 'YOUR_WIFI_PASSWORD';
  var connected = wifi.connect(ssid, password);
  if (connected) {
    display.drawText(10, 50, 'Connected: ' + wifi.ipAddress());
    var body = wifi.httpGet('http://example.com');
    display.drawText(10, 80, 'HTTP GET done, see serial log for size.');
    print('GET returned ${body.length} bytes');
  } else {
    display.drawText(10, 50, 'Wi-Fi connect failed.');
    display.drawText(10, 80, 'Edit ssid/password in main.dart and retry.');
  }
  display.drawText(10, 110, 'Press A to continue.');
  buttons.waitPressed(Button.a);
}
