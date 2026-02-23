import 'package:dominium/domains/auth/application/auth_controller.dart';
import 'package:dominium/domains/navigation/presentation/imperium_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authControllerProvider).authChanges;
});

final localOfflineModeProvider = StateProvider<bool>((_) => false);

final authSessionBootstrapProvider = FutureProvider<void>((ref) async {
  final controller = ref.read(authControllerProvider);
  if (controller.currentSession != null) {
    await controller.ensureProfileForCurrentUser();
  }
});

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(authSessionBootstrapProvider);
    final controller = ref.read(authControllerProvider);
    final localOfflineMode = ref.watch(localOfflineModeProvider);

    return bootstrap.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
      data: (_) {
        ref.watch(authStateChangesProvider);
        final hasSession = controller.currentSession != null;
        if (hasSession || localOfflineMode) return const ImperiumShell();
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool signUp}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authControllerProvider);
      if (signUp) {
        await auth.signUpWithEmail(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      await auth.signInWithEmail(
        email: _email.text.trim(),
        password: _password.text,
      );
      ref.invalidate(authSessionBootstrapProvider);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Falha ao autenticar. Confira email e senha.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar no Dominium')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : () => _submit(signUp: false),
                    child: Text(_loading ? 'Entrando...' : 'Entrar'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => _submit(signUp: true),
                    child: const Text('Criar conta e entrar'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => ref.read(localOfflineModeProvider.notifier).state = true,
                    child: const Text('Continuar em modo offline'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
