import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:medify/core/design/adaptive.dart';
import 'package:medify/core/design/medify_theme_extension.dart';
import 'package:medify/features/history/presentation/pages/history_page.dart';
import 'package:medify/features/medicines/presentation/pages/medicine_list_page.dart';
import 'package:medify/features/schedule/presentation/pages/schedule_page.dart';
import 'package:medify/features/statistics/presentation/pages/statistics_page.dart';
import 'package:medify/l10n/app_localizations.dart';

/// Shell with adaptive tab bar — iOS 26 Liquid Glass, Material tint elsewhere.
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SchedulePage(),
    MedicineListPage(),
    HistoryPage(),
    StatisticsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = MedifyTokens.of(context);

    return AdaptiveScaffold(
      enableBlur: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        useNativeBottomBar: true,
        selectedIndex: _currentIndex,
        selectedItemColor: tokens.brand,
        unselectedItemColor: tokens.labelSecondary,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          MedifyAdaptive.destination(
            sf: 'calendar',
            sfSelected: 'calendar',
            cupertino: CupertinoIcons.calendar,
            material: Icons.calendar_today_outlined,
            materialSelected: Icons.calendar_today,
            label: l10n.today,
          ),
          MedifyAdaptive.destination(
            sf: 'pills',
            sfSelected: 'pills.fill',
            cupertino: CupertinoIcons.cube_box,
            material: Icons.medication_outlined,
            materialSelected: Icons.medication,
            label: l10n.medicines,
          ),
          MedifyAdaptive.destination(
            sf: 'clock.arrow.circlepath',
            sfSelected: 'clock.arrow.circlepath',
            cupertino: CupertinoIcons.clock,
            material: Icons.history_outlined,
            materialSelected: Icons.history,
            label: 'History',
          ),
          MedifyAdaptive.destination(
            sf: 'chart.bar',
            sfSelected: 'chart.bar.fill',
            cupertino: CupertinoIcons.chart_bar,
            material: Icons.bar_chart_outlined,
            materialSelected: Icons.bar_chart,
            label: l10n.statistics,
          ),
        ],
      ),
    );
  }
}
