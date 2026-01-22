import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:civicfix/models/complaint_model.dart';
import 'package:civicfix/widgets/status_badge.dart';
import 'package:civicfix/widgets/priority_badge.dart';
import 'package:civicfix/theme.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (complaint.imagePath != null)
              kIsWeb
                  ? Image.network(
                      complaint.imagePath!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 250,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Image.file(
                      File(complaint.imagePath!),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          complaint.issueTypeDisplay,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PriorityBadge(priority: complaint.priority),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${complaint.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatusBadge(status: complaint.status),
                  const SizedBox(height: 24),
                  _InfoSection(
                    title: 'Description',
                    child: Text(
                      complaint.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InfoSection(
                    title: 'Location',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                complaint.location.address,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        if (complaint.location.landmark != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            complaint.location.landmark!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InfoSection(
                    title: 'Reported By',
                    child: Text(
                      complaint.userName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InfoSection(
                    title: 'AI Validation',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              complaint.isAiValidated
                                  ? Icons.verified_outlined
                                  : Icons.warning_amber_outlined,
                              size: 20,
                              color: complaint.isAiValidated
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              complaint.isAiValidated ? 'Validated' : 'Pending Validation',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: complaint.isAiValidated
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${(complaint.aiConfidenceScore * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (complaint.duplicateCount > 1) ...[
                    const SizedBox(height: 24),
                    _InfoSection(
                      title: 'Community Reports',
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${complaint.duplicateCount} citizens reported this issue',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _InfoSection(
                    title: 'Timeline',
                    child: _Timeline(statusHistory: complaint.statusHistory),
                  ),
                  if (complaint.status == ComplaintStatus.resolved) ...[
                    const SizedBox(height: 24),
                    _InfoSection(
                      title: 'Resolution',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (complaint.resolutionImagePath != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(
                                      complaint.resolutionImagePath!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 150,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 48,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File(complaint.resolutionImagePath!),
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (complaint.resolutionNote != null)
                            Text(
                              complaint.resolutionNote!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          if (complaint.actualResolutionDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Resolved on: ${DateFormat('MMM dd, yyyy').format(complaint.actualResolutionDate!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<StatusUpdate> statusHistory;

  const _Timeline({required this.statusHistory});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: statusHistory.map((update) {
        final isLast = update == statusHistory.last;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getStatusColor(update.status, context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(update.status),
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusDisplay(update.status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(update.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (update.note != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          update.note!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(ComplaintStatus status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case ComplaintStatus.submitted:
        return isDark ? DarkModeColors.statusNew : LightModeColors.statusNew;
      case ComplaintStatus.verified:
        return isDark ? DarkModeColors.statusVerified : LightModeColors.statusVerified;
      case ComplaintStatus.assigned:
      case ComplaintStatus.inProgress:
        return isDark ? DarkModeColors.statusInProgress : LightModeColors.statusInProgress;
      case ComplaintStatus.resolved:
        return isDark ? DarkModeColors.statusResolved : LightModeColors.statusResolved;
      case ComplaintStatus.rejected:
        return Theme.of(context).colorScheme.error;
    }
  }

  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.submitted:
        return Icons.info;
      case ComplaintStatus.verified:
        return Icons.verified;
      case ComplaintStatus.assigned:
        return Icons.assignment;
      case ComplaintStatus.inProgress:
        return Icons.construction;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
      case ComplaintStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusDisplay(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.submitted:
        return 'Complaint Submitted';
      case ComplaintStatus.verified:
        return 'Verified by Authority';
      case ComplaintStatus.assigned:
        return 'Assigned to Team';
      case ComplaintStatus.inProgress:
        return 'Work in Progress';
      case ComplaintStatus.resolved:
        return 'Issue Resolved';
      case ComplaintStatus.rejected:
        return 'Complaint Rejected';
    }
  }
}
