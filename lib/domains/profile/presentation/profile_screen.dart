import 'package:dominium/domains/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Identidade Imperial',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text('Email: ${user?.email ?? 'modo offline'}'),
                  const SizedBox(height: 8),
                  Text('ID do usuário: ${user?.id ?? 'não autenticado'}'),
                  const SizedBox(height: 8),
                  Text('Último login: ${user?.lastSignInAt ?? 'indisponível'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: user == null
                ? null
                : () async {
                    await ref.read(authControllerProvider).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Encerrar sessão'),
          ),
        ],
      ),
    );
  }
}
