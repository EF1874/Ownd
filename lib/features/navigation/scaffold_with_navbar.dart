import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation_provider.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(bottomNavBarVisibleProvider);

    final index = _calculateSelectedIndex(context);
    return PopScope(
      canPop: index == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onItemTapped(0, context);
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isVisible ? 80 : 0,
          child: Wrap(
            children: [
              NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (int idx) => _onItemTapped(idx, context),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.devices), label: '资产'),
                  NavigationDestination(
                    icon: Icon(Icons.add_circle_outline),
                    selectedIcon: Icon(Icons.add_circle),
                    label: '添加',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: '我的',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/')) {
      if (location == '/') return 0;
      if (location.startsWith('/add')) return 1;
      if (location.startsWith('/profile')) return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/add');
        break;
      case 2:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}
