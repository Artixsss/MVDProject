import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Small reusable Home action button that navigates to the dashboard
class HomeAction extends StatelessWidget {
  const HomeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Главное меню',
      onPressed: () => context.go('/dashboard'),
      icon: const Icon(Icons.home, color: Colors.white),
    );
  }
}
