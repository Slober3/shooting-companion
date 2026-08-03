import 'package:flutter/material.dart';

import '../history/history_screen.dart';
import '../more/more_screen.dart';
import '../progress/progress_screen.dart';
import '../today/today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  static const _destinations = <_ShellDestination>[
    _ShellDestination(
      label: 'Start',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _ShellDestination(
      label: 'Logboek',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    _ShellDestination(
      label: 'Analyse',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
    ),
    _ShellDestination(
      label: 'Meer',
      icon: Icons.more_horiz,
      selectedIcon: Icons.more,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          HistoryScreen(),
          ProgressScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: HomeNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
      ),
    );
  }
}

class HomeNavigationBar extends StatelessWidget {
  const HomeNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final hideLabels = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          labelBehavior: hideLabels
              ? NavigationDestinationLabelBehavior.alwaysHide
              : NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (
              var index = 0;
              index < _HomeShellState._destinations.length;
              index++
            )
              NavigationDestination(
                icon: _DestinationIcon(
                  label: _HomeShellState._destinations[index].label,
                  icon: _HomeShellState._destinations[index].icon,
                  selected: false,
                ),
                selectedIcon: _DestinationIcon(
                  label: _HomeShellState._destinations[index].label,
                  icon: _HomeShellState._destinations[index].selectedIcon,
                  selected: true,
                ),
                label: _HomeShellState._destinations[index].label,
              ),
          ],
        ),
      ),
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({
    required this.label,
    required this.icon,
    required this.selected,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    selected: selected,
    excludeSemantics: true,
    child: Icon(icon),
  );
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
