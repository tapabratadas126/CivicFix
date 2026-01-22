import 'package:flutter/material.dart';
import 'package:civicfix/models/complaint_model.dart';
import 'package:civicfix/theme.dart';

class StatusBadge extends StatelessWidget {
  final ComplaintStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status, context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  ({Color color, IconData icon, String label}) _getStatusConfig(
    ComplaintStatus status,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (status) {
      case ComplaintStatus.submitted:
        return (
          color: isDark ? DarkModeColors.statusNew : LightModeColors.statusNew,
          icon: Icons.info_outline,
          label: 'Submitted',
        );
      case ComplaintStatus.verified:
        return (
          color: isDark ? DarkModeColors.statusVerified : LightModeColors.statusVerified,
          icon: Icons.verified_outlined,
          label: 'Verified',
        );
      case ComplaintStatus.assigned:
        return (
          color: isDark ? DarkModeColors.statusInProgress : LightModeColors.statusInProgress,
          icon: Icons.assignment_outlined,
          label: 'Assigned',
        );
      case ComplaintStatus.inProgress:
        return (
          color: isDark ? DarkModeColors.statusInProgress : LightModeColors.statusInProgress,
          icon: Icons.construction_outlined,
          label: 'In Progress',
        );
      case ComplaintStatus.resolved:
        return (
          color: isDark ? DarkModeColors.statusResolved : LightModeColors.statusResolved,
          icon: Icons.check_circle_outline,
          label: 'Resolved',
        );
      case ComplaintStatus.rejected:
        return (
          color: Theme.of(context).colorScheme.error,
          icon: Icons.cancel_outlined,
          label: 'Rejected',
        );
    }
  }
}
