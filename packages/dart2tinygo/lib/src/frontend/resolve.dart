import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as p;

/// Parses and type-resolves the Dart entry point at [entryPath] using
/// `package:analyzer`'s [AnalysisContextCollection], as decided in
/// `HANDOFF_dart2tinygo.md` §4.2 (resolved AST, not bare `parseString`).
Future<ResolvedUnitResult> resolveEntryPoint(String entryPath) async {
  final absolutePath = p.normalize(p.absolute(entryPath));
  if (!File(absolutePath).existsSync()) {
    throw FrontendException('Entry file not found: $absolutePath');
  }

  final collection = AnalysisContextCollection(
    includedPaths: [absolutePath],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );
  try {
    final context = collection.contextFor(absolutePath);
    final result = await context.currentSession.getResolvedUnit(
      absolutePath,
    );
    if (result is! ResolvedUnitResult) {
      throw FrontendException(
        'Failed to resolve $absolutePath: ${result.runtimeType}',
      );
    }
    return result;
  } finally {
    await collection.dispose();
  }
}

/// Thrown when the entry point cannot be parsed/resolved at all (as opposed
/// to containing unsupported-but-parseable syntax, which is the checker's
/// job to report).
class FrontendException implements Exception {
  FrontendException(this.message);

  final String message;

  @override
  String toString() => 'FrontendException: $message';
}
