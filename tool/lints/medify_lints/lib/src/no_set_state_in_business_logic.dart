import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags `setState(...)` calls and flags `BuildContext` parameters accepted
/// by Cubit/Bloc constructors or by anything under a `domain/` or `data/`
/// module path. Business logic must not depend on the widget tree.
class NoSetStateInBusinessLogic extends DartLintRule {
  const NoSetStateInBusinessLogic() : super(code: _code);

  static const _code = LintCode(
    name: 'medify_no_set_state_in_business_logic',
    problemMessage:
        'setState() and BuildContext are not allowed in domain/data layers '
        'or in Cubit/Bloc constructors. Use a Cubit/Bloc state instead.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  bool _isBusinessLogicPath(String path) =>
      path.contains('/domain/') || path.contains('/data/');

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.source.fullName.replaceAll('\\', '/');
    final inBusinessLogicPath = _isBusinessLogicPath(path);

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'setState' && inBusinessLogicPath) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addConstructorDeclaration((node) {
      final classDecl = node.parent;
      final className = classDecl is ClassDeclaration
          ? classDecl.name.lexeme
          : '';
      final isCubitOrBloc =
          className.endsWith('Cubit') || className.endsWith('Bloc');
      if (!isCubitOrBloc && !inBusinessLogicPath) return;

      for (final param in node.parameters.parameters) {
        final typeNode = param is SimpleFormalParameter
            ? param.type
            : param is DefaultFormalParameter &&
                  param.parameter is SimpleFormalParameter
            ? (param.parameter as SimpleFormalParameter).type
            : null;
        if (typeNode?.toSource() == 'BuildContext') {
          reporter.atNode(param, _code);
        }
      }
    });
  }
}
