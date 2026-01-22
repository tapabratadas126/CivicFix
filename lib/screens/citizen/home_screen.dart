import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:civicfix/services/auth_service.dart';
import 'package:civicfix/services/complaint_service.dart';
import 'package:civicfix/models/complaint_model.dart';
import 'package:civicfix/widgets/complaint_card.dart';
import 'package:civicfix/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _complaintService = ComplaintService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _complaintService.loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isAdmin = authService.isAdmin;

    return Scaffold(
      body: [
        _DashboardView(complaintService: _complaintService),
        _MapView(complaintService: _complaintService),
        _MyComplaintsView(complaintService: _complaintService),
        _ProfileView(),
      ][_selectedIndex],
      floatingActionButton: !isAdmin && _selectedIndex < 2
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/report-issue'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Report Issue'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: isAdmin
            ? const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Manage',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  selectedIcon: Icon(Icons.history),
                  label: 'My Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final ComplaintService complaintService;

  const _DashboardView({required this.complaintService});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isAdmin = authService.isAdmin;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(isAdmin ? 'Admin Dashboard' : 'CivicFix'),
          actions: [
            if (!isAdmin)
              IconButton(
                icon: const Icon(Icons.emoji_events_outlined),
                onPressed: () => context.push('/gamification'),
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsCards(complaintService: complaintService, isAdmin: isAdmin),
                const SizedBox(height: 24),
                Text(
                  'Recent Complaints',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: AppSpacing.horizontalLg,
          sliver: ListenableBuilder(
            listenable: complaintService,
            builder: (context, _) {
              final complaints = complaintService.complaints.take(10).toList();
              
              if (complaintService.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (complaints.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No complaints yet',
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
                  onTap: () => context.push('/complaint-detail', extra: complaints[index]),
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _StatsCards extends StatelessWidget {
  final ComplaintService complaintService;
  final bool isAdmin;

  const _StatsCards({required this.complaintService, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: complaintService,
      builder: (context, _) {
        final statusCounts = complaintService.getStatusCounts();
        final total = complaintService.complaints.length;
        final resolved = statusCounts['resolved'] ?? 0;
        final inProgress = statusCounts['inProgress'] ?? 0;
        final submitted = statusCounts['submitted'] ?? 0;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total',
                    value: total.toString(),
                    icon: Icons.assignment_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Resolved',
                    value: resolved.toString(),
                    icon: Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'In Progress',
                    value: inProgress.toString(),
                    icon: Icons.construction_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'New',
                    value: submitted.toString(),
                    icon: Icons.info_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  final ComplaintService complaintService;

  const _MapView({required this.complaintService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue Map')),
      body: const Center(
        child: Text('Interactive map view would be integrated here\nusing flutter_map with complaint markers'),
      ),
    );
  }
}

class _MyComplaintsView extends StatelessWidget {
  final ComplaintService complaintService;

  const _MyComplaintsView({required this.complaintService});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userId = authService.currentUser?.id;

    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('My Reports')),
        SliverPadding(
          padding: AppSpacing.paddingLg,
          sliver: ListenableBuilder(
            listenable: complaintService,
            builder: (context, _) {
              final myComplaints = userId != null
                  ? complaintService.getComplaintsByUserId(userId)
                  : <ComplaintModel>[];

              if (myComplaints.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reports yet',
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
                itemCount: myComplaints.length,
                itemBuilder: (context, index) => ComplaintCard(
                  complaint: myComplaints[index],
                  onTap: () => context.push('/complaint-detail', extra: myComplaints[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Profile')),
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (user?.role.name != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user!.role.name.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
