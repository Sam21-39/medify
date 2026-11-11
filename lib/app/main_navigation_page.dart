import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:medify/app/add_medicine_fab.dart';
import 'package:medify/core/design/adaptive.dart';
import 'package:medify/core/design/medify_theme_extension.dart';
import 'package:medify/gen/assets.gen.dart';
import 'package:medify/l10n/app_localizations.dart';

class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = MedifyTokens.of(context);

    return AdaptiveScaffold(
      enableBlur: true,
      // FAB overlays the shell, above the native tab bar (R2: overlay, not a Scaffold FAB).
      body: Stack(
        fit: StackFit.expand,
        children: [
          shell,
          AddMedicineFab(tabIndex: shell.currentIndex),
        ],
      ),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        useNativeBottomBar: true,
        selectedIndex: shell.currentIndex,
        selectedItemColor: tokens.brand,
        unselectedItemColor: tokens.labelSecondary,
        onTap: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        items: [
          MedifyAdaptive.destination(
            sf: 'calendar',
            sfSelected: 'calendar',
            cupertino: CupertinoIcons.calendar,
            material: Icons.calendar_today_outlined,
            materialSelected: Icons.calendar_today,
            label: l10n.today,
            svg: Assets.icons.home,
          ),
          MedifyAdaptive.destination(
            sf: 'pills',
            sfSelected: 'pills.fill',
            cupertino: CupertinoIcons.cube_box,
            material: Icons.medication_outlined,
            materialSelected: Icons.medication,
            label: l10n.medicines,
            svg: Assets.icons.medicine,
          ),
          MedifyAdaptive.destination(
            sf: 'clock.arrow.circlepath',
            sfSelected: 'clock.arrow.circlepath',
            cupertino: CupertinoIcons.clock,
            material: Icons.history_outlined,
            materialSelected: Icons.history,
            label: l10n.historyTitle,
            svg: Assets.icons.history,
          ),
          MedifyAdaptive.destination(
            sf: 'chart.bar',
            sfSelected: 'chart.bar.fill',
            cupertino: CupertinoIcons.chart_bar,
            material: Icons.bar_chart_outlined,
            materialSelected: Icons.bar_chart,
            label: l10n.statistics,
            svg: Assets.icons.statistics,
          ),
        ],
      ),
    );
  }
}
