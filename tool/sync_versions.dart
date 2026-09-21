// Keeps the version constraints between this repository's own packages in
// lockstep with the release version.
//
// tagpr bumps `version:` in every pubspec listed in `.tagpr` (versionFile) and
// then runs this script (postVersionCommand) with TAGPR_NEXT_VERSION set, e.g.
// `v0.1.0`. Pub workspaces enforce constraints between members, so after
// bumping wio_terminal to 0.1.0 its `tinygo_annotations: ^0.0.1` must become
// `^0.1.0` or `dart pub get` fails. Run manually with:
//
//   dart tool/sync_versions.dart 0.1.0
import 'dart:io';

/// Packages whose constraints are rewritten wherever another member depends
/// on them. Everything in the workspace is versioned together.
const internalPackages = [
  'dart2tinygo',
  'tinygo_annotations',
  'tinygo_machine',
  'wio_terminal',
  'test_binding',
];

/// Pubspecs that may depend on an internal package.
const pubspecs = [
  'packages/dart2tinygo/pubspec.yaml',
  'packages/tinygo_annotations/pubspec.yaml',
  'packages/tinygo_machine/pubspec.yaml',
  'packages/wio_terminal/pubspec.yaml',
  'packages/dart2tinygo/test/fixtures/test_binding/pubspec.yaml',
  'examples/hello_wioterminal/pubspec.yaml',
];

void main(List<String> args) {
  var version = args.isNotEmpty
      ? args.first
      : Platform.environment['TAGPR_NEXT_VERSION'] ?? '';
  if (version.startsWith('v')) version = version.substring(1);
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
    stderr.writeln(
      'usage: dart tool/sync_versions.dart <x.y.z> '
      '(or set TAGPR_NEXT_VERSION); got "$version"',
    );
    exit(64);
  }

  final pattern = RegExp(
    '^(\\s+(?:${internalPackages.join('|')}):\\s*)\\^\\d+\\.\\d+\\.\\d+\\s*\$',
    multiLine: true,
  );
  for (final path in pubspecs) {
    final file = File(path);
    final before = file.readAsStringSync();
    final after = before.replaceAllMapped(pattern, (m) => '${m[1]}^$version');
    if (after != before) {
      file.writeAsStringSync(after);
      stdout.writeln('sync_versions: updated $path');
    }
  }
}
