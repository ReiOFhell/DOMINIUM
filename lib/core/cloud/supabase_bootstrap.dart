import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static const _defaultUrl = 'https://ymgtbhisvxphenatvryf.supabase.co';
  static const _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InltZ3RiaGlzdnhwaGVuYXR2cnlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2NzYxMDYsImV4cCI6MjA4NzI1MjEwNn0.Lc-uWnip6lKHKzLem4CGGELumClu-ci6ymPy_NEeVVQ';

  static const _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const _defineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get _url => _defineUrl.isNotEmpty ? _defineUrl : _defaultUrl;
  static String get _anonKey =>
      _defineAnonKey.isNotEmpty ? _defineAnonKey : _defaultAnonKey;

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) return;

    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }
}
