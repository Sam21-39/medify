import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/no_set_state_in_business_logic.dart';
import 'src/no_cross_module_internal_import.dart';

PluginBase createPlugin() => _MedifyLintsPlugin();

class _MedifyLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const NoSetStateInBusinessLogic(),
    const NoCrossModuleInternalImport(),
  ];
}
