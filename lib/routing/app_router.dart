import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/auth_storage.dart';
import '../core/widgets/app_scaffold_shell.dart';
import '../features/attendance/presentation/attendance_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/events/presentation/events_page.dart';
import '../features/groups/presentation/groups_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/users/presentation/users_page.dart';
import '../features/content_pages/presentation/content_pages_page.dart';
import '../features/programs/presentation/programs_page.dart';

class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/dashboard',
      redirect: (context, state) async {
        final token = await AuthStorage().getToken();
        final loggedIn = token != null && token.isNotEmpty;
        final goingToLogin = state.matchedLocation == '/login';

        if (!loggedIn && !goingToLogin) return '/login';
        if (loggedIn && goingToLogin) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        ShellRoute(
          builder: (context, state, child) => AppScaffoldShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/users',
              builder: (context, state) => const UsersPage(),
            ),
            GoRoute(
              path: '/groups',
              builder: (context, state) => const GroupsPage(),
            ),
            GoRoute(
              path: '/programs',
              builder: (context, state) => const ProgramsPage(),
            ),
            GoRoute(
              path: '/events',
              builder: (context, state) => const EventsPage(),
            ),
            GoRoute(
              path: '/attendance',
              builder: (context, state) => const AttendancePage(),
            ),
            GoRoute(
              path: '/content-pages',
              builder: (context, state) => const ContentPagesPage(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsPage(),
            ),
          ],
        ),
      ],
    );
  }
}
