/// dart2tinygo binding for the Wio Terminal's microSD slot.
///
/// A separate library (and Go sub-package, `go/sd`) from
/// `wio_terminal.dart` so that a program that doesn't `import` this file
/// doesn't pull `tinygo.org/x/tinyfs/fatfs`'s cgo FAT implementation into
/// its build; see `docs/writing_bindings.md`.
@GoImport('github.com/o-ga09/dart2tinygo/packages/wio_terminal/go/sd',
    alias: 'wiosd')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

/// Configures SPI2 and the card-detect pin, then mounts the FAT filesystem
/// on the microSD card. Panics if no card is present or mounting fails;
/// check [SdCard.isInserted] first if that's a concern.
@GoName('wiosd.MountSdCard')
external SdCard mountSdCard();

/// The Wio Terminal's microSD slot, mounted as a FAT filesystem. Obtain one
/// with [mountSdCard].
@GoType('*wiosd.SdCard')
class SdCard {
  SdCard._();

  /// Whether a card is physically present (the card-detect pin).
  @GoName('IsInserted')
  external bool isInserted();

  /// Whether [path] exists on the card.
  @GoName('Exists')
  external bool exists(String path);

  /// The whole contents of [path] as a string, or `''` on failure (not
  /// found, read error, ...).
  @GoName('ReadText')
  external String readText(String path);

  /// Replaces [path]'s contents with [text], creating it if needed. Fails
  /// silently.
  @GoName('WriteText')
  external void writeText(String path, String text);

  /// Appends [text] to [path], creating it if needed.
  @GoName('AppendText')
  external void appendText(String path, String text);

  /// The whole contents of [path], or an empty list on failure.
  @GoName('ReadBytes')
  external List<int> readBytes(String path);

  /// Replaces [path]'s contents with [data], creating it if needed.
  @GoName('WriteBytes')
  external void writeBytes(String path, List<int> data);
}
