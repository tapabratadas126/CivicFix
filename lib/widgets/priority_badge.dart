import 'package:flutter/material.dart';
import 'package:civicfix/models/complaint_model.dart';
import 'package:civicfix/theme.dart';

class PriorityBadge extends StatelessWidget {
  final Priority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig(priority, context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        config.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: config.color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  ({Color color, String label}) _getPriorityConfig(
    Priority priority,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (priority) {
      case Priority.critical:
        return (
          color: isDark ? DarkModeColors.statusNew : LightModeColors.statusNew,
          label: 'CRITICAL',
        );
      case Priority.medium:
        return (
          color: isDark ? DarkModeColors.statusInProgress : LightModeColors.statusInProgress,
          label: 'MEDIUM',
        );
      case Priority.low:
        return (
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          label: 'LOW',
        );
    }
  }
}
