import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scaffold_with_navbar.dart';
import '../../features/home/home_screen.dart';
import '../../features/add_device/add_device_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/dashboard/insights_screen.dart';
import '../../features/device_detail/device_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        parentNavigatorKey: _rootNavigatorKey, 
        builder: (context, state) => const AddDeviceScreen(),
      ),
      GoRoute(
        path: '/device/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final id = int.tryParse(idStr ?? '') ?? 0;
          return DeviceDetailScreen(id: id);
        },
      ),
    ],
  );
});
