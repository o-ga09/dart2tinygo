import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart2tinygo/src/backend/generator.dart';
import 'package:dart2tinygo/src/checker/checker.dart';
import 'package:dart2tinygo/src/frontend/bindings.dart';
import 'package:dart2tinygo/src/frontend/resolve.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'dart2tinygo',
    'Converts a subset of Dart into TinyGo source code.',
  )
    ..addCommand(BuildCommand())
    ..addCommand(CheckCommand())
    ..addCommand(FlashCommand());

  try {
    final exitCode = await runner.run(arguments);
    exit(exitCode ?? 0);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  } on FrontendException catch (e) {
    stderr.writeln('dart2tinygo: $e');
    exit(1);
  }
}

/// `dart2tinygo check <entry.dart>`: only runs the checker — lists
/// unsupported syntax with file/line/reason without attempting to
/// generate Go.
class CheckCommand extends Command<int> {
  @override
  final name = 'check';

  @override
  final description = 'Report unsupported syntax without generating Go.';

  @override
  Future<int> run() async {
    final entry = _requireEntryArg(argResults!);
    if (entry == null) return 64;

    final result = await resolveEntryPoint(entry);
    final errors = checkEntryPoint(result);
    if (errors.isEmpty) {
      print('OK: $entry is within the v0.0.2 supported subset.');
      return 0;
    }
    for (final error in errors) {
      stderr.writeln(error);
    }
    return 1;
  }
}

/// `dart2tinygo build <entry.dart> [-o out_dir]`: checks, then converts
/// `main()` to a single-file Go program plus `go.mod`.
class BuildCommand extends Command<int> {
  BuildCommand() {
    argParser.addOption(
      'out',
      abbr: 'o',
      help: 'Output directory for the generated Go module.',
      defaultsTo: 'build',
    );
  }

  @override
  final name = 'build';

  @override
  final description = 'Generate a Go module from a Dart entry point.';

  @override
  Future<int> run() async {
    final entry = _requireEntryArg(argResults!);
    if (entry == null) return 64;
    final outDir = argResults!['out'] as String;
    return _build(entry, outDir);
  }
}

/// `dart2tinygo flash <entry.dart> --target=<tinygo-target> [-o out_dir] [--port=<port>]`:
/// runs the same steps as `build`, then hands the output
/// directory to `tinygo flash` with stdio inherited so TinyGo's own
/// progress/errors show.
class FlashCommand extends Command<int> {
  FlashCommand() {
    argParser
      ..addOption(
        'out',
        abbr: 'o',
        help: 'Output directory for the generated Go module.',
        defaultsTo: 'build',
      )
      ..addOption('target', help: 'TinyGo target board (required).')
      ..addOption('port', help: 'Serial port passed to `tinygo flash -port`.');
  }

  @override
  final name = 'flash';

  @override
  final description = 'Build a Dart entry point and flash it with TinyGo.';

  @override
  Future<int> run() async {
    final entry = _requireEntryArg(argResults!);
    if (entry == null) return 64;

    final target = argResults!['target'] as String?;
    if (target == null || target.isEmpty) {
      stderr.writeln('dart2tinygo: flash requires --target=<tinygo-target>');
      return 64;
    }

    final outDir = argResults!['out'] as String;
    final buildCode = await _build(entry, outDir);
    if (buildCode != 0) return buildCode;

    final port = argResults!['port'] as String?;
    return _tinygoFlash(outDir, target, port);
  }
}

/// Shared by `BuildCommand` and `FlashCommand`: checks, converts `main()` to
/// a single-file Go program plus `go.mod`, and `go mod tidy`s it if it pulls
/// in a binding's Go module.
Future<int> _build(String entry, String outDir) async {
  final result = await resolveEntryPoint(entry);
  final errors = checkEntryPoint(result);
  if (errors.isNotEmpty) {
    stderr.writeln('dart2tinygo: unsupported syntax in $entry:');
    for (final error in errors) {
      stderr.writeln('  $error');
    }
    return 1;
  }

  final generated = await generateGoFile(result);
  final formatted = await _gofmt(generated.source);

  final outDirAbs = Directory(outDir)..createSync(recursive: true);
  final mainGoPath = p.join(outDirAbs.path, 'main.go');
  File(mainGoPath).writeAsStringSync(formatted);

  final allLocalModules = _withTransitiveLocalModules(generated.localModules);

  final moduleName = _moduleNameFor(entry);
  final goModPath = p.join(outDirAbs.path, 'go.mod');
  File(goModPath).writeAsStringSync(
    _goModSource(moduleName, allLocalModules),
  );

  print('dart2tinygo: wrote $mainGoPath and $goModPath');

  if (allLocalModules.isNotEmpty) {
    // Bindings pull in third-party Go modules (drivers, fonts, ...), and
    // `tinygo build` needs them recorded in go.sum before it will build.
    final tidy = await _goModTidy(outDirAbs.path);
    if (tidy != 0) return tidy;
  }
  return 0;
}

Future<int> _tinygoFlash(String outDir, String target, String? port) async {
  try {
    final process = await Process.start(
      'tinygo',
      ['flash', '-target=$target', if (port != null) '-port=$port'],
      workingDirectory: outDir,
      mode: ProcessStartMode.inheritStdio,
    );
    return await process.exitCode;
  } on ProcessException {
    stderr.writeln(
      'dart2tinygo: `tinygo` was not found on PATH; install it from '
      'https://tinygo.org/getting-started/install/',
    );
    return 1;
  }
}

String? _requireEntryArg(ArgResults results) {
  if (results.rest.length != 1) {
    stderr.writeln('dart2tinygo: expected exactly one <entry.dart> argument');
    return null;
  }
  return results.rest.single;
}

/// Go module name for the generated `go.mod`. Named after the entry file,
/// except that `main.dart` takes its directory's name so `examples/foo/
/// main.dart` becomes module `foo` rather than the meaningless `main`.
String _moduleNameFor(String entryPath) {
  var base = p.basenameWithoutExtension(entryPath);
  if (base == 'main') {
    base = p.basename(p.dirname(p.absolute(entryPath)));
  }
  final sanitized = base.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  return sanitized.isEmpty ? 'app' : sanitized;
}

/// Expands [direct] (the modules directly `@GoImport`ed by the entry point)
/// with any further local modules each one's own `go.mod` `replace`s,
/// transitively — see `localModuleReplacesOf` in `frontend/bindings.dart`
/// for why this is needed at all.
List<GoLocalModule> _withTransitiveLocalModules(List<GoLocalModule> direct) {
  final byPath = {for (final module in direct) module.modulePath: module};
  final queue = List<GoLocalModule>.from(direct);
  while (queue.isNotEmpty) {
    final module = queue.removeLast();
    for (final found in localModuleReplacesOf(module)) {
      if (byPath.containsKey(found.modulePath)) continue;
      byPath[found.modulePath] = found;
      queue.add(found);
    }
  }
  return byPath.values.toList();
}

/// Binding runtimes that live in-tree next to their Dart package get a
/// `require` pinned to a placeholder version plus a `replace` to the local
/// directory, so the output builds from a checkout. Anything else is left
/// for `go mod tidy` to resolve.
String _goModSource(String moduleName, List<GoLocalModule> localModules) {
  final out = StringBuffer()
    ..writeln('module $moduleName')
    ..writeln()
    ..writeln('go 1.21');
  for (final module in localModules) {
    out
      ..writeln()
      ..writeln('require ${module.modulePath} v0.0.0')
      ..writeln()
      ..writeln('replace ${module.modulePath} => ${module.directory}');
  }
  return out.toString();
}

Future<int> _goModTidy(String dir) async {
  try {
    final process = await Process.start(
      'go',
      ['mod', 'tidy'],
      workingDirectory: dir,
      mode: ProcessStartMode.inheritStdio,
    );
    final code = await process.exitCode;
    if (code != 0) {
      stderr.writeln('dart2tinygo: `go mod tidy` failed in $dir');
    }
    return code;
  } on ProcessException {
    stderr.writeln(
      'dart2tinygo: `go` was not found on PATH; run `go mod tidy` in $dir '
      'before `tinygo build` (install: https://go.dev/doc/install)',
    );
    return 1;
  }
}

/// Best-effort `gofmt` on the generated code. Falls back to the
/// unformatted source if `gofmt` isn't on PATH, since board CI
/// environments may only have `tinygo`.
Future<String> _gofmt(String source) async {
  try {
    final process = await Process.start('gofmt', []);
    process.stdin.write(source);
    await process.stdin.close();
    final stdout =
        await process.stdout.transform(const SystemEncoding().decoder).join();
    final code = await process.exitCode;
    if (code == 0 && stdout.isNotEmpty) {
      return stdout;
    }
  } on ProcessException {
    // gofmt not available; ship unformatted source rather than failing the
    // build outright.
  }
  return source;
}
