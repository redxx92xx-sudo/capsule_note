import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/top_banner_scaffold.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';
import 'todos_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  /// Hide top banner on Settings (index 3).
  bool get _showBanner => _currentIndex != 3;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final screens = <Widget>[
      TodayScreen(
        onOpenVoiceNotes: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      ),
      const CalendarScreen(),
      const TodosScreen(),
      const SettingsScreen(),
    ];

    return TopBannerScaffold(
      showBanner: _showBanner,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny_outlined),
            label: s.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today_outlined),
            label: s.calendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.check_box_outlined),
            selectedIcon: const Icon(Icons.check_box_outlined),
            label: s.todos,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_outlined),
            label: s.settings,
          ),
        ],
      ),
    );
  }
}
