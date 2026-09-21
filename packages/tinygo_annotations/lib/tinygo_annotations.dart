/// Annotations that let a binding package declare, from the Dart side, which
/// Go identifiers its `external` declarations map to.
///
/// The transpiler core never contains board-specific knowledge; everything
/// board- or runtime-specific is expressed through these annotations in a
/// separate binding package. See `docs/writing_bindings.md`.
library;

/// Declares a Go import for the annotated library.
///
/// Apply to the `library;` directive of a binding library. Every `@GoName`
/// in that library may then refer to identifiers under [alias] (or the last
/// path segment of [path] when no alias is given), and the transpiler emits
/// `import alias "path"` whenever one of them is used.
///
/// ```dart
/// @GoImport('github.com/you/wio-runtime', alias: 'wio')
/// library;
/// ```
class GoImport {
  const GoImport(this.path, {this.alias});

  /// The Go import path, e.g. `github.com/you/wio-runtime`.
  final String path;

  /// Optional Go import alias. When omitted, the last path segment is used
  /// as the package name, matching Go's default.
  final String? alias;
}

/// Names the Go-side counterpart of an `external` function or method.
///
/// - On a top-level function: the fully qualified Go call target, e.g.
///   `@GoName('wio.NewDisplay')` (the prefix must match a `@GoImport` alias
///   on the enclosing library).
/// - On an instance method of a `@GoType` class: the Go method name, e.g.
///   `@GoName('DrawText')`; it is invoked on the receiver.
class GoName {
  const GoName(this.name);

  /// The Go identifier (optionally package-qualified) to call.
  final String name;
}

/// Maps a Dart class to a Go type, e.g. `@GoType('*wio.Display')`.
///
/// Values of the class are only ever produced by `@GoName` functions and
/// consumed by `@GoName` methods; the transpiler never constructs them itself.
class GoType {
  const GoType(this.name);

  /// The Go type expression, including any pointer marker.
  final String name;
}
