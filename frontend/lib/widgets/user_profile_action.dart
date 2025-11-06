import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileAction extends StatelessWidget {
  const UserProfileAction({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        final prefs = snap.data;
        if (prefs == null) return const SizedBox.shrink();
        final raw = prefs.getString('user');
        String name = '';
        String role = '';
        if (raw != null) {
          try {
            final Map<String, dynamic> j = Map<String, dynamic>.from(
              jsonDecode(raw) as Map,
            );
            name =
                (j['fullName'] ??
                        j['full_name'] ??
                        j['fullName'] ??
                        j['fullName'])
                    ?.toString() ??
                '';
            role = (j['role'] ?? j['Role'])?.toString() ?? '';
          } catch (_) {}
        }

        return PopupMenuButton<int>(
          tooltip: 'Профиль',
          icon: CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0D47A1),
            child: Text(name.isNotEmpty ? name[0] : '?'),
          ),
          onSelected: (v) async {
            if (v == 1) {
              // logout
              await prefs.remove('user');
              if (context.mounted) context.go('/');
            } else if (v == 2) {
              if (context.mounted) context.go('/profile');
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem<int>(
              value: 0,
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isNotEmpty ? name : 'Гость'),
                  if (role.isNotEmpty)
                    Text(
                      role,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<int>(value: 2, child: Text('Профиль')),
            const PopupMenuItem<int>(value: 1, child: Text('Выйти')),
          ],
        );
      },
    );
  }
}

// end of file
