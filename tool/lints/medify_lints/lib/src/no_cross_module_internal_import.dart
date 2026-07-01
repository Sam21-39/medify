import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

/// Enforces the Modular Monolith boundary: a feature under
/// `lib/features/<x>/**` may only import another feature's public domain
/// contracts (`lib/features/<y>/domain/*.dart`), never its `data/` or
/// `presentation/` layers, nor non-contract files inside `domain/` such as
/// `domain/**/*_impl.dart`.
class NoCrossModuleInternalImport extends DartLintRule {
  const NoCrossModuleInternalImport() : super(code: _code);

  static const _code = LintCode(
    name: 'medify_no_cross_module_internal_import',
    problemMessage:
        'Illegal cross-module import: only lib/features/<module>/domain/*.dart '
        'public contracts may be imported from outside that module.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  static final _featureImport = RegExp(r'features/([^/]+)/');

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.source.fullName.replaceAll('\\', '/');
    final currentModuleMatch = _featureImport.firstMatch(path);
    if (currentModuleMatch == null) return; // not inside lib/features/**
    final currentModule = currentModuleMatch.group(1);

    context.registry.addImportDirective((node) {
      final uriContent = node.uri.stringValue;
      if (uriContent == null) return;

      // Resolve the import target to an absolute-style path so relative
      // imports (../../other_feature/data/x.dart) are caught the same as
      // package: imports.
      final resolvedPath = uriContent.startsWith('package:')
          ? uriContent
          : p
                .normalize(p.join(p.dirname(path), uriContent))
                .replaceAll('\\', '/');

      final importMatch = _featureImport.firstMatch(resolvedPath);
      if (importMatch == null) return; // not importing another feature
      final importedModule = importMatch.group(1);
      if (importedModule == currentModule) return; // same module, fine

      final isDataOrPresentation =
          resolvedPath.contains('/data/') ||
          resolvedPath.contains('/presentation/');
      final isNonContractDomainFile =
          resolvedPath.contains('/domain/') &&
          (resolvedPath.contains('_impl.dart') ||
              resolvedPath.contains('/services/'));

      if (isDataOrPresentation || isNonContractDomainFile) {
        reporter.atNode(node, _code);
      }
    });
  }
}
