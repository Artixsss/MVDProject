import 'package:go_router/go_router.dart';
import 'screens/citizen_complaint_screen.dart';
import 'screens/check_status_screen.dart';

class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/complaint',
      routes: [
        GoRoute(
          path: '/complaint',
          builder: (context, state) => const CitizenComplaintScreen(),
        ),
        GoRoute(
          path: '/check-status',
          builder: (context, state) => const CheckStatusScreen(),
        ),
      ],
    );
  }
}

