import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:civicfix/services/complaint_service.dart';
import 'package:civicfix/models/complaint_model.dart';
import 'package:civicfix/widgets/complaint_card.dart';
import 'package:civicfix/theme.dart';

class AdminManageScreen extends StatefulWidget {
  const AdminManageScreen({super.key});

  @override
  State<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends State<AdminManageScreen> {
  final _complaintService = ComplaintService();
  ComplaintStatus? _filterStatus;
  Priority? _filterPriority;
  IssueType? _filterIssueType;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Manage Complaints')),
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.horizontalLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _filterStatus == null,
                        onTap: () => setState(() => _filterStatus = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Submitted',
                        isSelected: _filterStatus == ComplaintStatus.submitted,
                        onTap: () => setState(() => _filterStatus = ComplaintStatus.submitted),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Verified',
                        isSelected: _filterStatus == ComplaintStatus.verified,
                        onTap: () => setState(() => _filterStatus = ComplaintStatus.verified),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'In Progress',
                        isSelected: _filterStatus == ComplaintStatus.inProgress,
                        onTap: () => setState(() => _filterStatus = ComplaintStatus.inProgress),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Resolved',
                        isSelected: _filterStatus == ComplaintStatus.resolved,
                        onTap: () => setState(() => _filterStatus = ComplaintStatus.resolved),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All Priority',
                        isSelected: _filterPriority == null,
                        onTap: () => setState(() => _filterPriority = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '🔴 Critical',
                        isSelected: _filterPriority == Priority.critical,
                        onTap: () => setState(() => _filterPriority = Priority.critical),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '🟡 Medium',
                        isSelected: _filterPriority == Priority.medium,
                        onTap: () => setState(() => _filterPriority = Priority.medium),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '⚪ Low',
                        isSelected: _filterPriority == Priority.low,
                        onTap: () => setState(() => _filterPriority = Priority.low),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: AppSpacing.horizontalLg,
          sliver: ListenableBuilder(
            listenable: _complaintService,
            builder: (context, _) {
              var complaints = _complaintService.complaints;

              if (_filterStatus != null) {
                complaints = complaints.where((c) => c.status == _filterStatus).toList();
              }

              if (_filterPriority != null) {
                complaints = complaints.where((c) => c.priority == _filterPriority).toList();
              }

              if (_filterIssueType != null) {
                complaints = complaints.where((c) => c.issueType == _filterIssueType).toList();
              }

              if (complaints.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 80,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No complaints match filters',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList.builder(
                itemCount: complaints.length,
                itemBuilder: (context, index) => ComplaintCard(
                  complaint: complaints[index],
                  onTap: () => _showActionDialog(context, complaints[index]),
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showActionDialog(BuildContext context, ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ComplaintActionSheet(complaint: complaint),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ComplaintActionSheet extends StatefulWidget {
  final ComplaintModel complaint;

  const _ComplaintActionSheet({required this.complaint});

  @override
  State<_ComplaintActionSheet> createState() => _ComplaintActionSheetState();
}

class _ComplaintActionSheetState extends State<_ComplaintActionSheet> {
  final _noteController = TextEditingController();
  ComplaintStatus? _selectedStatus;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    await ComplaintService().updateComplaintStatus(
      complaintId: widget.complaint.id,
      newStatus: _selectedStatus!,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      updatedBy: 'Admin',
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Update Complaint',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Current Status: ${widget.complaint.statusDisplay}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ComplaintStatus>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'New Status',
              prefixIcon: Icon(Icons.update),
            ),
            items: ComplaintStatus.values
                .where((status) => status != widget.complaint.status)
                .map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(_getStatusDisplay(status)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedStatus = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (Optional)',
              hintText: 'Add a note about this update...',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedStatus == null ? null : _updateStatus,
            child: const Text('Update Status'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/complaint-detail', extra: widget.complaint),
            child: const Text('View Full Details'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getStatusDisplay(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.verified:
        return 'Verified';
      case ComplaintStatus.assigned:
        return 'Assigned to Team';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }
}
