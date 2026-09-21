import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart2tinygo/src/backend/generator.dart';
import 'package:dart2tinygo/src/checker/checker.dart';
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

/// `dart2tinygo check <entry.dart>`: only runs the checker, per
/// `HANDOFF_dart2tinygo.md` §4.1 — lists unsupported syntax with file/line/
/// reason without attempting to generate Go.
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
      print('OK: $entry is within the v0.1 minimal supported subset.');
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

    final result = await resolveEntryPoint(entry);
    final errors = checkEntryPoint(result);
    if (errors.isNotEmpty) {
      stderr.writeln('dart2tinygo: unsupported syntax in $entry:');
      for (final error in errors) {
        stderr.writeln('  $error');
      }
      return 1;
    }

    final generated = generateGoFile(result);
    final formatted = await _gofmt(generated.source);

    final outDirAbs = Directory(outDir)..createSync(recursive: true);
    final mainGoPath = p.join(outDirAbs.path, 'main.go');
    File(mainGoPath).writeAsStringSync(formatted);

    final moduleName = _moduleNameFor(entry);
    final goModPath = p.join(outDirAbs.path, 'go.mod');
    File(goModPath).writeAsStringSync('module $moduleName\n\ngo 1.21\n');

    print('dart2tinygo: wrote $mainGoPath and $goModPath');
    return 0;
  }
}

/// `dart2tinygo flash <entry.dart> -target=<tinygo-target>`: requires real
/// hardware, so it stays a stub outside the minimal-transpile scope
/// (`HANDOFF_dart2tinygo.md` §7, task 5).
class FlashCommand extends Command<int> {
  FlashCommand() {
    argParser.addOption('target', help: 'TinyGo target board.');
  }

  @override
  final name = 'flash';

  @override
  final description = 'Not implemented yet (requires real hardware).';

  @override
  Future<int> run() async {
    stderr.writeln(
      'dart2tinygo: `flash` is not implemented yet. Run `build` and flash '
      'the generated go.mod with `tinygo flash` directly for now.',
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

String _moduleNameFor(String entryPath) {
  final base = p.basenameWithoutExtension(entryPath);
  final sanitized = base.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  return sanitized.isEmpty ? 'app' : sanitized;
}

/// Best-effort `gofmt`, matching `HANDOFF_dart2tinygo.md` §4.2 ("生成コードは
/// gofmt 済みにする"). Falls back to the unformatted source if `gofmt` isn't
/// on PATH, since board CI environments may only have `tinygo`.
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
