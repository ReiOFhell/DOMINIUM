import 'package:dominium/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class DomainHubAction {
  const DomainHubAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
    this.mood = ImperialMood.calmo,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final ImperialMood mood;
}

class DomainHubScreen extends StatelessWidget {
  const DomainHubScreen({
    super.key,
    required this.title,
    required this.description,
    required this.actions,
  });

  final String title;
  final String description;
  final List<DomainHubAction> actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...actions.map(
          (action) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              mood: action.mood,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: action.onTap,
                leading: Icon(action.icon),
                title: Text(action.title),
                subtitle: Text(action.subtitle),
                trailing: action.badge == null
                    ? const Icon(Icons.chevron_right)
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(action.badge!, style: const TextStyle(fontSize: 11)),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
