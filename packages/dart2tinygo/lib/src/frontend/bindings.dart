import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;

/// Reads the `@GoImport` / `@GoName` / `@GoType` annotations that binding
/// packages declare with `package:tinygo_annotations`.
///
/// This is the only place the core knows about bindings, and it is
/// board-agnostic by construction: it never looks at *which* Go package is
/// bound, only at how the annotations describe it.
const _annotationsLibraryUri =
    'package:tinygo_annotations/tinygo_annotations.dart';

/// A Go import declared by `@GoImport(path, alias: ...)` on a binding library.
class GoImportSpec {
  GoImportSpec({required this.path, this.alias, this.localModule});

  /// The Go import path.
  final String path;

  /// The import alias, or `null` to let Go use the package name.
  final String? alias;

  /// When the binding's Dart package ships its Go runtime in a `go/`
  /// directory next to `pubspec.yaml`, the module it declares, so the
  /// generated `go.mod` can `replace` it with the local checkout.
  final GoLocalModule? localModule;

  /// The identifier the generated Go code uses to refer to this package.
  String get packageName => alias ?? p.url.basename(path);
}

/// A Go module found at [directory] (declaring [modulePath]).
class GoLocalModule {
  GoLocalModule({required this.modulePath, required this.directory});

  final String modulePath;
  final String directory;
}

/// The Go-side counterpart of an `external` Dart declaration.
class GoBinding {
  GoBinding({required this.goName, required this.import});

  /// The Go call target: package-qualified (`wio.NewDisplay`) for top-level
  /// functions, bare (`DrawText`) for methods.
  final String goName;

  /// The `@GoImport` of the library that declares the binding.
  final GoImportSpec import;
}

/// Returns the `@GoImport` on [library], or `null` if it has none.
GoImportSpec? goImportOf(LibraryElement library) {
  final value = _annotationValue(library.metadata, 'GoImport');
  if (value == null) return null;
  final path = value.getField('path')?.toStringValue();
  if (path == null) return null;
  final alias = value.getField('alias')?.toStringValue();
  return GoImportSpec(
    path: path,
    alias: alias,
    localModule: _findLocalModule(library),
  );
}

/// Returns the `@GoName` on [element], or `null` if it has none.
String? goNameOf(Element element) =>
    _annotationValue(element.metadata, 'GoName')
        ?.getField('name')
        ?.toStringValue();

/// Returns the `@GoType` on [element], or `null` if it has none.
String? goTypeOf(Element element) =>
    _annotationValue(element.metadata, 'GoType')
        ?.getField('name')
        ?.toStringValue();

/// Whether [type] is a Dart class annotated with `@GoType`.
bool isGoType(DartType? type) {
  if (type is! InterfaceType) return false;
  return goTypeOf(type.element) != null;
}

/// Resolves [element] (an `external` top-level function or method) to its
/// Go binding, or `null` when it isn't a complete binding: it must be
/// `external`, carry `@GoName`, and live in a library with `@GoImport`.
GoBinding? goBindingOf(ExecutableElement element) {
  if (!element.isExternal) return null;
  final goName = goNameOf(element);
  if (goName == null) return null;
  final library = element.library;
  final import = goImportOf(library);
  if (import == null) return null;
  return GoBinding(goName: goName, import: import);
}

DartObject? _annotationValue(Metadata metadata, String className) {
  for (final annotation in metadata.annotations) {
    final value = annotation.computeConstantValue();
    final type = value?.type;
    if (type is! InterfaceType) continue;
    final element = type.element;
    if (element.name == className &&
        element.library.uri.toString() == _annotationsLibraryUri) {
      return value;
    }
  }
  return null;
}

/// Looks for `<package root>/go/go.mod` next to the `pubspec.yaml` of the
/// package that declares [library]. This is a convention, not configuration:
/// a binding that ships its Go runtime in-tree gets a `replace` directive so
/// examples build straight from a checkout, and one that doesn't is left to
/// `go mod tidy` to fetch normally.
GoLocalModule? _findLocalModule(LibraryElement library) =>
    findLocalModuleNear(library.firstFragment.source.fullName);

/// Walks up from [sourcePath] to the nearest `pubspec.yaml`, and returns the
/// `go/go.mod` module declared next to it, if any. Shared by [_findLocalModule]
/// (a binding library) and the core's own `dartrt` runtime
/// (`packages/dart2tinygo/go/`, see `docs/mapping.md` "Common Go runtime"),
/// which is looked up the same way even though it isn't a binding.
GoLocalModule? findLocalModuleNear(String sourcePath) {
  var dir = p.dirname(sourcePath);
  while (true) {
    if (File(p.join(dir, 'pubspec.yaml')).existsSync()) {
      final goDir = p.join(dir, 'go');
      final goMod = File(p.join(goDir, 'go.mod'));
      if (!goMod.existsSync()) return null;
      final modulePath = _moduleLine(goMod.readAsStringSync());
      if (modulePath == null) return null;
      return GoLocalModule(modulePath: modulePath, directory: goDir);
    }
    final parent = p.dirname(dir);
    if (parent == dir) return null;
    dir = parent;
  }
}

/// Reads [module]'s own `go.mod` for `replace <path> => <dir>` directives
/// pointing at another local checkout (a path that itself has a `go.mod`),
/// and returns each as a further [GoLocalModule].
///
/// A binding's Go module can itself depend on another binding's local Go
/// module (e.g. `wio_terminal`'s pin constants returning `tinygo_machine`'s
/// `Pin` type, #22) — but Go's own `replace` directive only ever applies
/// within the module actually being built, never transitively through a
/// dependency's own `go.mod` (https://go.dev/ref/mod#go-mod-file-replace,
/// confirmed against `go` 1.27: a downstream build fails with "missing
/// go.sum entry" until its *own* go.mod repeats the replace). The caller
/// (`bin/dart2tinygo.dart`) closes that gap by copying these into the
/// generated go.mod too, alongside the directly-`@GoImport`ed modules.
///
/// One hop only; call again on the results to walk a longer chain.
List<GoLocalModule> localModuleReplacesOf(GoLocalModule module) {
  final goModFile = File(p.join(module.directory, 'go.mod'));
  if (!goModFile.existsSync()) return const [];
  final found = <GoLocalModule>[];
  for (final line in goModFile.readAsStringSync().split('\n')) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('replace ')) continue;
    final arrow = trimmed.indexOf('=>');
    if (arrow < 0) continue;
    final target = trimmed.substring(arrow + 2).trim();
    if (target.isEmpty) continue;
    final targetDir = p.isAbsolute(target)
        ? target
        : p.normalize(p.join(module.directory, target));
    final targetGoMod = File(p.join(targetDir, 'go.mod'));
    if (!targetGoMod.existsSync()) continue;
    final modulePath = _moduleLine(targetGoMod.readAsStringSync());
    if (modulePath == null) continue;
    found.add(GoLocalModule(modulePath: modulePath, directory: targetDir));
  }
  return found;
}

String? _moduleLine(String goModSource) {
  for (final line in goModSource.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('module ')) {
      return trimmed.substring('module '.length).trim();
    }
  }
  return null;
}
