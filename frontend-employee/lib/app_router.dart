import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/request_list_screen.dart';
import 'screens/request_detail_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/admin_screen.dart';

class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final user = prefs.getString('user');
        final isLoggedIn = user != null && user.isNotEmpty;
        final loggingIn = state.matchedLocation == '/';
        
        if (!isLoggedIn && !loggingIn) return '/';
        if (isLoggedIn && loggingIn) return '/dashboard';

        // Role-based guard for /admin
        if (isLoggedIn && state.matchedLocation.startsWith('/admin')) {
          try {
            final Map<String, dynamic> j = jsonDecode(user);
            final role = (j['role'] ?? j['Role'])?.toString() ?? '';
            if (!(role == 'Admin' || role == 'Manager')) {
              return '/dashboard';
            }
          } catch (_) {
            return '/dashboard';
          }
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const AuthScreen()),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/requests',
          builder: (context, state) => const RequestListScreen(),
        ),
        GoRoute(
          path: '/requests/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return RequestDetailScreen(id: id);
          },
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminScreen(),
        ),
      ],
    );
  }
}

