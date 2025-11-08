import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/request_list_screen.dart';
import 'screens/request_detail_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/operator_create_request_screen.dart';
import 'screens/manage_employees_screen.dart';
import 'models/user_session.dart';

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
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardScreen(),
        ),
        // Маршрут для оператора - создание обращения
        GoRoute(
          path: '/operator/create-request',
          builder: (context, state) => const _OperatorCreateRequestWrapper(),
        ),
        // Маршрут для админа - управление сотрудниками
        GoRoute(
          path: '/admin/employees',
          builder: (context, state) => const ManageEmployeesScreen(),
        ),
      ],
    );
  }

  // Получение текущей сессии пользователя
  static Future<UserSession?> _getUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson == null) return null;
      
      final json = jsonDecode(userJson) as Map<String, dynamic>;
      return UserSession.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}

// Обёртка для загрузки сессии пользователя
class _OperatorCreateRequestWrapper extends StatefulWidget {
  const _OperatorCreateRequestWrapper();

  @override
  State<_OperatorCreateRequestWrapper> createState() => _OperatorCreateRequestWrapperState();
}

class _OperatorCreateRequestWrapperState extends State<_OperatorCreateRequestWrapper> {
  UserSession? _userSession;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final json = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() {
          _userSession = UserSession.fromJson(json);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userSession == null) {
      return const Scaffold(
        body: Center(child: Text('Ошибка загрузки сессии')),
      );
    }

    return OperatorCreateRequestScreen(currentUser: _userSession!);
  }
}

