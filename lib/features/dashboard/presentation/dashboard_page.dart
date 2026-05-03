import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/page_header.dart';
import '../data/dashboard_repository.dart';

class DashboardPage extends StatefulWidget {
  final void Function(String route)? onNavigate;

  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final repo = DashboardRepository(ApiClient(authStorage: AuthStorage()));
      final result = await repo.fetchDashboard();

      if (!mounted) return;

      setState(() {
        data = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        error = 'Failed to load dashboard';
        loading = false;
      });
    }
  }

  void _go(String route) {
    widget.onNavigate?.call(route);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingState();

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 42),
            const SizedBox(height: 12),
            Text(error!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final summary = Map<String, dynamic>.from(data?['summary'] ?? {});
    final scope = Map<String, dynamic>.from(data?['scope'] ?? {});

    final cards = [
      _DashboardMetric(
        title: 'Total Users',
        value: '${summary['totalUsers'] ?? 0}',
        subtitle: 'Manage members',
        icon: Icons.people_alt_rounded,
        color: AppColors.primary,
        route: '/users',
      ),
      _DashboardMetric(
        title: 'Active Users',
        value: '${summary['activeUsers'] ?? 0}',
        subtitle: 'Currently enabled',
        icon: Icons.verified_user_rounded,
        color: AppColors.success,
        route: '/users',
      ),
      _DashboardMetric(
        title: 'Inactive Users',
        value: '${summary['inactiveUsers'] ?? 0}',
        subtitle: 'Needs review',
        icon: Icons.person_off_rounded,
        color: AppColors.danger,
        route: '/users',
      ),
      _DashboardMetric(
        title: 'Groups',
        value: '${summary['totalGroups'] ?? 0}',
        subtitle: 'Hierarchy groups',
        icon: Icons.account_tree_rounded,
        color: const Color(0xFF7C3AED),
        route: '/groups',
      ),
      _DashboardMetric(
        title: 'Total Events',
        value: '${summary['totalEvents'] ?? 0}',
        subtitle: 'All programs',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF2563EB),
        route: '/events',
      ),
      _DashboardMetric(
        title: 'Upcoming Events',
        value: '${summary['upcomingEvents'] ?? 0}',
        subtitle: 'Programs ahead',
        icon: Icons.event_available_rounded,
        color: const Color(0xFFF59E0B),
        route: '/events',
      ),
      _DashboardMetric(
        title: 'Attendance Records',
        value: '${summary['totalAttendanceRecords'] ?? 0}',
        subtitle: 'All records',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF0F766E),
        route: '/attendance',
      ),
      _DashboardMetric(
        title: 'Recent Attendance',
        value: '${summary['recentAttendanceRecords'] ?? 0}',
        subtitle: 'Last 7 days',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFFDB2777),
        route: '/attendance',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dashboard',
            subtitle: 'Overview of your current scoped admin data.',
            action: OutlinedButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1180
                  ? 3
                  : width >= 760
                  ? 2
                  : 1;

              return GridView.builder(
                itemCount: cards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 3.1,
                ),
                itemBuilder: (context, index) {
                  final metric = cards[index];

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 250 + (index * 40)),
                    tween: Tween(begin: 0, end: 1),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: _ClickableMetricCard(
                      metric: metric,
                      onTap: () => _go(metric.route),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Scope',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your dashboard only shows data available within your assigned hierarchy.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Role: ${scope['role'] ?? '-'}',
                      color: AppColors.primary,
                    ),
                    _InfoPill(
                      icon: Icons.account_tree_rounded,
                      label: 'Tree: ${scope['treeId'] ?? '-'}',
                      color: const Color(0xFF2563EB),
                    ),
                    _InfoPill(
                      icon: Icons.verified_rounded,
                      label:
                          'Super Admin: ${(scope['isSuperAdmin'] ?? false) ? 'Yes' : 'No'}',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetric {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _ClickableMetricCard extends StatefulWidget {
  final _DashboardMetric metric;
  final VoidCallback onTap;

  const _ClickableMetricCard({required this.metric, required this.onTap});

  @override
  State<_ClickableMetricCard> createState() => _ClickableMetricCardState();
}

class _ClickableMetricCardState extends State<_ClickableMetricCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: hovering ? 1.015 : 1,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  metric.color.withValues(alpha: hovering ? 0.13 : 0.07),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hovering
                    ? metric.color.withValues(alpha: 0.34)
                    : metric.color.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: hovering
                      ? metric.color.withValues(alpha: 0.17)
                      : Colors.black.withValues(alpha: 0.045),
                  blurRadius: hovering ? 24 : 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: metric.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(metric.icon, color: metric.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            metric.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            metric.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: hovering
                        ? metric.color.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: hovering ? metric.color : const Color(0xFF94A3B8),
                    size: 21,
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

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
