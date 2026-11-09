import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'medicine_list_page.dart';
import 'schedule_page.dart';
import 'statistics_page.dart';
import 'history_page.dart';

/// Main navigation page with bottom navigation bar
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

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon: const Icon(Icons.medication),
            label: l10n.medicines,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.statistics,
          ),
        ],
      ),
    );
  }
}
