import 'dart:math' as math;

import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:dominium/domains/campaigns/presentation/campaigns_screen.dart';
import 'package:dominium/domains/orders/presentation/orders_screen.dart';
import 'package:dominium/domains/throne/presentation/throne_screen.dart';
import 'package:dominium/domains/treasury/presentation/treasury_screen.dart';
import 'package:flutter/material.dart';

class DominiumApp extends StatelessWidget {
  const DominiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOMINIUM',
      debugShowCheckedModeBanner: false,
      theme: DominiumTheme.theme,
      home: const SplashGate(),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const EmpireShell()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final v = Curves.easeOutCubic.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(color: DominiumTheme.black),
              CustomPaint(
                size: Size.infinite,
                painter: RadialPulsePainter(progress: v),
              ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('DOMINIUM', style: TextStyle(fontSize: 38, letterSpacing: 5)),
                  SizedBox(height: 12),
                  Text('O Império observa', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class RadialPulsePainter extends CustomPainter {
  const RadialPulsePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          DominiumTheme.red.withOpacity(0.25 * (1 - progress)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius * progress, paint);
  }

  @override
  bool shouldRepaint(covariant RadialPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class EmpireShell extends StatefulWidget {
  const EmpireShell({super.key});

  @override
  State<EmpireShell> createState() => _EmpireShellState();
}

class _EmpireShellState extends State<EmpireShell> {
  int index = 0;

  final pages = const [
    ThroneScreen(),
    TreasuryScreen(),
    OrdersScreen(),
    CampaignsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance), label: 'Trono'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Tesouro'),
          NavigationDestination(icon: Icon(Icons.gavel), label: 'Ordens'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Campanhas'),
        ],
      ),
    );
  }
}
