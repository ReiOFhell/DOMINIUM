import 'package:dominium/app.dart';
import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBootstrap.initialize();
  runApp(const ProviderScope(child: DominiumApp()));
}
